_ = require 'lodash'
Base = require './tools/base'
Price = require './price'

# Price category: a given title to group a set of prices.
# Embedded into price list
module.exports = class PriceCategory extends Base

  # category title
  category: ''

  # individual prices
  prices: []

  # Creates a price category from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this price category
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      category: ''
      prices: []

    # enrich object attributes
    raw.prices = (for rawPrice in raw.prices
      if rawPrice?.constructor?.name isnt 'Price'
        new Price rawPrice
      else
        rawPrice
    )

    # fill attributes
    super(raw)