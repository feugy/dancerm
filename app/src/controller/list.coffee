_ = require 'underscore'
  
module.exports = class ListController
              
  # Controller dependencies
  # Inject storage to ensure that models are properly initialized
  @$inject: ['$scope', '$location']
  
  # Controller scope, injected within constructor
  scope: null

  # Link to Angular location provider
  location: null
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param location [Object] Angular location provider
  constructor: (@scope, @location) -> 
    @scope.tags = []
    @scope.$watch 'search', @_onSearchChanged, true 
    @scope.$watch 'search.name', @_onSearchNameChanged 
    # injects public methods into scope
    @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

  # display a given dancer on the main part
  #
  # @param dancer [Dancer] choosen dancer
  displayDancer: (dancer) =>
    console.log "ask to display #{dancer.id}"
    @location.path "/home/dancer/#{dancer.id}"