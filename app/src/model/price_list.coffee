_ = require 'lodash'
Persisted = require './tools/persisted'
PriceCategory = require './price_category'
i18n = require '../labels/common'

# Price list is a set of price categories
# Persisted in database
module.exports = class PriceList extends Persisted

  # **static**
  # Find the unic price list, defaulting to an empty list
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done priceList [PriceList] the corresponding price list
  @findSingle: (done) ->
    @findWhere {}, (err, list) =>
      return done err if err?
      return done null, if list?.length > 0 then list[0] else new PriceList categories: i18n.priceList.default

  # List of price categories
  categories: []

  # Creates a price listfrom a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this price list
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      categories: []

    # enrich object attributes
    raw.categories = (for rawCategory in raw.categories
      if rawCategory?.constructor?.name isnt 'PriceCategory'
        new PriceCategory rawCategory
      else
        rawCategory
    )
    super(raw)

  # Makes a flat representation of the entire price list, to be processed in a single loop
  #
  # @returns [Array<PriceCategory|Price>] flatten price list
  flatList: =>
    @categories.reduce (list, category) =>
      list.push category
      list.concat category.prices
    , []