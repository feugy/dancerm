# configure requireJS
requirejs.config  

  # paths to vendor libs
  paths:
    'async': '../vendor/async/lib/async'
    'angular': '../vendor/angular/angular'
    'angular-route': '../vendor/angular/angular-route'
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
    'angular-route':
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
  'ui.bootstrap'
  './app'
  # require directives and filters immediately to allow circular dependencies
  'angular-route'
  './util/filters'
  './directive/registration'
  './directive/planning'
  './directive/payment'
], ($, _, angular) ->

  # merge underscore and underscore string functions
  _.mixin _.str.exports()

  # starts the application from a separate file to allow circular dependencies to application
  angular.bootstrap $('body'), ['app']