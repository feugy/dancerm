'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'

# make some variable globals for other scripts
global.gui = gui
global.$ = $
global.angular = angular
global.localStorage = localStorage

# 'win' is Node-Webkit's window
# 'window' is DOM's window
win = gui.Window.get()
isMaximized = false

# stores in local storage application state
win.on 'close', ->
  console.log 'close !'
  for attr in ['x', 'y', 'width', 'height']
    localStorage.setItem attr, win[attr]

  localStorage.setItem 'maximized', isMaximized
  @close true

win.on 'maximize', -> console.log('maximized'); isMaximized = true
win.on 'unmaximize', -> isMaximized = false
win.on 'minimize', -> isMaximized = false

# DOM is ready
win.once 'loaded', ->
  # set application title
  window.document?.title = i18n.ttl.application

  $(window).on 'keyup', (event) ->
    # opens dev tools on F12 or Command+Option+J
    win.showDevTools() if event.which is 123 or event.witch is 74 and event.metaKey and event.altKey
      
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
  require '../script/directive/planning'
  require '../script/directive/payment'
  require '../script/directive/tags'
  require '../script/directive/registration'

  # starts the application from a separate file to allow circular dependencies to application
  angular.bootstrap $('body'), ['app']