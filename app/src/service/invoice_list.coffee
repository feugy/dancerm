_ = require 'lodash'
SearchList = require './tools/search_list'

# Service responsible for keeping the card list between states
# Triggers search.
module.exports = class InvoiceList extends SearchList

  # **static**
  # Model class used
  @ModelClass: require '../model/invoice'

  # **static**
  # Default sort
  @sort: 'customer.name'

  # Initialise criteria
  constructor: (args...) ->
    @criteria =
      string: null
    super args...

  # **private**
  # Parse criteria to search options
  # @returns [Object] option for findWhere method.
  _parseCriteria: =>
    conditions = {}
    # depending on criterias
    if @criteria.string?.length >= 7
      # find all invoices by date
      conditions.date = new RegExp "^#{@criteria.string}", 'i'
    conditions