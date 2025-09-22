import { AbstractModel } from './abstract-model'

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
}

/**
 * Base class for all models containing references to tracks: Albums, Artists, Playlists.
 * Computes references automatically, and ensures reference integrity.
 */
export class DancersModel extends AbstractModel<Dancer> {
	constructor() {
		super({ name: 'Dancer' })
	}
}

export const dancersModel = new DancersModel()
