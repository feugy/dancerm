_ = require 'underscore'
ListController = require './list' 
i18n = require '../labels/common'

module.exports = class ExpandedListController extends ListController
  

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param state [Object] Angular state provider
  constructor: (scope, state) -> 
    super scope, state
    @scope.i18n = i18n
    # keeps current sort for inversion
    @scope.sort = null
    @scope.sortAsc = true

  # Sort list by given attribute and order
  #
  # @param attr [String] sort attribute
  onSort: (attr) =>
    # invert if using same sort.
    if attr is @scope.sort
      @scope.list.reverse()
      @scope.sortAsc = !@scope.sortAsc
    else
      @scope.sortAsc = true
      @scope.sort = attr
      # specific attributes
      if attr is 'due'
        attr = (model) -> model?.registrations?[0]?.due() 
      else if attr is 'address'
        attr = (model) -> model?.address?.zipcode
      @scope.list = _.sortBy @scope.list, attr