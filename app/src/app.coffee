# configure requireJS
requirejs.config  

 # paths to vendor libs
  paths:
    'angular': '../vendor/angular/angular'
    'jquery': '../vendor/jquery/jquery'
    'ui.bootstrap': '../vendor/angular-bootstrap/ui-bootstrap-tpls'
    'underscore': '../vendor/underscore/underscore'
    'underscore.string': '../vendor/underscore.string/lib/underscore.string'
    
  # vendor libs dependencies and exported variable
  shim:
    'angular':
      exports: 'angular'
    'jquery': 
      exports: '$'
    'underscore': 
      exports: '_'
    'underscore.string': 
      exports: '_'
    'ui.bootstrap':
      deps: ['angular']

require [
  'jquery'
  'angular'
  'underscore'
  'controller/home'
  # unwired
  'underscore.string'
  'ui.bootstrap'
], ($, angular, _, HomeCtrl) ->

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
    route.otherwise 
      redirectTo: "/home"
  ]

  # starts the application !
  angular.bootstrap $('body'), ['app']
  
  