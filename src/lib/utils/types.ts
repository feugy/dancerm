import v from '@vinejs/vine'
import type { Infer } from '@vinejs/vine/types'

/** Database column definition with types. */
export type Column =
	| {
			name: string
			/* use 'auto' to keep SQLite type affinity, 'date' for ISO string <-> Date, 'json' for JSON string <-> object */
			type: 'auto' | 'date' | 'json'
	  }
	| {
			name: string
			/* use 'reference' for foreign key reference to another table */
			type: 'reference'
			model: { table: string; columns: Column[] }
	  }

/** A page of list results. */
export interface Page<T> {
	/** Total number of models. */
	total: number
	/** 0-based rank of the first model returned. */
	size: number
	/** Maximum number of models per page. */
	from: number
	/** Sorting criteria used: direction (+ or -) then property (name, rank...). */
	sort: string
	/** Returned models. */
	results: T[]
}

/** A page of list results. */
export interface Page<T> {
	/** Total number of models. */
	total: number
	/** 0-based rank of the first model returned. */
	size: number
	/** Maximum number of models per page. */
	from: number
	/** Sorting criteria used: direction (+ or -) then property (name, rank...). */
	sort: string
	/** Returned models. */
	results: T[]
}

export const dbConfSchema = v.object({
	filename: v.string()
})

/** Represents a configuration object to connect to database. */
export type DBConf = Infer<typeof dbConfSchema>

/**
 * Utility type for creating making all fields of a type optional, except the ones listed as required.
 * The hidden child of Partial<> and Pick<>
 * @example: Partial<{ id: string, name: string | null, age: number }, 'id' | 'name'> -> { id: string, name: string | null, age?: number }
 */
export type PartialWithReq<Type, Key extends keyof Type> = Partial<Type> & {
	[P in Key]-?: Type[P]
}
