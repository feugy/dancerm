import * as v from 'valibot'
import { query } from '$app/server'
import { DATABASE_PATH } from '$env/static/private'
import { danceClassesModel, init } from '$lib/server/models'

const filename = DATABASE_PATH

export const getSeasonsAndPlanning = query(v.nullable(v.string()), async (season) => {
	await init({ filename })
	const seasons = await danceClassesModel.listSeasons()
	const selectedSeason = season && seasons.includes(season) ? season : seasons[0]
	return {
		seasons,
		selectedSeason,
		planning: await danceClassesModel.buildPlanning(selectedSeason)
	}
})
