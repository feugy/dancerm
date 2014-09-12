# merge underscore and underscore string functions
_ = require 'underscore'
_str = require 'underscore.string'
_.mixin _str.exports()

i18n = require '../script/labels/common'
ExportService = require '../script/service/export'
ImportService = require '../script/service/import'
DialogService = require '../script/service/dialog'
LayoutCtrl = require '../script/controller/layout'
ListCtrl = require '../script/controller/list'
ExpandedListCtrl = require '../script/controller/expandedlist'
PlanningCtrl = require '../script/controller/planning'
CardCtrl = require '../script/controller/card'
StatsCtrl = require '../script/controller/stats'
initializer = require '../script/model/tools/initializer'

console.log "running with angular v#{angular.version.full}"

# declare main module that configures routing
app = angular.module 'app', ['ngAnimate', 'ui.bootstrap', 'ui.router', 'nvd3']

app.config ['$locationProvider', '$urlRouterProvider', '$stateProvider', (location, router, states) ->
  location.html5Mode false
  # configure routing
  router.otherwise '/home'

  home = _.extend {}, LayoutCtrl.declaration, url: '/home'

  states.state 'home', home

  states.state 'list-and-planning',
    parent: home
    url: ''
    views: 
      column: ListCtrl.declaration
      main: PlanningCtrl.declaration

  states.state 'list-and-card',
    parent: home
    url: '/card/:id'
    views: 
      column: ListCtrl.declaration
      main: CardCtrl.declaration

  states.state 'expanded-list',
    parent: home
    url: '/list'
    views: 
      column: ExpandedListCtrl.declaration

  states.state 'stats',
    parent: home
    url: '/stats'
    views: 
      column: StatsCtrl.declaration
]

# application initialization
app.run ['$rootScope', (rootScope) ->
  # init model
  initializer().then -> 
    console.log "broadcast"
    rootScope.$broadcast 'model-initialized'
]

# make export an Angular service
app.service 'export', ExportService
app.service 'import', ImportService
app.service 'dialog', DialogService

# on close, dump data, with a waiting dialog message
# @returns the dump promise
app.close = () ->
  $injector = angular.element('body').injector()
  # display waigin message
  $injector.get('$rootScope').$apply =>
    $injector.get('dialog').messageBox i18n.ttl.dump, i18n.msg.dumping
  # export data
  $injector.get('export').dump localStorage.getItem 'dumpPath'

module.exports = app