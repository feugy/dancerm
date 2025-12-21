import * as v from 'valibot'
import { form } from '$app/server'
import { DATABASE_PATH } from '$env/static/private'
import { cardsModel, init } from '$lib/server/models'

const filename = DATABASE_PATH

export const saveCard = form(
	v.object({
		id: v.string(),
		knownBy: v.optional(v.array(v.string()), [])
	}),

	async (data) => {
		await init({ filename })
		const [saved] = await cardsModel.save(data)
		return saved
	}
)
