# configure requireJS
requirejs.config  

  # paths to vendor libs
  paths:
    'async': '../vendor/async/lib/async'
    'chai': '../vendor/chai/chai'
    'mocha': '../vendor/mocha/mocha'
    'moment': '../vendor/moment/moment'
    'underscore': '../vendor/underscore/underscore'
    'underscore.string': '../vendor/underscore.string/lib/underscore.string'
    
  # vendor libs dependencies and exported variable
  shim:
    'chai':
      exports: 'chai'
    'mocha': 
      exports: 'mocha'
    'moment': 
      exports: 'moment'
    'underscore': 
      exports: '_'
    'underscore.string': 
      deps: ['underscore']

require [
  'chai'
  'mocha'
  'require'
  'underscore'
  # unwired
  'underscore.string'
], (chai, mocha, require, _) ->
  
  # merge underscore and underscore string functions
  _.mixin _.str.exports()

  # export 'expect-style' chai assertion
  window.expect = chai.expect
  mocha.setup 'bdd'

  # get test and run them
  require [
    'service/storage_test'
    'model/dancer_test'
    'model/danceclass_test'
    'model/planning_test'
    'util/common_test'
  ], ->
    mocha.checkLeaks()
    mocha.globals(['jQuery', 'expect'])
    mocha.run()