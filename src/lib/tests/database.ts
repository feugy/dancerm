import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { DatabaseSync } from 'node:sqlite'
import { AbstractModel } from '$lib/server/models/abstract-model'
import { makeSerializer } from '$lib/server/utils/sqlite'
import type { DBConf } from '$lib/utils/types'

export async function initTestDB() {
	const conf: DBConf = {
		filename: join(await mkdtemp(join(tmpdir(), 'dancerm-')), 'db.sqlite3')
	}
	return { conf, db: new DatabaseSync(conf.filename) }
}

export async function cleanTestTB(conf: DBConf) {
	AbstractModel.release()
	await rm(conf.filename, { force: true })
}

export function serializeModel<T extends { id: number; _v: number }>(
	model: Record<string, unknown>,
	modelClass: AbstractModel<T>
) {
	return addVersion(makeSerializer(modelClass)(model), (model as { _v: number })._v)
}

export function serializeModels<T extends { id: number; _v: number }>(
	models: Record<string, unknown>[],
	modelClass: AbstractModel<T>
) {
	const serialize = makeSerializer(modelClass)
	return models.map((m) => addVersion(serialize(m), (m as { _v: number })._v))
}

export function addVersion<T>(model: T, _v = 1): T {
	return { _v, ...model }
}
