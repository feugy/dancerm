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
DancerCtrl = require '../script/controller/dancer'
DancerModel = require '../script/model/dancer/dancer'
PlanningModel = require '../script/model/planning/planning'
initializer = require '../script/model/initializer'

console.log "running with angular v#{angular.version.full}"

# declare main module that configures routing
app = angular.module 'app', ['ngAnimate', 'ui.bootstrap', 'ui.router']

app.config ['$locationProvider', '$urlRouterProvider', '$stateProvider', (location, router, states) ->
  location.html5Mode false
  # configure routing
  router.otherwise '/home'

  home = 
    url: '/home'
    abstract: true
    templateUrl: 'columnandmain.html'
    controller: LayoutCtrl
  states.state 'home', home

  states.state 'list-and-planning',
    parent: home
    url: ''
    views: 
      column:
        templateUrl: 'list.html'
        controller: ListCtrl
      main:
        templateUrl: 'planning.html'
        controller: PlanningCtrl

  states.state 'list-and-dancer',
    parent: home
    url: '/dancer/:id'
    views: 
      column:
        templateUrl: 'list.html'
        controller: ListCtrl
      main:
        templateUrl: 'dancer.html'
        controller: DancerCtrl

  states.state 'expanded-list',
    parent: home
    url: '/list'
    views: 
      column:
        templateUrl: 'expandedlist.html'
        controller: ExpandedListCtrl
]

# application initialization
app.run ['$rootScope', (rootScope) ->
  # init model
  initializer (err, initialized) ->
    throw err if err?
    rootScope.$broadcast 'model-initialized'
]

# make export an Angular service
app.service 'export', ExportService
app.service 'import', ImportService
app.service 'dialog', DialogService

#on close, dump data, with a waiting dialog message
app.close = (callback) ->
  $injector = angular.element('body').injector()
  # display waigin message
  $injector.get('$rootScope').$apply =>
    $injector.get('dialog').messageBox i18n.ttl.dump, i18n.msg.dumping
  # export data
  $injector.get('export').dump localStorage.getItem('dumpPath'), callback

module.exports = app