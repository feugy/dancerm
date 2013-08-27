# configure requireJS
requirejs.config  

  # paths to vendor libs
  paths:
    'async': '../vendor/async/lib/async'
    'angular': '../vendor/angular/angular'
    'angular-ui-router': '../vendor/angular-ui-router/release/angular-ui-router.min'
    'jquery': '../vendor/jquery/jquery'
    'ui.bootstrap': '../vendor/angular-bootstrap/ui-bootstrap-tpls'
    'moment': '../vendor/moment/moment'
    'jszip': '../vendor/jszip/jszip.min'
    'nls': 'labels'
    'i18n': '../vendor/requirejs-i18n/i18n'
    'underscore': '../vendor/underscore/underscore'
    'underscore.string': '../vendor/underscore.string/lib/underscore.string'
    'xlsx': '../vendor/xlsx.js/xlsx'
    
  # vendor libs dependencies and exported variable
  shim:
    'angular':
      exports: 'angular'
    'angular-ui-router':
      deps: ['angular']
    'jquery': 
      exports: '$'
    'jszip':
      exports: 'JSZip'
    'moment': 
      exports: 'moment'
    'underscore': 
      exports: '_'
    'underscore.string': 
      deps: ['underscore']
    'ui.bootstrap':
      deps: ['angular']
    'xlsx': 
      deps: ['jszip']
      exports: 'xlsx'

require [
  'jquery'
  'underscore'
  'angular'
  # unwired
  'underscore.string'
  'angular-ui-router'
  'ui.bootstrap'
  './app'
  # require directives and filters immediately to allow circular dependencies
  './util/filters'
  './directive/registration'
  './directive/planning'
  './directive/payment'
], ($, _, angular) ->

  # merge underscore and underscore string functions
  _.mixin _.str.exports()

  # starts the application from a separate file to allow circular dependencies to application
  angular.bootstrap $('body'), ['app']