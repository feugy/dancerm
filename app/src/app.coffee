_ = require 'lodash'
{remote, ipcRenderer} = require 'electron'
windowManager = remote.require 'electron-window-manager'
require('moment').locale 'fr'
{dumpError, buildStyles, getColorsFromTheme, fixConsole} = require '../script/util/common'
{init} = require '../script/model/tools/initializer'
i18n = require '../script/labels/common'

process.on 'uncaughtException', dumpError()
fixConsole()

win = windowManager.get 'main'
hasDump = false

console.log "running with angular #{angular.version.full}"

# declare main module that configures routing
app = angular.module 'app', ['ngAnimate', 'ngSanitize', 'ui.bootstrap', 'ui.router', 'nvd3', 'monospaced.elastic']

app.config ['$locationProvider', '$urlRouterProvider', '$stateProvider', '$compileProvider', (location, router, states, compile) ->
  # html5 mode cause problems when loading templates
  location.html5Mode false
  # configure routing
  router.otherwise '/list/planning'

  states.state 'list', _.extend {url: '/list', abstract:true}, require('../script/controller/list_layout').declaration
  states.state 'stats', _.extend {url: '/stats'}, require('../script/controller/stats').declaration
  states.state 'settings', _.extend {url: '/settings'}, require('../script/controller/settings').declaration
  states.state 'detailed', _.extend {url: '/detailed-list'}, require('../script/controller/expanded_list').declaration
  states.state 'lessons', _.extend {url: '/lessons/:id'}, require('../script/controller/lessons').declaration

  states.state 'list.card',
    url: '/card/:id'
    views:
      main: require('../script/controller/card').declaration

  states.state 'list.planning',
    url: '/planning'
    views:
      main: require('../script/controller/planning').declaration

  states.state 'list.invoice',
    url: '/invoice'
    params:
      invoice: null
    views:
      main: require('../script/controller/invoice').declaration

  # adds chrome-extension to whitelist to allow loading relative path to images/links
  compile.imgSrcSanitizationWhitelist /^\s*((https?|ftp|file|blob|chrome-extension):|data:image\/)/
  compile.aHrefSanitizationWhitelist /^\s*(https?|ftp|mailto|tel|file:chrome-extension):/
]

# make export an Angular service
app.service 'conf', require '../script/service/conf'
app.service 'export', require '../script/service/export'
app.service 'import', require '../script/service/import'
app.service 'dialog', require '../script/service/dialog'
app.service 'cardList', require '../script/service/card_list'
app.service 'invoiceList', require '../script/service/invoice_list'
app.service 'lessonList', require '../script/service/lesson_list'

# require directives and filters immediately to allow circular dependencies
require('../script/util/filters')(app)
require('../script/directive/address')(app)
require('../script/directive/app_menu')(app)
require('../script/directive/dancer')(app)
require('../script/directive/filtered_input')(app)
require('../script/directive/invoice_item')(app)
require('../script/directive/layout')(app)
require('../script/directive/lesson_list')(app)
require('../script/directive/list')(app)
require('../script/directive/planning')(app)
require('../script/directive/payment')(app)
require('../script/directive/tags')(app)
require('../script/directive/registration')(app)

# at startup, check that dump path is defined
app.run ['$location', 'conf', (location, conf) ->
  conf.load () ->
    location.url('/settings?firstRun').replace() unless conf.dumpPath? and conf.teachers.length
]

# store current window's position and state in local storage
storePosition = ->
  bounds = win.object.getBounds()
  localStorage.setItem attr, bounds[attr] for attr of bounds
  localStorage.setItem 'maximized', win.object.isMaximized()

# build styles
buildStyles ['dancerm', 'print'], localStorage.getItem('theme') or 'none', (err, styles) ->
  # DOM is ready
  throw err if err?

  $('head').append "<style type='text/css' data-theme>#{styles['dancerm']}</style>"
  # make sheets global for others windows
  global.styles = styles

  # set application title
  window.document?.title = i18n.ttl.application

  # save before close
  $(window).on 'beforeunload', (evt) ->
    unless hasDump
      # cancel close and perform dump
      evt.preventDefault()
      console.log 'ask to close...'
      hasDump = true

      injector = angular.element('body.app').injector()
      # display waiting message
      injector.invoke ['dialog', (dialog) =>
        dialog.messageBox i18n.ttl.dumping, i18n.msg.dumping
      ]

      dumpPath = injector.get('conf').dumpPath
      # export data
      injector.get('export').dump dumpPath, (err) =>
        if err?
          console.error 'close after save error', err
        else
          console.log 'close after save'
        win.close()
      return false

    # stores in local storage application state
    console.log 'close !'
    storePosition()

  # reload full windows
  win.registerShortcut 'F5', ->
    storePosition()
    # must clear require cache also
    delete global.require.cache[attr] for attr of global.require.cache
    global.reload = true
    $(window).off 'beforeunload'
    windowManager.shortcuts.unregisterAll win.object
    win.reload true

  # toggle dev tools
  win.registerShortcut 'CommandOrControl+F12', -> win.toggleDevTools true

  # show updates notification from Main process
  ipcRenderer.on 'updates', (event, update) =>
    injector = angular.element('body.app').injector()
    # display modal message for updates
    injector.invoke ['dialog', '$filter', (dialog, filter) =>
      dialog.messageBox(i18n.ttl.updateInstalled, filter('i18n')('msg.updateInstalled', args: update), [
          {label: @i18n.btn.no}
          {label: @i18n.btn.yes, cssClass: 'btn-warning', result: true}
        ]
      ).result.then (confirmed) =>
        return unless confirmed
        # if confirmed, restart everything
        remote.app.relaunch()
        remote.app.exit 0
    ]

  console.log 'init database...'
  init (err) ->
    if err?
      dumpError err
      console.error err
      # close all windows without dumping data
      hasDump = true
      return win.close()
    console.log 'database initialized !'

    # restore from local storage application state if possible
    if localStorage.getItem 'x'
      x = +localStorage.getItem 'x'
      y = +localStorage.getItem 'y'
      win.move x, y
    if localStorage.getItem 'width'
      width = +localStorage.getItem 'width'
      height = +localStorage.getItem 'height'
      win.resize width, height

    # starts the application
    getColorsFromTheme()
    angular.bootstrap $('body.app'), ['app']

    # we are ready: shows it !
    win.object.show()
    # local storage stores strings !
    if 'true' is localStorage.getItem 'maximized'
      _.defer => win.maximize()

    # close splash screen
    win.object.getChildWindows()[0]?.close()
