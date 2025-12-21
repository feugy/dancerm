import { AbstractModel } from './abstract-model'

export interface Card {
	id: string
	_v: number
	knownBy: string[]
	registrations: unknown[]
}

export class CardsModel extends AbstractModel<Card> {
	constructor() {
		super({
			table: 'card',
			columns: [
				{ name: 'id', type: 'auto' },
				{ name: '_v', type: 'auto' },
				{ name: 'knownBy', type: 'json' },
				{ name: 'registrations', type: 'json' }
			]
		})
	}
}

export const cardsModel = new CardsModel()
