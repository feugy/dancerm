define [
  'angular'
  'service/storage'
  'controller/home'
  'controller/dancer'
  'model/dancer/dancer'
  'model/planning/planning'
], (angular, StorageService, HomeCtrl, DancerCtrl, DancerModel, PlanningModel) ->

  # declare main module that configures routing
  app = angular.module 'app', ['ui.bootstrap']
  app.config ['$locationProvider', '$routeProvider', (location, route) ->
    # use push state
    location.html5Mode true
    # configure routing
    route.when "/home",
      name: 'home'
      templateUrl: 'home.html'
      controller: HomeCtrl
    route.when "/dancer",
      name: 'dancer'
      templateUrl: 'dancer.html'
      controller: DancerCtrl
    route.otherwise 
      redirectTo: "/dancer"
  ]

  # make storage an Angular service
  app.factory 'storage', ->
    # creates the instance
    storage = new StorageService()
    # bind models to storage provider
    DancerModel.bind storage
    PlanningModel.bind storage
    storage
  
  app