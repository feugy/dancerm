import { AbstractModel } from './abstract-model'

export interface Address {
	id: string
	_v: number
	street: string | null
	zipcode: number | null
	city: string | null
	phone: string | null
}

export class AddressesModel extends AbstractModel<Address> {
	constructor() {
		super({
			table: 'address',
			columns: [
				{ name: 'id', type: 'auto' },
				{ name: '_v', type: 'auto' },
				{ name: 'street', type: 'auto' },
				{ name: 'zipcode', type: 'auto' },
				{ name: 'city', type: 'auto' },
				{ name: 'phone', type: 'auto' }
			]
		})
	}
}

export const addressesModel = new AddressesModel()
