import type { DatabaseSync } from 'node:sqlite'
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from 'vitest'
import { faker } from '@faker-js/faker'
import { cleanTestTB, initTestDB, serializedModels } from '$lib/tests/database'
import type { DBConf } from '$lib/utils/types'
import { whereIn } from '$lib/server/utils/sqlite'
import { AbstractModel } from './abstract-model'

const modelName = 'test'

class Test extends AbstractModel<{ tags: unknown; name?: string; id: number }> {
	constructor() {
		super({ name: modelName })
	}
}

describe('Abstract model', () => {
	let db: DatabaseSync
	let conf: DBConf
	const migrationsTable = '_migrations'

	beforeAll(async () => {
		;({ conf, db } = await initTestDB())
	})

	afterAll(async () => {
		await cleanTestTB(conf)
	})

	it('can not constructor model without name', () => {
		// @ts-expect-error -- Typescript validations are not enforced at runtime.
		expect(() => new AbstractModel({})).toThrow(/every model needs a name/)
	})

	describe('init()', () => {
		it('can not create init without db file', async () => {
			await expect(new Test().init()).rejects.toThrow(
				/must be initialized with a database configuration/
			)
		})

		it('triggers migrations', async () => {
			const tested = new Test()
			await tested.init(conf)
			expect(db.prepare(`SELECT name FROM sqlite_schema where type = 'table';`).all()).toEqual(
				expect.arrayContaining([{ name: migrationsTable }])
			)
			expect(db.prepare(`SELECT id, name FROM ${migrationsTable};`).all()).toEqual([
				{ id: 1, name: '001-init' }
			])
		})
	})

	describe('given some data', () => {
		const tested = new Test()
		const name = faker.person.fullName()
		const models = [
			{ id: faker.number.int(), name },
			{ id: faker.number.int(), name: faker.person.fullName() },
			{
				id: faker.number.int(),
				name: `${name} ${faker.person.fullName()}`
			},
			{ id: faker.number.int(), name: faker.person.fullName() }
		]

		beforeEach(async () => {
			db.exec(`CREATE TABLE ${modelName} (id BIGINT PRIMARY KEY, name TEXT)`)
			const insert = db.prepare(`INSERT INTO ${modelName} VALUES (:id, :name)`)
			for (const model of models) {
				insert.run(model)
			}
			await tested.init(conf)
		})

		afterEach(() => {
			db.exec(`DROP TABLE IF EXISTS ${modelName}`)
			AbstractModel.release()
		})

		describe('reset()', () => {
			it('resets table', async () => {
				const count = db.prepare(`SELECT COUNT(*) as c FROM ${modelName}`)
				expect(count.get()).toEqual({ c: models.length })
				await tested.reset()
				expect(count.get()).toEqual({ c: 0 })
			})
		})

		describe('save()', () => {
			it('adds single model', async () => {
				const model = {
					id: faker.number.int(),
					name: faker.person.fullName()
				}

				expect(await tested.save(model)).toEqual([model])
				expect(db.prepare(`SELECT * FROM ${modelName} WHERE id=:id`).get({ id: model.id })).toEqual(
					serializedModels([model], tested)[0]
				)
			})

			it('adds multiple models', async () => {
				const models = [
					{ id: faker.number.int(), name: faker.person.fullName() },
					{ id: faker.number.int(), name: faker.person.fullName() }
				]

				expect(await tested.save(models)).toEqual(models)
				expect(
					db
						.prepare(`SELECT * FROM ${modelName} WHERE ${whereIn('id', models)}`)
						.all(...models.map(({ id }) => id))
				).toEqual(expect.arrayContaining(serializedModels(models, tested)))
			})

			it('update existing models', async () => {
				const originals = [
					{
						id: faker.number.int(),
						name: faker.person.fullName()
					},
					{
						id: faker.number.int(),
						name: faker.person.fullName()
					}
				]
				const models = [
					{
						id: originals[0].id,
						name: `${originals[0].name}-new`
					},
					{ id: originals[1].id, name: `${originals[1].name}-new` }
				]
				for (const original of originals) {
					db.prepare(`INSERT INTO ${modelName} VALUES (:id, :name)`).run(original)
				}

				expect(await tested.save(models)).toEqual(models)
				expect(
					db
						.prepare(`SELECT * FROM ${modelName} WHERE ${whereIn('id', models)}`)
						.all(...models.map(({ id }) => id))
				).toEqual(
					expect.arrayContaining(
						serializedModels(
							models.map((model, i) => ({ ...originals[i], ...model })),
							tested
						)
					)
				)
			})
		})

		describe('list()', () => {
			it('lists models', async () => {
				const { total, results, size, sort, from } = await tested.list()
				expect(results).toEqual(expect.arrayContaining(models))
				expect(results).toHaveLength(models.length)
				expect(total).toEqual(models.length)
				expect(size).toEqual(10)
				expect(from).toEqual(0)
				expect(sort).toEqual('+id')
			})

			it('lists models with order and pagination', async () => {
				const { total, from, size, sort, results } = await tested.list({
					size: 2,
					from: 1,
					sort: '-name'
				})
				const sorted = models.sort((m1, m2) =>
					m1.name > m2.name ? -1 : m1.name === m2.name ? 0 : 1
				)
				expect(results).toEqual(sorted.slice(1, 3))
				expect(results).toHaveLength(size)
				expect(total).toEqual(models.length)
				expect(size).toEqual(2)
				expect(from).toEqual(1)
				expect(sort).toEqual('-name')
			})

			it('lists models with bigger size than resultset', async () => {
				const { total, from, size, sort, results } = await tested.list({
					size: 100
				})
				expect(results).toEqual(models.sort((a, b) => a.id - b.id))
				expect(total).toEqual(models.length)
				expect(size).toEqual(100)
				expect(from).toEqual(0)
				expect(sort).toEqual('+id')
			})

			it('lists models with out of range page', async () => {
				const { total, from, size, sort, results } = await tested.list({
					from: 10
				})
				expect(results).toEqual([])
				expect(total).toEqual(models.length)
				expect(size).toEqual(10)
				expect(from).toEqual(10)
				expect(sort).toEqual('+id')
			})
		})

		describe('count()', () => {
			it('counts models', async () => {
				expect(await tested.count()).toBe(models.length)
			})
		})

		describe('getByIds()', () => {
			it('get model by id', async () => {
				const model = models[1]
				const results = await tested.getById(model.id)
				expect(results).toEqual(model)
			})

			it('returns null when getting unknown model by id', async () => {
				expect(await tested.getById(faker.number.int())).toBe(null)
			})

			it('gets models by ids', async () => {
				const results = await tested.getByIds([models[0].id, models[3].id, faker.number.int()])
				expect(results).toEqual(expect.arrayContaining([models[0], models[3]]))
				expect(results).toHaveLength(2)
			})
		})

		describe('removeByIds()', () => {
			it('removes models by ids', async () => {
				const removed = await tested.removeByIds([models[0].id, models[3].id, faker.number.int()])

				expect(removed).toEqual(expect.arrayContaining([models[0], models[3]]))
				expect(removed).toHaveLength(2)
				const ids = db
					.prepare(`SELECT id FROM ${modelName} WHERE ${whereIn('id', models)}`)
					.all(...models.map(({ id }) => id))
					.map(({ id }) => id)
				expect(ids).toEqual(expect.not.arrayContaining([models[0].id, models[3].id]))
				expect(ids).toHaveLength(2)
			})
		})
	})
})
