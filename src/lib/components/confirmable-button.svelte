<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { HTMLButtonAttributes } from 'svelte/elements'

	interface ConfirmableButtonProps extends HTMLButtonAttributes {
		children?: Snippet
		heading: Snippet
		content: Snippet
		confirmAction: Snippet
		cancelAction: Snippet
	}

	const {
		class: className,
		heading,
		content,
		cancelAction,
		confirmAction,
		children,
		onclick,
		...props
	}: ConfirmableButtonProps = $props()

	let modal: HTMLDialogElement | null = null

	function open(event: Event) {
		event.preventDefault()
		modal?.showModal()
	}

	function confirm(event: MouseEvent & { currentTarget: HTMLButtonElement }) {
		modal?.close()
		onclick?.(event)
	}
</script>

<button class="btn {className}" onclick={open} {...props}>{@render children?.()}</button>
<dialog bind:this={modal} class="modal font-normal text-base">
  <div class="modal-box">
    <h3 class="text-lg font-bold">{@render heading()}</h3>
    <p class="py-4">{@render content()}</p>
    <div class="modal-action">
      <form method="dialog" class="contents">
        <button class="btn">{@render cancelAction()}</button>
        <button class="btn btn-primary" onclick={confirm}>{@render confirmAction()}</button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>close</button>
  </form>
</dialog>

