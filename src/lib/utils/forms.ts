export function dateToDateInput(date?: Date | null) {
	return (date?.toISOString() ?? '').slice(0, 10)
}
