export function isNew<T extends { _v?: number }>(model?: T | null) {
	return (model?._v ?? -1) === 0
}
