<script lang="ts">
	import '../app.css'
	const { children } = $props()
</script>

<div class="flex flex-col h-full">
  {@render children()}
</div>

