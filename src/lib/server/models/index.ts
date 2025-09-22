import { mkdir } from 'node:fs/promises'
import { dirname } from 'node:path'
import type { DBConf } from '$lib/utils/types'
import { AbstractModel } from './abstract-model'
import { type Dancer, dancersModel } from './dancer'

export { AbstractModel, dancersModel }
export type { Dancer }

/** Initializes all model classes. */
export async function init(conf: DBConf, migrate = true) {
	await mkdir(dirname(conf.filename), { recursive: true })
	await dancersModel.init(conf, migrate)
}
