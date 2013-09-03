# merge underscore and underscore string functions
_ = require 'underscore'
_str = require 'underscore.string'
_.mixin _str.exports()

StorageService = require '../script/service/storage'
ExportService = require '../script/service/export'
ImportService = require '../script/service/import'
LayoutCtrl = require '../script/controller/layout'
ListCtrl = require '../script/controller/list'
ExpandedListCtrl = require '../script/controller/expandedlist'
PlanningCtrl = require '../script/controller/planning'
DancerCtrl = require '../script/controller/dancer'
DancerModel = require '../script/model/dancer/dancer'
PlanningModel = require '../script/model/planning/planning'
initializer = require '../script/model/initializer'

# declare main module that configures routing
app = angular.module 'app', ['ui.bootstrap', 'ui.router']

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

# make storage an Angular service
app.factory 'storage', ['$rootScope', (rootScope) ->
  # creates the instance
  storage = new StorageService()
  # bind models to storage provider
  DancerModel.bind storage
  PlanningModel.bind storage
  # for debug purposes
  window.storage = storage
  window.Dancer = DancerModel
  window.Planning = PlanningModel
  # init model
  initializer (err, initialized) ->
    throw err if err?
    rootScope.$broadcast 'model-initialized'
  storage
]

# make export an Angular service
app.service 'export', ExportService
app.service 'import', ImportService

module.exports = app