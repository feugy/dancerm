import { app, BrowserWindow } from 'electron'
import started from 'electron-squirrel-startup'

if (started) {
	// squirrel shortcuts for Windows installing/uninstalling.
	app.quit()
}

const createWindow = async () => {
	const mainWindow = new BrowserWindow({
		width: 800,
		height: 600
	})

	const url = MAIN_WINDOW_VITE_DEV_SERVER_URL || `http://localhost:3000`
	if (!MAIN_WINDOW_VITE_DEV_SERVER_URL) {
		// in production, start the sveltekit built server
		await import('../build/index.js')
	} else {
		mainWindow.webContents.on('did-frame-finish-load', () => {
			mainWindow.webContents.openDevTools({ mode: 'detach' })
		})
	}
	mainWindow.loadURL(url)
}

app.on('ready', createWindow)

app.on('window-all-closed', () => {
	if (process.platform !== 'darwin') {
		app.quit()
	}
})

app.on('activate', () => {
	if (BrowserWindow.getAllWindows().length === 0) {
		createWindow()
	}
})
