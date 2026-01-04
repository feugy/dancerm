<script lang="ts">
	import type { DanceClass } from '$lib/server/models'
	import { unsecureHash } from '$lib/utils/basics'
	import { parseTime } from '$lib/utils/models'

	const dayTitles = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche']
	const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
	const colors = new Map([
		['color1', 'btn-primary'],
		['color2', 'btn-secondary'],
		['color3', 'btn-accent'],
		['color4', 'btn-info'],
		['color5', 'btn-success'],
		['color6', 'btn-warning'],
		['color7', 'btn-error'],
		['color8', 'btn-secondary-content'],
		['color9', 'btn-accent-content'],
		['color10', 'btn-info-content'],
		['color11', 'btn-success-content'],
		['color12', 'btn-warning-content'],
		['color13', 'btn-error-content']
	])
	const dayCellClasses = 'px-2 py-0.5 text-center'
	const groupCellClasses = 'p-2 text-center'

	const {
		class: className,
		danceClasses,
		onSelect,
		groupBy = 'room',
		shrinkHours = true,
		hideEmptyDays = true
	}: {
		danceClasses: DanceClass[]
		groupBy?: keyof DanceClass
		shrinkHours?: boolean
		hideEmptyDays?: boolean
		class?: string
		onSelect?: (args: { danceClass: DanceClass }) => void
	} = $props()

	const state = $derived.by(() => {
		const legend = new Map<string, string>()
		const groupByDay = new Map<number, string[]>(Array.from({ length: 7 }, (_, i) => [i, []]))

		let earliest = 24
		let latest = 0
		for (const danceClass of danceClasses) {
			const { color, kind } = danceClass
			if (color && kind) {
				legend.set(color, kind)
			}
			const startTime = parseTime(danceClass.start)
			const endTime = parseTime(danceClass.end)
			if (!startTime || !endTime) continue

			earliest = Math.min(earliest, startTime.hour)
			latest = Math.max(latest, endTime.minutes ? endTime.hour + 1 : endTime.hour)
			const group = groupByDay.get(startTime.day) ?? []
			const grouped = danceClass[groupBy]?.toString() ?? ''
			if (!group.includes(grouped)) {
				group.push(grouped)
				groupByDay.set(startTime.day, group.sort())
			}
		}
		if (!shrinkHours) {
			earliest = 8
			latest = 22
		}

		const columns: { titleCol: string; title?: string; groups?: unknown[]; day: number }[] = [
			{ titleCol: '1', day: -1 }
		]
		const columnsDef = ['[time] 50px']
		let currentCol = 2
		let colCount = 1
		for (const [day, groups] of groupByDay) {
			if (groups.length) {
				columns.push({
					titleCol: `${currentCol} / span ${groups.length}`,
					title: dayTitles[day],
					day,
					groups
				})
				currentCol += groups.length
				colCount += groups.length
				columnsDef.push(...groups.map((group) => `[${dayNames[day]}_${unsecureHash(group)}] 1fr`))
			} else if (!hideEmptyDays) {
				columns.push({
					titleCol: `${currentCol}`,
					title: dayTitles[day],
					day,
					groups: ['']
				})
				currentCol++
				colCount++
				columnsDef.push('1fr')
			}
		}
		const rows: { def: string; time?: string }[] = []
		for (let hour = earliest; hour < latest; hour++) {
			for (const minute of ['00', '15', '30', '45']) {
				rows.push({ def: `[t${hour}_${minute}] 1fr`, time: `${hour}:${minute}` })
			}
		}
		return {
			rows,
			columns,
			rowsDef: rows.map(({ def }) => def).join(' '),
			columnsDef: columnsDef.join(' ')
		}
	})
</script>

<div class="grid relative grid-rows-(--rows) grid-cols-(--cols) {className}" 
      style:--cols={state.columnsDef}
      style:--rows="auto auto {state.rowsDef}">
  {#each danceClasses as danceClass}
    {@const day = danceClass.start?.split(' ')[0]}
    {@const timeStart = danceClass.start?.split(' ')[1]}
    {@const timeEnd = danceClass.end?.split(' ')[1]}
    {#if day && timeStart && timeEnd && danceClass.room}
			<div class="tooltip absolute inset-0 m-0.5 " 
						style:grid-row={`t${timeStart.replace(':', '_')} / t${timeEnd.replace(':', '_')}`}
						style:grid-column={`${day}_${unsecureHash(danceClass.room)} / span 1`}>
				<button class="btn {colors.get(danceClass.color ?? 'color1')} p-2 h-full w-full"
					onclick={() => onSelect?.({ danceClass })}>{danceClass.level}</button> 
				<div class="tooltip-content flex flex-col gap-2 p-3">
					<span>{danceClass.kind} {danceClass.level}</span>
					<span>{timeStart} ~ {timeEnd}</span>
				</div>
			</div>
    {/if}
  {/each}
  {#each state.columns as {titleCol, title}}
    <span class="{dayCellClasses} col-(--col)" 
          style:--col={titleCol}>{title}</span>
  {/each}
  {#each state.columns as {groups}, col}
    {#if groups}
      {#each groups as group, groupRank}
        <span class="border-current {groupCellClasses}" class:border-l={groupRank === 0 && col > 1}>{group}</span>
      {/each}
    {:else}
      <span class={groupCellClasses}></span> 
    {/if}
  {/each}
  {#each state.rows as { time }, row}
    {@const oClock = row%4 === 0}
    {@const halfHour = row%4 === 2}
    {#each state.columns as {day, groups}, col}
      {#if groups}
        {#each groups as group, groupRank}
          <span class="border-current" 
                class:border-l={groupRank === 0 && col > 1}
                class:border-t={oClock || halfHour}
                style:border-top-style={halfHour ? 'dashed' : 'solid'}
                data-group={group} 
                data-time="{dayNames[day]} {time}"></span>
        {/each}
      {:else if oClock}
        <span class="border-t border-current text-right row-span-2">{time}</span> 
      {:else if halfHour}
        <span class="border-t border-current border-dashed row-span-2">&nbsp;</span> 
      {/if}
    {/each}
  {/each}
</div>