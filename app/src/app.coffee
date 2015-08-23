# merge lodash and lodash string functions
_ = require 'lodash'
_.mixin require('underscore.string').exports()

i18n = require '../script/labels/common'
ExportService = require '../script/service/export'
ImportService = require '../script/service/import'
DialogService = require '../script/service/dialog'
CardListService = require '../script/service/card_list'

StatsCtrl = require '../script/controller/stats'
SettingsCtrl = require '../script/controller/settings'
ListLayoutCtrl = require '../script/controller/list_layout'
CardCtrl = require '../script/controller/card'
PlanningCtrl = require '../script/controller/planning'
ExpandedListCtrl = require '../script/controller/expanded_list'

console.log "running with angular v#{angular.version.full}"

# declare main module that configures routing
app = angular.module 'app', ['ngAnimate', 'ui.bootstrap', 'ui.router', 'nvd3']

app.config ['$locationProvider', '$urlRouterProvider', '$stateProvider', (location, router, states) ->
  # html5 mode raise problems when loading templates
  location.html5Mode false
  # configure routing
  router.otherwise '/list/planning'

  states.state 'list', _.extend {url: '/list', abstract:true}, ListLayoutCtrl.declaration
  states.state 'stats', _.extend {url: '/stats'}, StatsCtrl.declaration
  states.state 'settings', _.extend {url: '/settings'}, SettingsCtrl.declaration
  states.state 'detailed', _.extend {url: '/detailed-list'}, ExpandedListCtrl.declaration

  states.state 'list.card',
    url: '/card/:id'
    views:
      main: CardCtrl.declaration

  states.state 'list.planning',
    url: '/planning'
    views:
      main: PlanningCtrl.declaration
]

# make export an Angular service
app.service 'export', ExportService
app.service 'import', ImportService
app.service 'dialog', DialogService
app.service 'cardList', CardListService

# at startup, check that dump path is defined
app.run ['$location', (location) ->
  location.url('/settings?firstRun').replace() unless localStorage.dumpPath?
]

# on close, dump data, with a waiting dialog message
# @param done [Function] completion callback invoked with optionnal error argument
app.close = (done) ->
  injector = angular.element('body.app').injector()
  # display waigin message
  injector.get('$rootScope').$apply =>
    injector.get('dialog').messageBox i18n.ttl.dumping, i18n.msg.dumping
  # export data
  injector.get('export').dump localStorage.dumpPath, done

module.exports = app