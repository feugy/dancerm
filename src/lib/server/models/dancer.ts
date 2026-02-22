import { buildSelect, makeDeserializer } from '$lib/server/utils/sqlite'
import { AbstractModel } from './abstract-model'
import { type Address, addressesModel } from './address'
import { type Card, cardsModel } from './card'

export interface Dancer {
	id: string
	_v: number
	created: Date | null
	title: string | null
	firstname: string | null
	lastname: string | null
	cellphone: string | null
	email: string | null
	birth: Date | null
	address: Address | null
	card: Card
	danceClassIds: string[]
}

export class DancersModel extends AbstractModel<Dancer> {
	constructor() {
		super({
			table: 'dancer',
			columns: [
				{ name: 'id', type: 'auto' },
				{ name: '_v', type: 'auto' },
				{ name: 'created', type: 'date' },
				{ name: 'title', type: 'auto' },
				{ name: 'firstname', type: 'auto' },
				{ name: 'lastname', type: 'auto' },
				{ name: 'cellphone', type: 'auto' },
				{ name: 'email', type: 'auto' },
				{ name: 'birth', type: 'date' },
				{ name: 'addressId', type: 'reference', model: addressesModel },
				{ name: 'cardId', type: 'reference', model: cardsModel },
				{ name: 'danceClassIds', type: 'json' }
			]
		})
	}

	async listByCard(cardId: string) {
		if (!this.db) throw new Error('model not initialized')
		const query = `${buildSelect(this.table, this.columns)} WHERE ${this.table}.cardId = :cardId`
		this.logger.debug({ query, cardId }, 'list models by card')
		const deserialize = makeDeserializer<Dancer>(this, true)
		const result = this.db
			.prepare(query)
			.all({ cardId })
			.map((model) => deserialize(model) as Dancer)
		this.logger.info({ cardId, length: result.length }, 'list by card')
		return result
	}

	async listByAddress(addressId: string) {
		if (!this.db) throw new Error('model not initialized')
		const query = `${buildSelect(this.table, this.columns)} WHERE ${this.table}.addressId = :addressId`
		this.logger.debug({ query, addressId }, 'list models by address')
		const deserialize = makeDeserializer<Dancer>(this, true)
		const result = this.db
			.prepare(query)
			.all({ addressId })
			.map((model) => deserialize(model) as Dancer)
		this.logger.info({ addressId, length: result.length }, 'list by address')
		return result
	}

	async listByDanceClass(danceClassId: string) {
		if (!this.db) throw new Error('model not initialized')
		const query = `${buildSelect(this.table, this.columns)}, json_each(${this.table}.danceClassIds, '$') WHERE json_each.value = :danceClassId`
		this.logger.debug({ query, danceClassId }, 'list models by dance class')
		const deserialize = makeDeserializer<Dancer>(this, true)
		const result = this.db
			.prepare(query)
			.all({ danceClassId })
			.map((model) => deserialize(model) as Dancer)
		this.logger.info({ danceClassId, length: result.length }, 'list by dance class')
		return result
	}
}

export const dancersModel = new DancersModel()
