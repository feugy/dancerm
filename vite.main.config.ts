import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vite'

// https://vitejs.dev/config
export default defineConfig({
	build: {
		outDir: '.vite',
		rollupOptions: {
			// Exclude sveltekit build output from vite bundling so it could be loaded at runtime
			external: ['build/index.js'].map((src) => fileURLToPath(new URL(src, import.meta.url)))
		},
		lib: {
			formats: ['es'],
			entry: 'src/electron-main.ts',
			fileName: 'main'
		}
	}
})
