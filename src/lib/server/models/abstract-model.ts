import { DatabaseSync, type SQLOutputValue } from 'node:sqlite'
import { getCurrentVersion, type Migration, migrateToLatest } from '$lib/server/utils/migrations'
import {
	buildSelect,
	buildUpsert,
	makeDeserializer,
	makeSerializer,
	whereIn
} from '$lib/server/utils/sqlite'
import { getLogger, type Logger } from '$lib/utils/logger'
import type { Column, DBConf, Page, PartialWithReq } from '$lib/utils/types'
import * as migrations from './migrations'

let _db: DatabaseSync | null = null

/**
 * Connects to database, creating file if it does not exist, applying migrations up to latest, and
 * storing database conneciton as a global variable.
 * @param conf database configuration
 * @param logger Logger used
 * @param migrate If true, applies migrations to latest version
 */
async function connect(conf: DBConf, logger: Logger, migrate: boolean) {
	if (!_db) {
		logger.debug({ conf }, 'connecting...')
		_db = new DatabaseSync(conf.filename)
		_db.exec('PRAGMA journal_mode = WAL')
		if (migrate) {
			logger.debug({ conf }, 'migrating to latest...')
			await migrateToLatest(
				_db,
				Object.keys(migrations).map(
					(name) =>
						// biome-ignore lint/performance/noDynamicNamespaceImportAccess: we intentionally use dynamic access
						({ name, ...migrations[name as keyof typeof migrations] }) as Migration
				)
			)
		}
		const version = await getCurrentVersion(_db)
		logger.info({ conf, version }, `database connection ready on version ${version}`)
	}
	return _db
}

/**
 * Base class for all database models, provides CRUD operations on a single SQLite table.
 */
export abstract class AbstractModel<T extends { id: string | number; _v: number }> {
	/** Model name, used at table name. */
	table: string

	/** Logger specific to this model class. */
	logger: Logger

	/** Database connection. */
	db: DatabaseSync | null = null

	/** Column definition with types.  */
	columns: Column[]

	/** Release database connection (useful during tests). */
	static release() {
		if (_db) {
			_db.close()
			_db = null
		}
	}

	/** Builds a model manager, that can handle records of a given SQL table. */
	constructor({
		table,
		columns
	}: {
		table: string
		columns: Column[]
	}) {
		if (!table) {
			throw new Error('every model needs a name')
		}
		this.table = table
		this.logger = getLogger(`models/${this.table}`)
		this.columns = columns
	}

	/**
	 * Connects to SQLite database, getting a database connection and applying migrations if needed.
	 * @param configuration configuration to the database.
	 * @param migrate If true, applies migrations to latest version
	 */
	async init(configuration?: DBConf, migrate = true) {
		if (!configuration) {
			throw new Error(`${this.table} model must be initialized with a database configuration`)
		}
		this.db = await connect(configuration, this.logger, migrate)
	}

	/**
	 * Lists models within table, with pagination and sort.
	 * Also supports searches, when the searched text is provided.
	 * @param args List arguments, including:
	 * @param args.from 0-based index of the first result
	 * @param args.size Maximum number of records returned after first results
	 * @param args.sort Column used for sorting. Use + for ascending order (default) or - for descending
	 * @returns a given page of models
	 */
	async list({
		from = 0,
		size = 10,
		sort = 'id'
	}: {
		from?: number
		size?: number
		sort?: string
	} = {}) {
		if (!this.db) throw new Error('model not initialized')
		const [, rawDir, rawSort] = sort.match(/(-|\+)?(.+)/) as [unknown, string, string]
		const direction = rawDir || '+'

		const query = `${buildSelect(this.table, this.columns)} WHERE 1=1 ORDER BY ${this.table}.${rawSort} ${direction === '+' ? 'asc' : 'desc'} LIMIT :size OFFSET :from`
		const countQuery = `SELECT COUNT(*) AS count FROM ${this.table} WHERE 1=1`

		const params = { size, from }
		this.logger.debug({ query, countQuery, from, size, rawSort, direction }, 'list models')
		const deserialize = makeDeserializer<T>(this, true)
		const results = this.db
			.prepare(query)
			.all(params)
			.map((model) => deserialize(model) as T)
		const total = this.db.prepare(countQuery).get()?.count ?? 0
		this.logger.info(
			{ total, from, size, rawSort, direction, hitCount: results.length },
			'returned list page'
		)
		return {
			total,
			from,
			size,
			sort: `${direction}${rawSort}`,
			results
		} as Page<T>
	}

