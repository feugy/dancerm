_ = require 'lodash'
moment = require 'moment'
Base = require './tools/base'

# Private lesson a dancer can take
module.exports = class Lesson extends Base

  # date with start hour
  date: null
  # lesson duration, in minutes
  duration: null

  # who taught what
  teacher: null
  kind: null

  # extra details
  details: null

  # price and status if already invoiced
  price: 0
  invoiced: false

  # computed and read-only lesson end
  @property 'end',
    get: -> @start.clone().add @duration, 'minutes'

  # Creates an lesson from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  #
  # @param raw [Object] raw attributes of this invoice
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      date: moment().seconds(0).milliseconds(0)
      duration: 60
      teacher: null
      kind: null
      details: null
      price: 0
      invoiced: false
    # fill attributes
    super(raw)
    @date = moment @date if @date?