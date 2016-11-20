_ = require 'lodash'
moment = require 'moment'
{map} = require 'async'
{currentSeason} = require '../util/common'
Base = require './tools/base'
Payment = require './payment'
Invoice = require './invoice'

# Registration is for one or several classes and a given
# Multiple payment may be used for the same registration: their sum is stored in `balance`
module.exports = class Registration extends Base

  @_transient = Base._transient.concat ['balance', '_invoices']

  # creation date
  created: null

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

  # ids of related invoices
  invoiceIds: []

  # Creates a registration from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this registration
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      created: moment()
      season: currentSeason()
      certificates: {}
      charged: 0
      balance: 0
      payments: []
      period: 'year'
      details: null
      invoiceIds: []

    # enrich object attributes
    raw.payments = (for rawPayment in raw.payments
      if rawPayment?.constructor?.name isnt 'Payment'
        new Payment rawPayment
      else
        rawPayment
    )
    # fill attributes
    super(raw)
    # enrich object attributes
    @created = moment @created
    @created = null unless @created.isValid()
    @charged = +@charged

  # Updates balance by summing payments.
  # Automatically invoked on payment change
  updateBalance: =>
    sum = 0
    for payment in @payments
      sum += payment.value or 0
    @balance = sum if sum isnt @balance

  # @return amount to be paid for this registration
  due: =>
    @updateBalance()
    amount = @charged
    amount *= 3 if @period is 'quarter'
    amount - @balance

  # @return if a dancer was certified for this registration
  certified: (dancer) =>
    @certificates[dancer?.id] is true

  # Consult registration's invoices
  #
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  # @option done invoices [Array<Invoice>] list (that may be empty) of registration's invoices
  getInvoices: (done) =>
    return _.defer(=> done null, @_invoices) if @_invoices?
    # resolve models
    map @invoiceIds, (id, next) =>
      Invoice.find id, (err, result) =>
        console.log "failed to get invoice #{id} of registration #{@id}: #{err}" if err?
        next null, result
    , (err, results) =>
      @_invoices = results
      done null, @_invoices