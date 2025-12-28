import { redirect } from '@sveltejs/kit'
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

const filename = DATABASE_PATH

export const getDancers = query(async () => {
	await init({ filename })
	return dancersModel.list()
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

	async (data) => {
		await init({ filename })
		let card: Card | undefined
		if (data.card) {
			card =
				(Object.keys(data.card).length === 1
					? await cardsModel.getById(data.card.id)
					: (await cardsModel.save(data.card))[0]) ?? undefined
		}
		let address: Address | undefined
		if (data.address) {
			address =
				(Object.keys(data.address).length === 1
					? await addressesModel.getById(data.address.id)
					: (await addressesModel.save(data.address))[0]) ?? undefined
		}

		const [saved] = await dancersModel.save({
			...data,
			birth: data.birth ? new Date(data.birth) : null,
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
	async (data) => {
		await init({ filename })
		await dancersModel.removeByIds([data.id])
		const addressId = data.address?.id
		if (addressId) {
			const related = await dancersModel.listByAddress(addressId)
			if (related.length === 0) {
				await addressesModel.removeByIds([addressId])
			}
		}
		const cardId = data.card?.id
		if (cardId) {
			getRelatedDancers(cardId).refresh()
			const related = await dancersModel.listByCard(cardId)
			if (related.length === 0) {
				await cardsModel.removeByIds([cardId])
			}
		}
	}
)
