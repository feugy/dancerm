import type { DatabaseSync } from 'node:sqlite'
import { getLogger, type Logger } from '$lib/utils/logger'

const migrationsTable = '_migrations'

export interface Migration {
	name: string
	up: (db: DatabaseSync) => Promise<void>
}

async function ensureTable(db: DatabaseSync) {
	db.exec(`
CREATE TABLE IF NOT EXISTS \`${migrationsTable}\` (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
  name TEXT, 
  time INTEGER
)
  `)
}

async function listCompleted(db: DatabaseSync, logger: Logger) {
	const migrations = db.prepare(`SELECT id, name, time FROM ${migrationsTable} ORDER BY id`).all()
	logger.debug({ migrations }, 'completed migrations')
	return migrations.map(({ name }) => name)
}

async function applyMigration({ name, up }: Migration, db: DatabaseSync, logger: Logger) {
	logger.debug({ name }, `applying migration ${name}`)
	try {
		await up(db)
		logger.debug({ name }, 'inserting into migration table')
		db.prepare(`INSERT INTO ${migrationsTable} (name, time) VALUES (:name, :time)`).run({
			name,
			time: Date.now()
		})
		logger.info({ name }, `migration ${name} applied`)
	} catch (error) {
		logger.error(
			{ name, error },
			`Failed to apply migration ${name}: ${Error.isError(error) ? error.message : error}`
		)
		throw error
	}
}

export async function migrateToLatest(db: DatabaseSync, migrations: Migration[]) {
	const logger = getLogger('utils/migrations')
	await ensureTable(db)
	const completed = await listCompleted(db, logger)
	const all = migrations.toSorted(
		({ name: a }, { name: b }) => Number.parseInt(a) - Number.parseInt(b)
	)
	const pending = all.filter(({ name }) => !completed.includes(name))
	for (const migration of pending) {
		await applyMigration(migration, db, logger)
	}
}

export async function getCurrentVersion(db: DatabaseSync) {
	try {
		return (
			db.prepare(`SELECT name FROM ${migrationsTable} ORDER BY id DESC LIMIT 1`).get()?.name ??
			'none'
		)
	} catch (error) {
		if (Error.isError(error) && error.message.includes('no such table')) {
			return 'none'
		}
		throw error
	}
}
