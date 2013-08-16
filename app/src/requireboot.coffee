# configure requireJS
requirejs.config  

  # paths to vendor libs
  paths:
    'async': '../vendor/async/lib/async'
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
  'underscore'
  'angular'
  # unwired
  'underscore.string'
  'ui.bootstrap'
  './app'
  # require directive now for circular dependencies
  './directive/registration'
  './directive/planning'
  './directive/payment'
], ($, _, angular) ->

  # merge underscore and underscore string functions
  _.mixin _.str.exports()

  # starts the application from a separate file to allow circular dependencies to application
  angular.bootstrap $('body'), ['app']