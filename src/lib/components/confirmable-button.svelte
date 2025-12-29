<script lang="ts">
	import type { Snippet } from 'svelte'
	import type { ButtonProps } from '$lib/components/button.svelte'
	import Button from '$lib/components/button.svelte'

	interface ConfirmableButtonProps extends ButtonProps {
		heading: Snippet
		content: Snippet
		confirmAction: Snippet
		cancelAction: Snippet
	}

	const {
		heading,
		content,
		cancelAction,
		confirmAction,
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

<Button onclick={open} {...props}/>
<dialog bind:this={modal} class="modal font-normal text-base">
  <div class="modal-box">
    <h3 class="text-lg font-bold">{@render heading()}</h3>
    <p class="py-4">{@render content()}</p>
    <div class="modal-action">
      <form method="dialog" class="contents">
        <Button>{@render cancelAction()}</Button>
        <Button class="btn-primary" onclick={confirm}>{@render confirmAction()}</Button>
      </form>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop">
    <button>close</button>
  </form>
</dialog>

