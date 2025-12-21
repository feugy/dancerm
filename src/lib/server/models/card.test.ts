import { faker } from '@faker-js/faker'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { cleanTestTB, initTestDB } from '$lib/tests/database'
import type { DBConf, PartialWithReq } from '$lib/utils/types'
import { type Card, cardsModel } from './card'

describe('Cards model', () => {
	let conf: DBConf
	beforeAll(async () => {
		;({ conf } = await initTestDB())
		await cardsModel.init(conf)
	})

	afterAll(async () => {
		await cleanTestTB(conf)
	})

	describe('save()', () => {
		it('adds new card', async () => {
			const card: PartialWithReq<Card, 'id'> = {
				id: faker.number.int().toString(),
				knownBy: ['website', 'mouth'],
				registrations: []
			}

			expect(await cardsModel.save(card)).toEqual([{ ...card, _v: 1 }])
			expect(await cardsModel.getById(card.id)).toEqual({ ...card, _v: 1 })
		})
	})
})
