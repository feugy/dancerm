export function unsecureHash(value: string) {
	// Paul Hsieh's SuperFastHash
	let hash = 0
	for (let i = 0; i < value.length; i++) {
		const chr = value.charCodeAt(i)
		hash = (hash << 5) - hash + chr
		hash |= 0
	}
	return hash >>> 0
}
