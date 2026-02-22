import { error, redirect } from '@sveltejs/kit'
import * as v from 'valibot'
import { command, form, query } from '$app/server'
import { DATABASE_PATH } from '$env/static/private'
import {
	type Address,
	addressesModel,
	type Card,
	cardsModel,
	dancersModel,
	init
} from '$lib/server/models'
import { isNew } from './utils/models'

const filename = DATABASE_PATH

export const getDancers = query(async () => {
	await init({ filename })
	return dancersModel.list()
})

export const listDanceClassDancers = query(v.string(), async (danceClassId: string) => {
	await init({ filename })
	return dancersModel.listByDanceClass(danceClassId)
})

export const getDancer = query(v.string(), async (id: string) => {
	await init({ filename })
	const dancer = await dancersModel.getById(id)
	if (!dancer) redirect(307, '/dancers')
	return dancer
})

export const getRelatedDancers = query(v.string(), async (cardId: string) => {
	await init({ filename })
	return dancersModel.listByCard(cardId)
})

export const saveDancer = form(
	v.object({
		id: v.string(),
		_v: v.number(),
		title: v.pipe(v.string(), v.nonEmpty()),
		firstname: v.string(),
		lastname: v.optional(v.string()),
		cellphone: v.optional(v.string()),
		email: v.optional(v.string()),
		birth: v.optional(v.string()),
		address: v.optional(
			v.object({
				id: v.string(),
				street: v.optional(v.string()),
				zipcode: v.optional(v.pipe(v.number(), v.integer(), v.minValue(0))),
				city: v.optional(v.string()),
				phone: v.optional(v.string())
			})
		),
		card: v.optional(
			v.object({
				id: v.string(),
				knownBy: v.optional(v.array(v.string()), [])
			})
		)
	}),

	async (dancer) => {
		await init({ filename })
		let card: Card | undefined
		if (dancer.card) {
			card =
				(Object.keys(dancer.card).length === 1
					? await cardsModel.getById(dancer.card.id)
					: (await cardsModel.save(dancer.card))[0]) ?? undefined
		}
		let address: Address | undefined
		if (dancer.address) {
			address =
				(Object.keys(dancer.address).length === 1
					? await addressesModel.getById(dancer.address.id)
					: (await addressesModel.save(dancer.address))[0]) ?? undefined
		}

		const [saved] = await dancersModel.save({
			danceClassIds: isNew(dancer) ? [] : undefined,
			...dancer,
			birth: dancer.birth ? new Date(dancer.birth) : null,
			address,
			card
		})

		const dancerId = saved.id
		// fetch the full dancer with address and card populated.
		const result = await dancersModel.getById(dancerId)
		if (result) {
			const cardId = result.card.id
			getDancer(dancerId).set(result)
			getRelatedDancers(cardId).set(await dancersModel.listByCard(cardId))
			return result
		}
	}
)

export const deleteDancer = command(
	v.object({
		id: v.string(),
		address: v.nullish(
			v.object({
				id: v.string()
			})
		),
		card: v.optional(
			v.object({
				id: v.string()
			})
		)
	}),
	async (dancer) => {
		await init({ filename })
		await dancersModel.removeByIds([dancer.id])
		const addressId = dancer.address?.id
		if (addressId) {
			const related = await dancersModel.listByAddress(addressId)
			if (related.length === 0) {
				await addressesModel.removeByIds([addressId])
			}
		}
		const cardId = dancer.card?.id
		if (cardId) {
			getRelatedDancers(cardId).refresh()
			const related = await dancersModel.listByCard(cardId)
			if (related.length === 0) {
				await cardsModel.removeByIds([cardId])
			}
		}
	}
)

export const removeFromAddress = command(
	v.object({
		dancer: v.object({
			id: v.string(),
			address: v.nullish(
				v.object({
					id: v.string()
				})
			),
			card: v.optional(
				v.object({
					id: v.string()
				})
			)
		}),
		newAddressId: v.string()
	}),
	async ({ dancer, newAddressId }) => {
		await init({ filename })
		const address = await addressesModel.getById(newAddressId)
		if (!address) {
			error(400, { message: `No address found with id ${newAddressId}` })
		}

		const oldAddressId = dancer.address?.id
		const related = await dancersModel.listByAddress(oldAddressId ?? '')
		if (!oldAddressId || related.every(({ id }) => id !== dancer.id)) {
			error(400, { message: `Dancer is not assigned to old address id ${oldAddressId}` })
		}

		let card: Card | undefined
		if (dancer.card) {
			card = (await cardsModel.getById(dancer.card.id)) ?? undefined
		}
		const saved = (await dancersModel.save({ ...dancer, card, address }))[0]
		getDancer(dancer.id).set(saved)
		if (card?.id) {
			getRelatedDancers(card.id).refresh()
		}
		if (related.length === 1) {
			await addressesModel.removeByIds([oldAddressId])
		}
	}
)
