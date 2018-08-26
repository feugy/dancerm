_ = require 'lodash'
Base = require './tools/base'

# Price category: a given title to group a set of prices.
# Embedded into price list
module.exports = class Price extends Base

  # price full name, displayed on invoice items
  name: ''

  # price value
  price: 0

  # default quantity applied
  quantity: 1

  # short label used in list
  label: ''

  # Creates a price from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this price
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      name: ''
      price: 0
      quantity: 1
      label: ''

    # fill attributes
    super(raw)