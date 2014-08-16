'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'

console.log "running on node-webkit v#{process.versions['node-webkit']}"

# make some variable globals for other scripts
global.gui = gui
global.$ = $
global.angular = angular
global.localStorage = localStorage

# 'win' is Node-Webkit's window
# 'window' is DOM's window
win = gui.Window.get()
isMaximized = false
hasDump = false

# stores in local storage application state
win.on 'close', ->
  return @close true if hasDump

  hasDump = true
  global.app.close (err) =>
    console.error err if err?
    console.log 'close after save'
    @close true

  console.log 'ask to close...'
  for attr in ['x', 'y', 'width', 'height']
    localStorage.setItem attr, win[attr]

  localStorage.setItem 'maximized', isMaximized

win.on 'maximize', -> console.log('maximized'); isMaximized = true
win.on 'unmaximize', -> isMaximized = false
win.on 'minimize', -> isMaximized = false


$(win.window).on 'keyup', (event) ->
  # opens dev tools on F12 or Command+Option+J
  win.showDevTools() if event.which is 123 or event.witch is 74 and event.metaKey and event.altKey
  # reloads full app on Ctrl+F5
  if event.which is 116 and event.ctrlKey
    # must clear require cache also
    delete global.require.cache[attr] for attr of global.require.cache
    win.reloadIgnoringCache() 

# DOM is ready
$(win.window).on 'load', ->
  # set application title
  window.document?.title = i18n.ttl.application

  # restore from local storage application state if possible
  if localStorage.getItem 'x'
    x = Number localStorage.getItem 'x'
    y = Number localStorage.getItem 'y'
    win.moveTo x, y
  if localStorage.getItem 'width'
    width = Number localStorage.getItem 'width'
    height = Number localStorage.getItem 'height'
    win.resizeTo width, height
  else
    infos = require '../../package.json'
    win.resizeTo infos.window.min_width, infos.window.min_height,

  # we are ready: shows it !
  win.show()
  # local storage stores strings !
  win.maximize() if 'true' is localStorage.getItem 'maximized'

  global.app = require '../script/app'
  # require directives and filters immediately to allow circular dependencies
  require '../script/util/filters'
  require '../script/directive/address'
  require '../script/directive/dancer'
  require '../script/directive/number_only'
  require '../script/directive/planning'
  require '../script/directive/payment'
  require '../script/directive/tags'
  require '../script/directive/registration'

  # starts the application from a separate file to allow circular dependencies to application
  angular.bootstrap $('body'), ['app']
