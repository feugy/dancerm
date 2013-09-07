_ = require 'underscore'
  
module.exports = class ListController
              
  # Controller dependencies
  @$inject: ['$scope', '$state']
  
  # Controller scope, injected within constructor
  scope: null

  # Link to Angular state provider
  state: null
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param state [Object] Angular state provider
  constructor: (@scope, @state) -> 
    @scope.tags = []
    # injects public methods into scope
    @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # detach table during transition, to avoid huge UI redraw
    table = null
    previous = null
    @scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState) =>
      if toState.name is 'expanded-list' or fromState.name is 'expanded-list'
        element = $('.column-and-main .column .table')
        if @scope.list.length
          table = element          
          previous = table.prev();
          table.detach()
    $('.column-and-main .column').on 'webkitTransitionEnd', (e) ->
      if table? and $(e.target).hasClass 'column'
        table.insertAfter previous 
        table = null

  # Displays a given dancer on the main part
  #
  # @param dancer [Dancer] choosen dancer
  onDisplayDancer: (dancer) =>
    console.log "ask to display #{dancer.id}"
    @state.go 'list-and-dancer', id:dancer.id