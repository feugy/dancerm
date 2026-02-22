import { mkdir } from 'node:fs/promises'
import { dirname } from 'node:path'
import type { DBConf } from '$lib/utils/types'
import { importModels } from '../utils/import'
import { AbstractModel } from './abstract-model'
import { type Address, addressesModel } from './address'
import { type Card, cardsModel } from './card'
import { type DanceClass, danceClassesModel } from './dance-class'
import { type Dancer, dancersModel } from './dancer'

export { AbstractModel, dancersModel, cardsModel, addressesModel, danceClassesModel }
export type { Address, Card, Dancer, DanceClass }

let imported = false

/** Initializes all model classes. */
export async function init(conf: DBConf, migrate = true) {
	await mkdir(dirname(conf.filename), { recursive: true })
	await addressesModel.init(conf, migrate)
	await dancersModel.init(conf, false)
	await cardsModel.init(conf, false)
	await danceClassesModel.init(conf, false)

	if (!imported) {
		console.log('importing data...')
		const data = (await import(`./migrations/danceRM.json?raw`)).default
		await importModels(data)
		console.log('data imported successfully')
		imported = true
	}
}
