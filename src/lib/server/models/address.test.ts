import { faker } from '@faker-js/faker'
import { afterAll, beforeAll, describe, expect, it } from 'vitest'
import { cleanTestTB, initTestDB } from '$lib/tests/database'
import type { DBConf, PartialWithReq } from '$lib/utils/types'
import { type Address, addressesModel } from './address'

describe('Addresses model', () => {
	let conf: DBConf
	beforeAll(async () => {
		;({ conf } = await initTestDB())
		await addressesModel.init(conf)
	})

	afterAll(async () => {
		await cleanTestTB(conf)
	})

	describe('save()', () => {
		it('adds new Address', async () => {
			const address: PartialWithReq<Address, 'id'> = {
				id: faker.number.int().toString(),
				street: faker.location.street(),
				city: faker.location.city(),
				zipcode: Number.parseFloat(faker.location.zipCode()),
				phone: faker.phone.number()
			}

			expect(await addressesModel.save(address)).toEqual([{ ...address, _v: 1 }])
			expect(await addressesModel.getById(address.id)).toEqual({ ...address, _v: 1 })
		})
	})
})
