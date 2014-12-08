# merge lodash and lodash string functions
_ = require 'lodash'
_str = require 'underscore.string'
_.mixin _str.exports()

i18n = require '../script/labels/common'
ExportService = require '../script/service/export'
ImportService = require '../script/service/import'
DialogService = require '../script/service/dialog'
CardListService = require '../script/service/cardlist'

###LayoutCtrl = require '../script/controller/layout'
ListCtrl = require '../script/controller/list'###
StatsCtrl = require '../script/controller/stats'
ListLayoutCtrl = require '../script/controller/listlayout'
CardCtrl = require '../script/controller/card'
PlanningCtrl = require '../script/controller/planning'
ExpandedListCtrl = require '../script/controller/expandedlist'

console.log "running with angular v#{angular.version.full}"

# declare main module that configures routing
app = angular.module 'app', ['ngAnimate', 'ui.bootstrap', 'ui.router', 'tc.chartjs']

app.config ['$locationProvider', '$urlRouterProvider', '$stateProvider', (location, router, states) ->
  # html5 mode raise problems when loading templates
  location.html5Mode false 
  # configure routing
  router.otherwise '/list/planning'

  states.state 'list', _.extend {url: '/list', abstract:true}, ListLayoutCtrl.declaration
  states.state 'stats', _.extend {url: '/stats'}, StatsCtrl.declaration
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
app.run ['dialog', (dialog) ->
  chooseDumpLocation = ->
    dumpDialog = $('<input style="display:none;" type="file" nwsaveas value="dump_dancerm.json" accept="application/json"/>')
    dumpDialog.change (evt) =>
      dumpPath = dumpDialog.val()
      dumpDialog.remove()
      # dialog cancellation
      return askDumpLocation() unless dumpPath
      # retain entry for next loading
      localStorage.setItem 'dumpPath', dumpPath
    dumpDialog.trigger 'click'

  askDumpLocation = ->
    # first, explain what we're asking, then display file selection, wether the user accepted or not
    dialog.messageBox(i18n.ttl.dump, i18n.msg.dumpData, [label: i18n.btn.ok]).result.then(chooseDumpLocation).catch chooseDumpLocation

  # nothing in localStorage
  dumpPath = localStorage.getItem 'dumpPath'
  askDumpLocation() unless dumpPath
]

# on close, dump data, with a waiting dialog message
# @param done [Function] completion callback invoked with optionnal error argument
app.close = (done) ->
  $injector = angular.element('body.app').injector()
  # display waigin message
  $injector.get('$rootScope').$apply =>
    $injector.get('dialog').messageBox i18n.ttl.dump, i18n.msg.dumping
  # export data
  $injector.get('export').dump localStorage.getItem('dumpPath'), done

module.exports = app