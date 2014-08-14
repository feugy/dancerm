_ = require 'underscore'
LayoutController = require './layout'
  
module.exports = class ListController extends LayoutController
  
  # tags displayed above dancer's list
  tags: []

  # Controller constructor: bind methods and attributes to current scope
  constructor: (parentArgs...) ->
    super parentArgs...
    @tags = []

    # detach table during transition, to avoid huge UI redraw
    table = null
    previous = null
    @rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState) =>
      return unless @list.length and (toState.name is 'expanded-list' or fromState.name is 'expanded-list')
      _.defer =>       
        table = $('.column.expanded .table')
        previous = table.prev()
        table.detach()
    $('.column-and-main .column').on '$animate:close', (e) ->
      return unless table? and previous?
      table.insertAfter previous 
      table = null

  # Displays a given dancer on the main part
  #
  # @param dancer [Dancer] choosen dancer
  displayDancer: (dancer) =>
    console.log "ask to display #{dancer.id}"
    @state.go 'list-and-dancer', id:dancer.id