define [
  'underscore'
  '../base'
  './payment'
], (_, Base, Payment) ->

  # Registration is for one or several classes and a given
  # Multiple payment may be used for the same registration: their sum is stored in `balance`
  class Registration extends Base

    # corresponding planning, meaning registration season
    planningId: null

    # id of the concerned dance classs
    danceClassIds: []

    # price awaited and account balance
    charged: 0

    # payment list for this registration and the account balance 
    payments: []
    balance: 0

    # Creates a registration from a set of raw JSON arguments
    #
    # @param raw [Object] raw attributes of this registration
    constructor: (raw = {}) ->
      # set default values
      _.defaults raw, 
        planningId: null
        danceClassIds: []
        charged: 0
        balance: 0
        payments: []
      # fill attributes
      super(raw)
      # enrich object attributes
      @payments = (new Payment raw for raw in @payments when raw?)
      @updateBalance()

    # Updates the registration's balance according to payment values
    updateBalance: =>
      @balance = 0
      for payment in @payments
        @balance += payment.value