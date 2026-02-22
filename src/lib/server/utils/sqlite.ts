import type { SQLInputValue, SQLOutputValue } from 'node:sqlite'
import type { Column } from '$lib/utils/types'

/**
 * Returns SQL positional placeholders to match a list of values against a column.
 * @param column matched column.
 * @param values number of matched values.
 */
export function whereIn(column: string, { length }: unknown[]) {
	return length ? `${column} IN (${new Array(length).fill('?').join(',')})` : ''
}

/**
 * Returns the INSERT statement to insert or update given table (which primary key is column "id") given a list of columns.
 * @param table upserted table.
 * @param columns model columns
 * @param returning whether to return the inserted/updated rows.
 */
export function buildUpsert(table: string, columns: Column[], returning = false) {
	const colNames = []
	const paramNames = []
	const conflictClause = []
	for (const { name } of columns) {
		if (name !== '_v') {
			colNames.push(name)
			paramNames.push(`:${name}`)
		}
		if (name !== 'id' && name !== '_v') {
			conflictClause.push(`${name}=if(excluded.${name}='', ${name}, excluded.${name})`)
		}
	}
	conflictClause.push('_v=_v+1')
	return `INSERT INTO ${table} (${colNames.join(', ')}) 
VALUES (${paramNames.join(', ')})
ON CONFLICT(id) DO UPDATE SET
${conflictClause.join(',\n')}
${
	returning
		? `RETURNING _v, ${columns
				.filter(({ type }) => type !== 'reference')
				.map(({ name, type }) => (type === 'json' ? `${name} -> '$' as "${name}"` : name))
				.join(', ')}`
		: ''
}`.trim()
}

export function buildSelect(table: string, columns: Column[]) {
	const { fields, joins } = buildSelectClauses(table, columns)
	return `SELECT ${fields.join(', ')} FROM ${table} ${joins.join(' ')}`
}

function buildSelectClauses(
	table: string,
	columns: Column[],
	results: { fields: string[]; joins: string[] } = { fields: [], joins: [] }
) {
	for (const column of columns) {
		if (column.type === 'reference') {
			const { table: refTable, columns: refColumns } = column.model
			results.joins.push(`LEFT JOIN ${refTable} ON ${refTable}.id = ${table}.${column.name}`)
			buildSelectClauses(refTable, refColumns, results)
		} else if (column.type === 'json') {
			results.fields.push(`${table}.${column.name} -> '$' as "${table}#${column.name}"`)
		} else {
			results.fields.push(`${table}.${column.name} as "${table}#${column.name}"`)
		}
	}
	return results
}

export function makeDeserializer<T>(
	{ table, columns }: { table: string; columns: Column[] },
	fullNames = false
) {
	return (input: Record<string, SQLOutputValue>, original?: Partial<T>) => {
		const model: Record<string, unknown> = {}
		for (const column of columns) {
			const fullName = fullNames ? `${table}#${column.name}` : column.name
			const { name, type } = column
			if (type === 'auto') {
				model[name] = input[fullName]
			} else if (type === 'date') {
				model[name] = input[fullName] ? new Date(input[fullName] as string) : null
			} else if (type === 'json') {
				try {
					model[name] = JSON.parse((input[fullName] || 'null') as string)
				} catch (err) {
					throw new Error(
						`failed to deserialize value "${input[fullName]}" for col ${fullName}: ${(err as Error).message}, ${JSON.stringify(input)}`
					)
				}
			} else if (type === 'reference') {
				const ref = input[`${column.model.table}#id`]
				model[column.model.table] = ref
					? makeDeserializer(column.model, true)(input)
					: ((original as Record<string, unknown> | undefined)?.[column.model.table] ?? null) // reuse original reference if any
			}
		}
		return model as unknown as T
	}
}

/**
 * Internal function intended to subclasses, to customize serialization.
 * Default implementation stringifies data to json columns.
 * Undefined values are converted to empty strings, so the upsert logic will reuse existing values,
 * while null values will be stored as NULL in database.
 * **Note** the returned object must not contain undefined values for columns
 * @returns a serialization function that takes model and returns database row
 */
export function makeSerializer<T>({ columns }: { table: string; columns: Column[] }) {
	return (model: Partial<T>) => {
		const saved = {} as Record<string, unknown>
		const input = model as Record<string, unknown>
		for (const column of columns) {
			const { name, type } = column
			// do not serialize _v since the UPSERT will handle it
			if (type === 'auto' && name !== '_v') {
				saved[name] = input[name] === null ? null : (input[name] ?? '')
			} else if (type === 'date') {
				saved[name] =
					input[name] === null ? null : ((input[name] as Date | undefined)?.getTime?.() ?? '')
			} else if (type === 'json') {
				saved[name] = input[name] === null ? null : (JSON.stringify(input[name]) ?? '')
			} else if (type === 'reference') {
				saved[name] =
					input[column.model.table] === null
						? null
						: ((input[column.model.table] as Record<string, unknown> | undefined)?.id ?? '')
			}
		}
		return saved as unknown as Record<string, SQLInputValue>
	}
}
