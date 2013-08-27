define [
  'angular'
  'service/storage'
  'controller/layout'
  'controller/list'
  'controller/planning'
  'controller/dancer'
  'model/dancer/dancer'
  'model/planning/planning'
  'model/initializer'
], (angular, StorageService, LayoutCtrl, ListCtrl, PlanningCtrl, DancerCtrl, DancerModel, PlanningModel, initializer) ->

  # declare main module that configures routing
  app = angular.module 'app', ['ui.bootstrap', 'ui.router', 'ui.state']

  app.config ['$locationProvider', '$urlRouterProvider', '$stateProvider', (location, router, states) ->
    location.html5Mode true
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
  ]

  # make storage an Angular service
  app.factory 'storage', ['$rootScope', (rootScope) ->
    # creates the instance
    storage = new StorageService()
    # bind models to storage provider
    DancerModel.bind storage
    PlanningModel.bind storage
    # init model
    initializer storage, (err, initialized) ->
      throw err if err?
      rootScope.$broadcast 'model-initialized' if initialized
    storage
  ]
  
  app