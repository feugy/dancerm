import { describe, expect, it } from 'vitest'
import { dateToDateInput } from './forms'

describe('forms utilities', () => {
	describe('dateToDateInput()', () => {
		it.each([
			{
				title: 'converts a valid Date to ISO date string format',
				input: new Date('2023-12-25T14:30:00.000Z'),
				expected: '2023-12-25'
			},
			{
				title: 'handles date with time components correctly',
				input: new Date('2023-01-15T23:59:59.999Z'),
				expected: '2023-01-15'
			},
			{
				title: 'handles leap year dates correctly',
				input: new Date('2024-02-29T12:00:00.000Z'),
				expected: '2024-02-29'
			},
			{
				title: 'handles very old dates',
				input: new Date('1900-01-01T00:00:00.000Z'),
				expected: '1900-01-01'
			},
			{
				title: 'handles future dates',
				input: new Date('2099-12-31T12:00:00.000Z'),
				expected: '2099-12-31'
			}
		])('$title', ({ input, expected }) => {
			expect(dateToDateInput(input)).toBe(expected)
		})

		it.each([
			{
				title: 'is null',
				input: null
			},
			{
				title: 'is undefined',
				input: undefined
			}
		])('returns empty string when date $title', ({ input }) => {
			expect(dateToDateInput(input)).toBe('')
		})
	})
})
