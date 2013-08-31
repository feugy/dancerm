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
    @scope.$watch 'search.string', @_onSearchChanged 
    # injects public methods into scope
    @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

  # display a given dancer on the main part
  #
  # @param dancer [Dancer] choosen dancer
  displayDancer: (dancer) =>
    console.log "ask to display #{dancer.id}"
    @location.path "/home/dancer/#{dancer.id}"

  # **private**
  # Triggers a new search if at least 3 characters are present and value changed
  #
  # @param value [String] the current searched string
  # @param old [String] previous searched string
  _onSearchChanged: (value, old) =>
    # quit if no changes detected or not enough letters
    return unless value?.length >= 3 and value isnt old
    @scope.search.classId = null
    @scope.search.season = null
    @scope.search.teacher = null
    @scope.triggerSearch()