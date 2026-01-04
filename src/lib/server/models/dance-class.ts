import { buildSelect, makeDeserializer } from '$lib/server/utils/sqlite'
import { parseTime } from '$lib/utils/models'
import { AbstractModel } from './abstract-model'

export interface DanceClass {
	id: string
	_v: number
	season: string | null
	start: string | null
	end: string | null
	kind: string | null
	level: string | null
	room: string | null
	color: string | null
	teacher: string | null
}

export class DanceClassesModel extends AbstractModel<DanceClass> {
	constructor() {
		super({
			table: 'danceclass',
			columns: [
				{ name: 'id', type: 'auto' },
				{ name: '_v', type: 'auto' },
				{ name: 'season', type: 'auto' },
				{ name: 'start', type: 'auto' },
				{ name: 'end', type: 'auto' },
				{ name: 'kind', type: 'auto' },
				{ name: 'level', type: 'auto' },
				{ name: 'room', type: 'auto' },
				{ name: 'color', type: 'auto' },
				{ name: 'teacher', type: 'auto' }
			]
		})
	}

	async listSeasons() {
		if (!this.db) throw new Error('model not initialized')
		const query = `SELECT DISTINCT season FROM ${this.table} ORDER BY season DESC`
		this.logger.debug({ query }, 'build season planning')
		const result = this.db
			.prepare(query)
			.all()
			.map(({ season }) => season as string)

		this.logger.info({ length: result.length }, 'season listed')
		return result
	}

	async buildPlanning(season: string) {
		if (!this.db) throw new Error('model not initialized')
		const query = `${buildSelect(this.table, this.columns)} WHERE ${this.table}.season = :season`
		this.logger.debug({ query, season }, 'build season planning')
		const deserialize = makeDeserializer<DanceClass>(this, true)
		const result = this.db
			.prepare(query)
			.all({ season })
			.map((model) => deserialize(model) as DanceClass)

		this.logger.info({ season, length: result.length }, 'season planning built')
		// sort classes by week day, then hour, then minutes
		return result.sort(({ start: a }, { start: b }) => {
			const timeA = parseTime(a)
			const timeB = parseTime(b)
			if (!timeA) return -1
			if (!timeB) return 1
			if (timeA.day < timeB.day) {
				return -1
			} else if (timeA.day > timeB.day) {
				return 1
			} else if (timeA.hour < timeB.hour) {
				return -1
			} else if (timeA.hour > timeB.hour) {
				return 1
			} else if (timeA.minutes < timeB.minutes) {
				return -1
			} else if (timeA.minutes > timeB.minutes) {
				return 1
			} else {
				return 0
			}
		})
	}
}

export const danceClassesModel = new DanceClassesModel()
