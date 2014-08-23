_ = require 'underscore'
{currentSeason} = require '../util/common'
Base = require './tools/base'
Payment = require './payment'

# Registration is for one or several classes and a given
# Multiple payment may be used for the same registration: their sum is stored in `balance`
module.exports = class Registration extends Base

  # corresponding season
  season: null

  # store medical certificates for each involved persons
  # person id is used as key 
  certificates: {}

  # price awaited and account balance
  charged: 0

  # payment period: year, quarter, class
  period: 'year'

  # payment free text field
  details: null

  # payment list for this registration and the account balance 
  payments: []
  balance: 0

  # Creates a registration from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this registration
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw, 
      season: currentSeason()
      certificates: {}
      charged: 0
      balance: 0
      payments: []
      period: 'year'
      details: null

    # enrich object attributes
    raw.payments = (for rawPayment in raw.payments 
      if rawPayment?.constructor?.name isnt 'Payment'
        new Payment rawPayment 
      else
        rawPayment
    )
    # fill attributes
    super(raw)

    # on payment change, remove old listeners and add new ones
    Object.defineProperty @, 'payments',
      configurable: true
      get: -> @_raw.payments
      set: (val) -> 
        if @_raw.payments?
          Array.unobserve @_raw.payments, @_onPaymentsChanged
        @_raw.payments = val
        if @_raw.payments?
          Array.observe @_raw.payments, @_onPaymentsChanged
        @_onPaymentsChanged [
          addedCount: @_raw.payments.length
          index: 0
          object: @_raw.payments
          removed: []
          type: 'splice'
        ]

    # on certificat changes, trigger change event
    Object.defineProperty @, 'certificates',
      configurable: true
      get: -> @_raw.certificates
      set: (val) -> 
        if @_raw.certificates?
          try
            Object.unobserve @_raw.certificates, @_onCertificatesChanged
          catch err
            # silent error
        @_raw.certificates = val
        if @_raw.certificates?
          Object.observe @_raw.certificates, @_onCertificatesChanged
        @_onCertificatesChanged()

    # for bindings initialization
    @payments = @payments
    @certificates = @certificates


  # **private**
  # Emit change event when payments have changed, and update balance
  #
  # @param details [Object] change details, containing added 'object' array, and 'removed' object array.
  _onPaymentsChanged: ([details]) => 
    # update bindings
    if details?.removed?
      removed.removeListener 'change', @_onSinglePaymentChanged for removed in details.removed when removed?.removeListener
    if details?.object
      added.on 'change', @_onSinglePaymentChanged for added in details.object when added?.on
    # update balance and trigger change event
    @emit 'change', 'payments', @_raw.payments
    @updateBalance()

  # **private**
  # Emit change event when single payment changed itself
  #
  # @param attr [String] modified path
  # @param value [Any] new value
  _onSinglePaymentChanged: (attr, value) =>
    @emit 'change', "payments.#{attr}", value
    @updateBalance()

  # **private**
  # Emit change event when certificates' attribute have changed.
  _onCertificatesChanged: =>
    @emit 'change', 'certificates', @_raw.certificates

  # Updates balance by summing payments.
  # Automatically invoked on payment change
  updateBalance: =>
    sum = 0
    for payment in @payments
      sum += payment.value or 0
    @balance = sum if sum isnt @balance

  # @return amount to be paid for this registration
  due: =>
    @charged - @balance

  # @return if a dancer was certified for this registration
  certified: (dancer) =>
    @certificates[dancer.id] is true
    