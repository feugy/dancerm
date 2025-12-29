<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { HTMLButtonAttributes } from 'svelte/elements'

	export interface ButtonProps extends HTMLButtonAttributes {
		children?: Snippet
	}

	const { class: className, children, title, ...props }: ButtonProps = $props()
</script>

{#snippet button()}
	<button class="btn {className}" {...props}>{@render children?.()}</button>
{/snippet}

{#if title}
	<div class="tooltip" data-tip={title}>{@render button()}</div>
{:else}
	{@render button()}
{/if}

