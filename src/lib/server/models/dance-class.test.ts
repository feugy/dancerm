import { faker } from '@faker-js/faker'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { cleanTestTB, initTestDB } from '$lib/tests/database'
import type { DBConf } from '$lib/utils/types'
import { type DanceClass, DanceClassesModel, danceClassesModel } from './dance-class'

describe('DanceClasses model', () => {
	let conf: DBConf
	beforeEach(async () => {
		;({ conf } = await initTestDB())
		await danceClassesModel.init(conf)
	})

	afterEach(async () => {
		DanceClassesModel.release()
		await cleanTestTB(conf)
	})

	describe('save()', () => {
		it('adds new dance class', async () => {
			const result: DanceClass = {
				id: faker.string.uuid(),
				_v: 1,
				season: faker.string.uuid(),
				start: faker.date.soon().toISOString(),
				end: faker.date.soon().toISOString(),
				kind: faker.animal.type(),
				level: faker.number.int({ min: 1, max: 5 }).toString(),
				room: faker.hacker.noun(),
				color: faker.color.human(),
				teacher: faker.person.firstName()
			}

			expect(await danceClassesModel.save(result)).toEqual([{ ...result }])
			expect(await danceClassesModel.getById(result.id)).toEqual(result)
		})
	})

	describe('listSeasons()', () => {
		it('returns planning of a given season', async () => {
			expect(await danceClassesModel.listSeasons()).toEqual([
				'2025/2026',
				'2024/2025',
				'2023/2024',
				'2022/2023',
				'2021/2022',
				'2020/2021',
				'2019/2020',
				'2018/2019',
				'2017/2018',
				'2016/2017',
				'2015/2016',
				'2014/2015',
				'2013/2014'
			])
		})

		it('throws error when model not initialized', async () => {
			const uninitializedModel = new DanceClassesModel()
			await expect(() => uninitializedModel.listSeasons()).rejects.toThrow('model not initialized')
		})
	})

	describe('buildPlanning()', () => {
		it('returns planning of a given season', async () => {
			const result = await danceClassesModel.buildPlanning('2025/2026')
			expect(
				result.map(({ season, start, room, level }) => ({ season, start, room, level }))
			).toEqual([
				{ level: 'Initiation 2', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Mon 17:15' },
				{ level: 'Zumba Kids', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Mon 18:00' },
				{ level: 'Solo technique', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Mon 18:30' },
				{ level: 'Zumba Adulte', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Mon 19:00' },
				{ level: 'RS1', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Mon 19:30' },
				{ level: 'TD1', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Mon 20:00' },
				{ level: 'RS4', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Mon 20:30' },
				{ level: 'TD2', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Mon 21:00' },
				{
					level: 'Zumba Mini kids',
					room: 'Gratte-ciel 1',
					season: '2025/2026',
					start: 'Tue 17:15'
				},
				{ level: 'TD1', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Tue 19:00' },
				{ level: 'Jazz 1', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Tue 19:30' },
				{ level: 'RS2', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Tue 20:00' },
				{ level: 'Latines', room: 'Croix-Luizet', season: '2025/2026', start: 'Tue 20:00' },
				{ level: 'Jazz 3', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Tue 20:30' },
				{ level: 'RS3', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Tue 21:00' },
				{ level: 'Initiation 1', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 10:00' },
				{ level: 'Initiation 2', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 11:00' },
				{ level: 'Initiation 1', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 14:00' },
				{ level: 'Elementaire 1', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Wed 14:00' },
				{ level: 'Initiation 2', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 15:00' },
				{ level: 'Elementaire 2', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Wed 15:00' },
				{ level: 'Pré-ado', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Wed 16:00' },
				{ level: 'DS1', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 16:00' },
				{ level: 'Solo LAT', room: 'Croix-Luizet', season: '2025/2026', start: 'Wed 16:30' },
				{ level: 'Ado', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Wed 17:00' },
				{ level: 'DS2', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 17:00' },
				{ level: 'Entrainement', room: 'Croix-Luizet', season: '2025/2026', start: 'Wed 17:15' },
				{ level: 'Solo STD', room: 'Croix-Luizet', season: '2025/2026', start: 'Wed 17:45' },
				{ level: 'Heels', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Wed 18:30' },
				{ level: 'Zumba Ados', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 18:30' },
				{ level: 'Couples', room: 'Croix-Luizet', season: '2025/2026', start: 'Wed 18:45' },
				{ level: 'RS1', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 19:30' },
				{ level: 'Zumba adulte', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Wed 19:30' },
				{ level: 'Jazz 2', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Wed 20:30' },
				{ level: 'TD3', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Wed 20:30' },
				{ level: 'HH Enfant', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Thu 17:15' },
				{ level: 'HH Ado', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Thu 18:00' },
				{ level: 'HH Adulte', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Thu 19:00' },
				{ level: 'RS1', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Thu 20:00' },
				{ level: 'Standards', room: 'Gratte-ciel 2', season: '2025/2026', start: 'Thu 20:15' },
				{ level: 'RS2', room: 'Gratte-ciel 1', season: '2025/2026', start: 'Thu 21:00' }
			])
		})

		it('returns nothing for a n unknown season', async () => {
			expect(await danceClassesModel.buildPlanning('non-existent-season')).toEqual([])
		})

		it('throws error when model not initialized', async () => {
			const uninitializedModel = new DanceClassesModel()
			await expect(() => uninitializedModel.buildPlanning('season-id')).rejects.toThrow(
				'model not initialized'
			)
		})
	})
})
