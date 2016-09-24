_ = require 'lodash'
SearchList = require './tools/search_list'

# Service responsible for searching for invoices, and keep the list between states.
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
    seed = @criteria.string or ''
    # find by month
    match = seed.match /^(\d{2})/
    conditions.date = new RegExp "^\\d{4}-#{match[1]}" if match?
    # or find by year
    match = seed.match /^(\d{4})/
    conditions.date = new RegExp "^#{match[1]}" if match?
    # or find by month and year
    match = seed.match /^(\d{4})[/\-\.](\d{2})/
    conditions.date = new RegExp "^#{match[1]}-#{match[2]}" if match?
    # or find by customer
    conditions['customer.name'] = new RegExp seed, 'i' unless conditions.date? or seed.length < 3
    conditions