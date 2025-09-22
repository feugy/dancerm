import { dancersModel, init } from '$lib/server/models'
import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async ({ params: { id } }) => {
	await init({ filename: 'dancers.sqlite3' })
	return {
		dancer: await dancersModel.getById(id)
	}
}
