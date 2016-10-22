require('source-map-support').install({environment: 'node'})
{app, BrowserWindow} = require 'electron'
{parallel} = require 'async'
{dumpError, fixConsole} = require '../script/util/common'

win = null

process.on 'uncaughtException', dumpError()
fixConsole()

createWindow = ->
  console.log "running DanceRM #{app.getVersion()} on electron #{process.versions.electron}"

  win = new BrowserWindow
    width: 1000
    height: 700
    show: false
    frame: false

  win.loadURL "file://#{__dirname}/../template/app.html"

  win.on 'closed', =>
    # dereference the window object, to destroy it
    win = null

app.on 'ready', createWindow

app.on 'window-all-closed', ->
  app.quit() if process.platform isnt 'darwin'

app.on 'activate', ->
  createWindow() unless win?
