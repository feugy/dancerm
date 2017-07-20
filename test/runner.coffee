{Application} = require 'spectron'
electron = require 'electron'
assert = require 'power-assert'
lab = require 'lab'

exports.lab = lab.script()
{describe, it, before, after} = exports.lab

describe.skip 'given a started application', ->

  app = new Application
    path: electron,
    args: ['.'],
    env:
      RUNNING_IN_SPECTRON: true

  before -> app.start().then ->
    app.client.waitForExist '.app-menu'

  after -> app.stop()

  it 'should load dump file', ->
    paths = ['C:/Users/user/Desktop/']
    app.mainProcess.on 'loaded', ->
      console.log '>>> loaded !!'

    app.mainProcess.on 'mock.showOpenDialog', (opts) ->
      console.log ">> coucou !!", opts
      app.mainProcess.send 'mock.showOpenDialog.cb', paths

    app.client.click '.nav-link > .settings'
      .then -> app.client.waitForExist '.data-load'
      .then -> app.client.click '.data-load'
      .then -> app.client.getMainProcessLogs()
      .then (logs) -> console.log '>> main\n\n', logs
      .then -> new Promise (res) ->
        setTimeout ->
          res()
        , 1e3
