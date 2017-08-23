_ = require 'lodash'
moment = require 'moment'
Persisted = require './tools/persisted'
# because of circular dependency
Dancer = null

# Private lesson a dancer can take
module.exports = class Lesson extends Persisted

  # extends transient fields
  @_transient = Persisted._transient.concat ['_dancer']

  # supported nested models
  @_nestedModels: [
    {search:'dancer.', Model: Dancer, select: 'dancerId'}
  ]

  # date with start hour
  date: null
  # lesson duration, in minutes
  duration: null

  # index of selected teacher for that invoice
  selectedTeacher: 0

  # link to concerned dancer
  dancerId: null

  # extra details
  details: null

  # price and status if already invoiced
  price: 45

  # link to a particular invoice (meaning it can't be invoiced anymore)
  invoiceId: null

  # computed and read-only lesson start hour
  @property 'start',
    get: -> @date.clone().locale('en').format 'ddd HH:mm'

  # computed and read-only lesson end
  @property 'end',
    get: -> @date.clone().locale('en').add(@duration, 'minutes').format 'ddd HH:mm'

  # Creates an lesson from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  #
  # @param raw [Object] raw attributes of this invoice
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      date: moment().seconds(0).milliseconds(0)
      duration: 60
      selectedTeacher: 0
      dancerId: null
      details: null
      price: 45
      invoiceId: null
    # fill attributes
    super(raw)
    @date = moment @date if @date?
    Dancer = require './dancer' unless Dancer?

  # Consult lesson's dancer
  #
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  # @option done dancer [Dancer] lesson's dancer
  getDancer: (done) =>
    return _.defer(=> done null, @_dancer) if @_dancer?
    return done null, null unless @dancerId?
    Dancer.find @dancerId, (err, dancer) =>
      return done err if err?
      @_dancer = dancer
      done null, @_dancer

  # Set lesson's dancer
  #
  # @param dancer [Dancer] lesson's dancer
  setDancer: (dancer) =>
    @dancerId = dancer?.id or null
    @_dancer = dancer