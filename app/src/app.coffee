# configure requireJS
requirejs.config  

  # paths to vendor libs
  paths:
    'angular': '../vendor/angular/angular'
    'jquery': '../vendor/jquery/jquery'
    'ui.bootstrap': '../vendor/angular-bootstrap/ui-bootstrap-tpls'
    'moment': '../vendor/moment/moment'
    'nls': 'labels'
    'i18n': '../vendor/requirejs-i18n/i18n'
    'underscore': '../vendor/underscore/underscore'
    'underscore.string': '../vendor/underscore.string/lib/underscore.string'
    
  # vendor libs dependencies and exported variable
  shim:
    'angular':
      exports: 'angular'
    'jquery': 
      exports: '$'
    'moment': 
      exports: 'moment'
    'underscore': 
      exports: '_'
    'underscore.string': 
      deps: ['underscore']
    'ui.bootstrap':
      deps: ['angular']

require [
  'jquery'
  'angular'
  'underscore'
  'service/storage'
  'controller/home'
  'controller/dancer'
  # unwired
  'underscore.string'
  'ui.bootstrap'
], ($, angular, _, StorageService, HomeCtrl, DancerCtrl) ->

  # merge underscore and underscore string functions
  _.mixin _.str.exports()

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
  app.service 'storage', StorageService

  # starts the application !
  angular.bootstrap $('body'), ['app']
  
  app