import { dancersModel, init } from '$lib/server/models'
import type { PageServerLoad } from './$types'

export const load: PageServerLoad = async () => {
	await init({ filename: 'dancers.sqlite3' })
	return {
		dancers: await dancersModel.list()
	}
}
