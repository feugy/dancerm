_ = require 'lodash'
{isA} = require '../util/common'
Price = require '../model/price'
i18n = require '../labels/common'

class PriceCategoryDirective

  # Controller dependencies
  @$inject: []

  # Controller constructor: bind methods and attributes to current scope
  constructor: () ->

  # check if a given field is missing or not
  #
  # @param field [String] checked field
  # @param index [Number] when provided, index of the checked price in price list
  # @return a css class
  isRequired: (field, index = null) =>
    return 'invalid' if 'category' is field and not @model.category?
    if index?
      return 'invalid' unless @model.prices[index]?[field]?
    ''
  
  # adds a new price to current price category
  addPrice: () => 
    @model.prices.push new Price name: i18n.lbl.rate
    @onChange?()

  # removes a given price from price category
  removePrice: (index) =>
    return unless 0 <= index and index < @model?.prices?.length
    @model.prices.splice index, 1
    @onChange?()

  # invoked on individual change
  # 
  # @param details [Object] change details: $field and $inde (when relevant)
  onItemChange: () => @onChange?()

# Allows to edit a set of prices for a given category
module.exports = (app) ->
  app.directive 'priceCategory', ->
    # directive template
    templateUrl: "price_category.html"
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: PriceCategoryDirective
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope:
      # edited PriceCategory model
      model: '=src'
      # invoked when price list needs to be removed ('model' parameter)
      onRemove: '&?'
      # invoke when price category, or price list items are modified
      onChange: '&?'