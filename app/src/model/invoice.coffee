moment = require 'moment'
Persisted = require './tools/persisted'
InvoiceItem = require './invoice_item'
# because of circular dependency
Dancer = null

# Invoice for a given registration
module.exports = class Invoice extends Persisted

  # invoice reference
  ref: null
  # application and due date
  date: null
  dueDate: null

  # customer details
  name: null
  address: null

  # list of items included in that invoice
  items: []

  # global discount
  discount: 0

  # fee applied in case of delayed paiement
  delayFee: 0

  # when valuated, invoice is readonly
  sent: null

  # link to card, if applicable
  cardId: null

  # Creates an invoice from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  #
  # @param raw [Object] raw attributes of this invoice
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      ref: null # TODO generate
      date: moment()
      name: ''
      address: ''
      items: []
      discount: 0
      delayFee: 0
      sent: null
      cardId: null
    # enrich object attributes
    raw.items = (for rawItem in raw.items
      if rawItem?.constructor?.name isnt 'InvoiceItem'
        new InvoiceItem rawItem
      else
        rawItem
    )
    # fill attributes
    super(raw)
    @changeDate raw.date
    Dancer = require './dancer' unless Dancer?

  # Set date value, and affect due date automatically
  #
  # @param date [String|Date|Moment] new date value
  # @param interval [Number] number of days before due date, default to 60
  changeDate: (date, interval = 60) =>
    @date = moment(date)
    @dueDate = @date.clone().add(interval, 'days')

  # Set customer by setting dancer
  #
  # @param dancer [Dancer] dancer used as customer
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  setCustomer: (dancer, done) =>
    return done null unless dancer?
    @name = "#{dancer.title} #{dancer.firstname} #{dancer.lastname}"
    dancer.getAddress (err, address) =>
      return done err if err?
      @address = "#{address.street}\n#{address.zipcode} #{address.city}" if address?
      done null

  # Set dance classes by setting registration and dancer
  #
  # @param dancerId [String] id of the dancer which dance classes will be added
  # @param registrationId [String] id of the registration containing dance classes
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  ###addDanceClasses: (dancerId, registrationId, done) =>
    return done null unless dancerId? and registrationId?
    Registration.find registrationId, (err, registration) =>
      return done err if err?
      Dancer.find dancerId, (err, dancer) =>
        return done err if err?
        return done null unless dancer? and registration?
        dancer.getClasses (err, danceClasses) =>
          return done err if err?
          @danceClasses.push danceClasses
            .filter((danceClass) => danceClass.season is registration.season)
            .map (danceClass) =>
              name: "#{danceClass.kind} #{danceClass.level} #{danceClass.start}"
              quantity: 1
              price: 0
              VAT: 0
              discount: 0
          done null###