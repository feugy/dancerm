define [
  'underscore'
  'i18n!nls/common'
  '../model/dancer'
], (_, i18n, Dancer) ->
  
  class DancerController
              
    # Controller dependencies
    @$inject: ['$scope', 'storage']
    
    # Controller scope, injected within constructor
    scope: null

    # Storage service
    storage: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] Angular current scope
    # @param storage [Storage] Storage service
    constructor: (@scope, storage) -> 
      # fill the scope and bind public methods
      @scope.i18n = i18n
      for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'
        @scope[attr] = value

    onNewDancer: =>
      # TODO check modifications, allow saving
      @scope.dancer = new Dancer i18n.defaultDancer