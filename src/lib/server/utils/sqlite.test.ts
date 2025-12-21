import { faker } from '@faker-js/faker'
import { describe, expect, it } from 'vitest'
import type { Column } from '$lib/utils/types'
import { buildUpsert, whereIn } from './sqlite'

describe('whereIn()', () => {
	it('returns an empty string for empty array', () => {
		expect(whereIn(faker.database.column(), [])).toBe('')
	})

	it('insert as many placeholders as the array length', () => {
		const column = faker.database.column()
		expect(whereIn(column, [1, 2, 3])).toBe(`${column} IN (?,?,?)`)
	})
})

describe('buildUpsert()', () => {
	it('does not include id in upserted fields', () => {
		const table = faker.database.column()
		const columns: Column[] = [
			{ name: 'id', type: 'auto' },
			{ name: 'f1', type: 'auto' },
			{ name: 'f2', type: 'auto' }
		]
		expect(buildUpsert(table, columns)).toEqual(`INSERT INTO ${table} (id, f1, f2) 
VALUES (:id, :f1, :f2)
ON CONFLICT(id) DO UPDATE SET
f1=if(excluded.f1='', f1, excluded.f1),
f2=if(excluded.f2='', f2, excluded.f2),
_v=_v+1`)
	})
})
