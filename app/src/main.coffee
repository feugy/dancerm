require('source-map-support').install({environment: 'node'})
{app, BrowserWindow} = require 'electron'
windowManager = require 'electron-window-manager'
{autoUpdater} = require 'electron-updater'
{parallel} = require 'async'
_ = require 'lodash'
{dumpError, fixConsole} = require '../script/util/common'

process.on 'uncaughtException', dumpError()
fixConsole()

createWindow = ->
  require('../../test/mock') require 'electron' if process.env.RUNNING_IN_SPECTRON

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

  # automatic update
  _.delay =>
    autoUpdater.logger = console
    autoUpdater.on 'update-downloaded', (it) ->  win.object.webContents.send 'updates', it
    autoUpdater.checkForUpdates()
  , 5e3

app.on 'ready', createWindow

app.on 'window-all-closed', ->
  app.quit() if process.platform isnt 'darwin'
