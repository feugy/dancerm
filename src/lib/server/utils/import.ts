import {
	type AbstractModel,
	addressesModel,
	cardsModel,
	danceClassesModel,
	dancersModel
} from '../models'

const separator = '------MODELS------'

export async function importModels(text: string) {
	const classByName = new Map<string, AbstractModel<{ id: string | number; _v: number }>>([
		['Address', addressesModel],
		['Card', cardsModel],
		['DanceClass', danceClassesModel],
		['Dancer', dancersModel]
	])

	const records: Record<string, { id: string }[]> = {}
	let list: { id: string }[] = []
	let name: string | null = null
	for (const line of text.split('\n')) {
		if (line.startsWith(separator)) {
			if (name) {
				records[name] = list
			}
			name = line.replace(separator, '').trim()
			list = []
		} else if (name && line.trim().length > 0) {
			try {
				list.push(JSON.parse(line.trim()))
			} catch {}
		}
	}
	for (const [name, inserted] of Object.entries(records)) {
		const model = classByName.get(name)
		if (!model) continue
		const ids = new Set([...inserted.map(({ id }) => id)])
		const existing = await model.getByIds([...ids])
		for (const item of inserted) {
			if (existing.every(({ id }) => id !== item.id) && isValid(item, model)) {
				await model.save(item)
			}
			// TODO merge logic
		}
	}
	// TODO remove dangling cards and addresses
}

function isValid(_item: { id: string } & Record<string, unknown>, _model: unknown): boolean {
	// TODO validation logic
	return true
}
