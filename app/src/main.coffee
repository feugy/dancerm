require('source-map-support').install({environment: 'node'})
{app, BrowserWindow} = require 'electron'
windowManager = require 'electron-window-manager'
{autoUpdater} = require 'electron-updater'
{parallel} = require 'async'
_ = require 'lodash'
{resolve} = require 'path'
{format} = require 'url'
{dumpError, fixConsole} = require '../script/util/common'

process.on 'uncaughtException', dumpError()
fixConsole()

createWindow = ->
  console.log "running DanceRM #{app.getVersion()} on electron #{process.versions.electron}"
  windowManager.init appBase: "file://#{__dirname}/../template", devMode: false

  # setup template for print windows, sized to A4 format, 3/4 height
  windowManager.templates.set 'print',
    width: 1000
    height: 800
    menu: null

  win = windowManager.createNew 'main', null, null, null,
    width: 1000
    height: 700
    resizable: true
    frame: false

  # true to hide it
  win.open '/app.html', true

  # splash window
  splash = new BrowserWindow
    width: 400
    height: 200
    center: true
    resizable: false
    frame: false
    alwaysOnTop: true
    parent: win.object
    modal: true
    backgroundColor: '#201b21'

  splash.loadURL format
    pathname: resolve __dirname, '..', 'template', 'splash.html'
    protocol: 'file:'
    slashes: true

  # automatic update
  _.delay =>
    autoUpdater.logger = console
    autoUpdater.on 'update-downloaded', (it) ->  win.object.webContents.send 'updates', it
    autoUpdater.checkForUpdates()
  , 5e3

app.on 'ready', createWindow

app.on 'window-all-closed', ->
  app.quit() if process.platform isnt 'darwin'
