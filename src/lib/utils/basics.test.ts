import { describe, expect, it } from 'vitest'
import { unsecureHash } from './basics'

describe('basics utilities', () => {
	describe('unsecureHash()', () => {
		it.each([
			['hello', 99162322],
			['world', 113318802],
			['test', 3556498],
			['', 0],
			['a', 97],
			['Hello', 69609650],
			['HELLO', 68624562]
		])('can hash "%s" to %i', (input, expected) => {
			expect(unsecureHash(input)).toBe(expected)
		})

		it.each([
			['hello world', 'hello world'],
			['test123', 'test123'],
			['same string', 'same string'],
			['unicode: 🎉', 'unicode: 🎉'],
			['special chars: !@#$%^&*()', 'special chars: !@#$%^&*()']
		])('produces consistent hash for same input: "%s"', (input1, input2) => {
			expect(unsecureHash(input1)).toBe(unsecureHash(input2))
		})

		it.each([
			['hello', 'world'],
			['test', 'TEST'],
			['', 'space'],
			[' leading space', 'leading space'],
			['trailing space ', 'trailing space']
		])('produces different hashes for different inputs: "%s" vs "%s"', (input1, input2) => {
			expect(unsecureHash(input1)).not.toBe(unsecureHash(input2))
		})
	})
})
