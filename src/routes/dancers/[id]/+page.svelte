<script lang="ts">
  import type { PageData } from "./$types";

  let { data }: { data: PageData } = $props();
</script>

<a href="/" class="text-blue-500 hover:underline mb-4 inline-block">Back</a>

<h1 class="text-lg font-bold">
  {data.dancer?.firstname}
  {data.dancer?.lastname}
</h1>
