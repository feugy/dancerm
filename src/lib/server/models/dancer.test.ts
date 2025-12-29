import { faker } from '@faker-js/faker'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { cleanTestTB, initTestDB } from '$lib/tests/database'
import type { DBConf } from '$lib/utils/types'
import { type Address, addressesModel } from './address'
import { type Card, cardsModel } from './card'
import { type Dancer, DancersModel, dancersModel } from './dancer'

describe('Dancers model', () => {
	let conf: DBConf
	beforeEach(async () => {
		;({ conf } = await initTestDB())
		await dancersModel.init(conf)
		await cardsModel.init(conf, false)
		await addressesModel.init(conf, false)
	})

	afterEach(async () => {
		DancersModel.release()
		await cleanTestTB(conf)
	})

	describe('save()', () => {
		let card: Card

		beforeEach(async () => {
			card = (
				await cardsModel.save({
					id: faker.string.uuid(),
					knownBy: [],
					registrations: []
				})
			)[0]
		})

		it('adds new dancer', async () => {
			const result: Dancer = {
				id: faker.string.uuid(),
				_v: 1,
				created: new Date(),
				title: 'M.',
				firstname: faker.person.firstName(),
				lastname: faker.person.lastName(),
				cellphone: faker.phone.number(),
				email: faker.internet.email(),
				birth: faker.date.past(),
				address: null,
				card
			}

			expect(await dancersModel.save(result)).toEqual([{ ...result }])
			expect(await dancersModel.getById(result.id)).toEqual(result)
			expect((await dancersModel.list()).results).toEqual(expect.arrayContaining([result]))
		})

		it('adds new dancer on an existing address', async () => {
			const [address] = await addressesModel.save({
				id: faker.string.uuid(),
				_v: 1,
				street: faker.location.streetAddress(),
				zipcode: faker.number.int(),
				city: faker.location.city(),
				phone: faker.phone.number()
			})

			const result: Dancer = {
				id: faker.string.uuid(),
				_v: 1,
				created: new Date(),
				title: 'M.',
				firstname: faker.person.firstName(),
				lastname: faker.person.lastName(),
				cellphone: faker.phone.number(),
				email: faker.internet.email(),
				birth: faker.date.past(),
				address,
				card
			}

			expect(await dancersModel.save(result)).toEqual([result])
			expect(await dancersModel.getById(result.id)).toEqual(result)
			expect((await dancersModel.list()).results).toEqual(expect.arrayContaining([result]))
		})

		it('keeps omitted fields', async () => {
			const [address] = await addressesModel.save({
				id: faker.string.uuid(),
				_v: 1,
				street: faker.location.streetAddress(),
				zipcode: faker.number.int(),
				city: faker.location.city(),
				phone: faker.phone.number()
			})

			const dancer = (
				await dancersModel.save({
					id: faker.string.uuid(),
					_v: 1,
					created: new Date(),
					title: 'M.',
					firstname: faker.person.firstName(),
					lastname: faker.person.lastName(),
					cellphone: faker.phone.number(),
					email: faker.internet.email(),
					birth: faker.date.past(),
					address,
					card
				})
			)[0]

			const newFirstname = `${dancer.firstname}-2`
			const result = { ...dancer, _v: 2, firstname: newFirstname }
			expect(
				await dancersModel.save({
					id: dancer.id,
					firstname: newFirstname
				})
			).toEqual([{ ...result, address: null, card: null }]) // address is null because of partial save
			expect(await dancersModel.getById(dancer.id)).toEqual(result)
			expect((await dancersModel.list()).results).toEqual(expect.arrayContaining([result]))
		})
	})

	describe('listByCard()', () => {
		let card1: Card
		let card2: Card

		beforeEach(async () => {
			;[card1, card2] = await cardsModel.save([
				{
					id: faker.string.uuid(),
					knownBy: [],
					registrations: []
				},
				{
					id: faker.string.uuid(),
					knownBy: [],
					registrations: []
				}
			])
		})

		it('returns dancers with specific card', async () => {
			const [dancer1, dancer2, dancer3] = await dancersModel.save([
				{
					id: faker.string.uuid(),
					_v: 1,
					created: new Date(),
					title: 'M.',
					firstname: faker.person.firstName(),
					lastname: faker.person.lastName(),
					cellphone: faker.phone.number(),
					email: faker.internet.email(),
					birth: faker.date.past(),
					address: null,
					card: card1
				},
				{
					id: faker.string.uuid(),
					_v: 1,
					created: new Date(),
					title: 'Mme.',
					firstname: faker.person.firstName(),
					lastname: faker.person.lastName(),
					cellphone: faker.phone.number(),
					email: faker.internet.email(),
					birth: faker.date.past(),
					address: null,
					card: card1
				},
				{
					id: faker.string.uuid(),
					_v: 1,
					created: new Date(),
					title: 'M.',
					firstname: faker.person.firstName(),
					lastname: faker.person.lastName(),
					cellphone: faker.phone.number(),
					email: faker.internet.email(),
					birth: faker.date.past(),
					address: null,
					card: card2
				}
			])

			const result = await dancersModel.listByCard(card1.id)
			expect(result).toHaveLength(2)
			expect(result).toEqual(expect.arrayContaining([dancer1, dancer2]))
			expect(result).not.toEqual(expect.arrayContaining([dancer3]))
		})

		it('returns empty array when no dancers found for card', async () => {
			expect(await dancersModel.listByCard('non-existent-card-id')).toEqual([])
		})

		it('throws error when model not initialized', async () => {
			const uninitializedModel = new DancersModel()
			await expect(() => uninitializedModel.listByCard('card-id')).rejects.toThrow(
				'model not initialized'
			)
		})
	})

	describe('listByAddress()', () => {
		let address1: Address
		let address2: Address
		let card1: Card
		let card2: Card

		beforeEach(async () => {
			;[card1, card2] = await cardsModel.save([
				{
					id: faker.string.uuid(),
					knownBy: [],
					registrations: []
				},
				{
					id: faker.string.uuid(),
					knownBy: [],
					registrations: []
				}
			])
			;[address1, address2] = await addressesModel.save([
				{
					id: faker.string.uuid(),
					street: faker.location.street(),
					zipcode: faker.number.int(),
					city: faker.location.city(),
					phone: faker.phone.number()
				},
				{
					id: faker.string.uuid(),
					street: faker.location.street(),
					zipcode: faker.number.int(),
					city: faker.location.city(),
					phone: faker.phone.number()
				}
			])
		})

		it('returns dancers with specific address', async () => {
			const [dancer1, dancer2, dancer3] = await dancersModel.save([
				{
					id: faker.string.uuid(),
					_v: 1,
					created: new Date(),
					title: 'M.',
					firstname: faker.person.firstName(),
					lastname: faker.person.lastName(),
					cellphone: faker.phone.number(),
					email: faker.internet.email(),
					birth: faker.date.past(),
					address: address1,
					card: card1
				},
				{
					id: faker.string.uuid(),
					_v: 1,
					created: new Date(),
					title: 'Mme.',
					firstname: faker.person.firstName(),
					lastname: faker.person.lastName(),
					cellphone: faker.phone.number(),
					email: faker.internet.email(),
					birth: faker.date.past(),
					address: address1,
					card: card2
				},
				{
					id: faker.string.uuid(),
					_v: 1,
					created: new Date(),
					title: 'M.',
					firstname: faker.person.firstName(),
					lastname: faker.person.lastName(),
					cellphone: faker.phone.number(),
					email: faker.internet.email(),
					birth: faker.date.past(),
					address: address2,
					card: card2
				}
			])

			const result = await dancersModel.listByAddress(address1.id)
			expect(result).toHaveLength(2)
			expect(result).toEqual(expect.arrayContaining([dancer1, dancer2]))
			expect(result).not.toEqual(expect.arrayContaining([dancer3]))
		})

		it('returns empty array when no dancers found for address', async () => {
			expect(await dancersModel.listByAddress('non-existent-address-id')).toEqual([])
		})

		it('throws error when model not initialized', async () => {
			const uninitializedModel = new DancersModel()
			await expect(() => uninitializedModel.listByAddress('address-id')).rejects.toThrow(
				'model not initialized'
			)
		})
	})
})
