define [
  'angular'
  'service/storage'
  'controller/home'
  'controller/dancer'
  'model/dancer/dancer'
  'model/planning/planning'
], (angular, StorageService, HomeCtrl, DancerCtrl, DancerModel, PlanningModel) ->

  # declare main module that configures routing
  app = angular.module 'app', ['ngRoute', 'ui.bootstrap']
  app.config ['$locationProvider', '$routeProvider', (location, route) ->
    # TODO problem with angular 1.2.0rc1 use push state
    # location.html5Mode true
    # configure routing
    route.when "/home",
      name: 'home'
      templateUrl: 'home.html'
      controller: HomeCtrl
    route.when "/dancer/:id?",
      name: 'dancer'
      templateUrl: 'dancer.html'
      controller: DancerCtrl
    route.otherwise 
      redirectTo: "/home"
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