	/**
	 * @returns the total number of models.
	 */
	async count() {
		if (!this.db) throw new Error('model not initialized')
		return this.db.prepare(`SELECT COUNT(*) AS count FROM ${this.table}`).get()?.count ?? 0
	}

	/**
	 * Get a single model by its id.
	 * @param id Desired id
	 * @returns matching model, or null
	 */
	async getById(id: T['id']) {
		if (!this.db) throw new Error('model not initialized')
		const query = `${buildSelect(this.table, this.columns)} WHERE ${this.table}.id = :id`
		this.logger.debug({ query, id }, 'get model by id')
		const result = this.db.prepare(query).get({ id })
		this.logger.info({ id, found: Boolean(result) }, 'fetch by id')
		if (!result) {
			return null
		}
		return makeDeserializer<T>(this, true)(result)
	}

	/**
	 * Get several models by their id.
	 * Ids that do not match any model are simply ignored.
	 * _Note_: does not guarantee that result ordering will match input ordering.
	 * @param ids Desired ids
	 * @returns array of matching model (may be empty)
	 */
	async getByIds(ids: T['id'][]): Promise<T[]> {
		if (!this.db) throw new Error('model not initialized')
		const query = `${buildSelect(this.table, this.columns)} WHERE ${whereIn(`${this.table}.id`, ids)}`
		this.logger.debug({ query, ids }, 'get models by ids')
		const results =
			this.db
				?.prepare(query)
				.all(...ids)
				?.map((data) => makeDeserializer<T>(this, true)(data)) ?? []
		this.logger.info({ ids, hitCount: results.length }, 'fetch by ids')
		return results as unknown as T[]
	}

	/**
	 * Saves given model to database.
	 * It creates new record when needed, and updates existing ones (based on provided id).
	 * Partial update is supported: incoming data is merged with previous.
	 * @param data Single or array of saved (partial) models
	 */
	async save(data: PartialWithReq<T, 'id'> | PartialWithReq<T, 'id'>[]): Promise<T[]> {
		if (!this.db) throw new Error('model not initialized')
		const input = Array.isArray(data) ? data : [data]
		this.logger.info({ data: input }, 'saving')
		const query = buildUpsert(this.table, this.columns, true)
		const upsert = this.db.prepare(query)
		const results = new Array(input.length)
		const deserializer = makeDeserializer<T>(this)
		const serializer = makeSerializer<T>(this)
		for (const [i, model] of input.entries()) {
			const saved = serializer(model)
			this.logger.debug({ query, input, saved }, 'save model')
			results[i] = deserializer(upsert.get(saved) as Record<string, SQLOutputValue>, model)
		}
		return results
	}

	/**
	 * Removes models by their ids.
	 * Unmatching ids will be simply ignored
	 * @param ids Ids of removed models
	 * @returns list (may be empty) of removed models
	 */
	async removeByIds(ids: T['id'][]): Promise<T[]> {
		if (!this.db) throw new Error('model not initialized')
		const query = `DELETE FROM ${this.table} WHERE ${whereIn('id', ids)}`
		this.logger.debug({ query, ids }, 'remove models by ids')
		this.logger.info({ ids }, 'removing')
		const previous = this.getByIds(ids)
		this.db.prepare(query).run(...ids)
		return previous
	}

	/** Deletes all models in table!! */
	async reset() {
		this.db?.exec(`DELETE FROM ${this.table}`)
		this.logger.info('table truncated')
	}
}
