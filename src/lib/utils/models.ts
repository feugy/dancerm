export function isNew<T extends { _v?: number }>(model?: T | null) {
	return (model?._v ?? -1) === 0
}

// ordered week days
const dayValue = new Map([
	['mon', 0],
	['tue', 1],
	['wed', 2],
	['thu', 3],
	['fri', 4],
	['sat', 5],
	['sun', 6]
])

export function parseTime(timeString?: string | null) {
	if (!timeString) return null
	const [dayName, time] = timeString.split(' ')
	const day = dayValue.get(dayName.toLowerCase()) ?? -1
	const [hour, minutes] = time.split(':').map(Number)
	return { day, dayName, hour, minutes }
}
