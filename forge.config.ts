import { FuseV1Options, FuseVersion } from '@electron/fuses'
import { MakerZIP } from '@electron-forge/maker-zip'
import { FusesPlugin } from '@electron-forge/plugin-fuses'
import { VitePlugin } from '@electron-forge/plugin-vite'
import type { ForgeConfig } from '@electron-forge/shared-types'

const config: ForgeConfig = {
	packagerConfig: {
		asar: true,
		ignore: (path) =>
			!(
				path === '' ||
				path === '/package.json' ||
				path.startsWith('/build') ||
				path.startsWith('/.vite')
			)
	},
	rebuildConfig: {},
	makers: [new MakerZIP({}, ['linux'])],
	plugins: [
		new VitePlugin({
			build: [
				{
					entry: 'electron/main.ts',
					config: 'vite.main.config.ts',
					target: 'main'
				}
			],
			renderer: [
				{
					name: 'main_window',
					config: 'vite.config.ts'
				}
			]
		}),
		// Fuses are used to enable/disable various Electron functionality
		// at package time, before code signing the application
		new FusesPlugin({
			version: FuseVersion.V1,
			[FuseV1Options.RunAsNode]: false,
			[FuseV1Options.EnableCookieEncryption]: true,
			[FuseV1Options.EnableNodeOptionsEnvironmentVariable]: false,
			[FuseV1Options.EnableNodeCliInspectArguments]: false,
			[FuseV1Options.EnableEmbeddedAsarIntegrityValidation]: true,
			[FuseV1Options.OnlyLoadAppFromAsar]: true
		})
	]
}

export default config
