define [
  'underscore'
  'moment'
  '../base'
], (_, moment, Base) ->

  # Payment of a given registration in a dance class. 
  # May be per month, quarter or year.
  class Payment extends Base

    # card, cash, check
    type: 'check'

    # payment duration in month (only indicative)
    duration: 12

    # amount of money paid
    value: 0

    # receiption date
    receipt: null

    # free text, for example to store check owner name
    details: null

    # Creates a payment from a set of raw JSON arguments
    #
    # @param raw [Object] raw attributes of this payment
    constructor: (raw = {}) ->
      # set default values
      _.defaults raw, 
        type: 'check'
        receipt: moment()
        value: 0
        duration: 12
        details: null
      # fill attributes
      super(raw)
      # enrich object attributes
      @receipt = moment @receipt