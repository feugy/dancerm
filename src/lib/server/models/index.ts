import { mkdir } from 'node:fs/promises'
import { dirname } from 'node:path'
import type { DBConf } from '$lib/utils/types'
import { AbstractModel } from './abstract-model'
import { type Address, addressesModel } from './address'
import { type Card, cardsModel } from './card'
import { type DanceClass, danceClassesModel } from './dance-class'
import { type Dancer, dancersModel } from './dancer'

export { AbstractModel, dancersModel, cardsModel, addressesModel, danceClassesModel }
export type { Address, Card, Dancer, DanceClass }

/** Initializes all model classes. */
export async function init(conf: DBConf, migrate = true) {
	await mkdir(dirname(conf.filename), { recursive: true })
	await addressesModel.init(conf, migrate)
	await dancersModel.init(conf, false)
	await cardsModel.init(conf, false)
	await danceClassesModel.init(conf, false)
}
