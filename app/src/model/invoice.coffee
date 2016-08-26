_ = require 'lodash'
moment = require 'moment'
Persisted = require './tools/persisted'
InvoiceItem = require './invoice_item'
{invoiceRefFormat} = require '../util/common'
# because of circular dependency
Dancer = null

# Invoice for a given registration
module.exports = class Invoice extends Persisted

  # extends transient fields
  @_transient = Persisted._transient.concat ['total', 'dutyFreeTotal', 'taxTotal']

  # **static**
  # Check if a given reference match the expected format, and isn't already used
  # Specify the self parameter to check if an existing Invoice can reuse its ref
  #
  # @param ref [String] checked refernce
  # @param self [Invoice] invoice which ref isn't considered as exiting
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done valid [Boolean] true if reference can be used
  @isRefValid: (ref, self, done) ->
    unless done?
      done = self
      self = null
    return done null, false unless ref? and invoiceRefFormat.test ref
    @findWhere {ref: ref}, (err, [exist]) ->
      done err, not exist? or exist.id is self?.id

  # **static**
  # Get the next free reference relative to a given date.
  # Find all references of the same month and year, order by rank, and return next rank.
  # If no references of the same month and year exist, return ref N°1 for that month.
  # During reference parsing, year on 4 digits is expected to come first, then month on 2 digits,
  # Then rank. Any non-numerical part will be ignored, as well as numerical part found after.
  #
  # Pad reference left with 2 zeros
  #
  # @param year [Number] desired year
  # @param month [Number] desired month (1-based)
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done ref [String] reference generated
  @getNextRef: (year, month, done) ->
    @findAllRaw (err, models) ->
      return done err if err?
      # gets all existing references
      refs = models.map (model) -> model.ref.match(invoiceRefFormat)?.splice(1, 3) or []
        .filter ([y, m]) -> +y is year and +m is month
        .map ([y, m, ref]) -> +ref
        .sort (a, b) -> a - b
      last = refs[refs.length-1] or 0
      console.log year, month, refs
      done null, "#{year}-#{_.padStart month, 2, '0'}-#{_.padStart last + 1, 3, '0'}"

  # invoice reference
  ref: null
  # application and due date
  date: null
  dueDate: null

  # customer details (name, street, city, zipcode)
  customer: null

  # list of items included in that invoice
  items: []

  # global discount
  discount: 0

  # fee applied in case of delayed paiement
  delayFee: 5

  # when valuated, invoice is readonly
  sent: null

  # index of selected school for that invoice
  selectedSchool: 0

  # link to card and season, if applicable
  cardId: null
  season: null

  # computed and read-only duty-free invoice total
  @property 'dutyFreeTotal',
    get: -> _.round((1 - @discount/100) * @items.reduce(((total, item) -> total + item.dutyFreeTotal), 0), 2) or 0

  # computed and read-only tax total
  @property 'taxTotal',
    get: -> _.round((1 - @discount/100) * @items.reduce(((total, item) -> total + item.taxTotal), 0), 2) or 0

  # computed and read-only invoice total
  @property 'total',
    get: -> _.round((1 - @discount/100) * @items.reduce(((total, item) -> total + item.total), 0), 2) or 0

  # Creates an invoice from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  #
  # @param raw [Object] raw attributes of this invoice
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      ref: null
      date: moment()
      customer:
        name: ''
        street: ''
        zipcode: ''
        city: ''
      items: []
      discount: 0
      delayFee: 5
      sent: null
      cardId: null
      season: null
      selectedSchool: 0
    # enrich object attributes
    raw.items = (for rawItem in raw.items
      if rawItem?.constructor?.name isnt 'InvoiceItem'
        new InvoiceItem rawItem
      else
        rawItem
    )
    # fill attributes
    super(raw)
    @sent = moment @sent if @sent?
    @changeDate raw.date
    Dancer = require './dancer' unless Dancer?

  # Save the current invoice into the persistance store.
  # Check reference validity first
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done model [Persisted] currently saved model
  save: (done) =>
    Invoice.isRefValid @ref, @, (err, isValid) =>
      return done err, null if err?
      return done new Error "Reference '#{@ref}' is misformated or already used" unless isValid
      super done

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
    @customer.name = "#{dancer.title} #{dancer.firstname} #{dancer.lastname}"
    dancer.getAddress (err, address) =>
      return done err if err?
      Object.assign @customer, address.toJSON() if address?
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