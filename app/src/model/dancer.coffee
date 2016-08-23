_ = require 'lodash'
{eachSeries, map} = require 'async'
moment = require 'moment'
Persisted = require './tools/persisted'
Address = require './address'
DanceClass = require './dance_class'
Card = require './card'
Lesson = require './lesson'

# Dancers keeps information relative to person attended to dance class, and card
module.exports = class Dancer extends Persisted

  # extends transient fields
  @_transient = Persisted._transient.concat ['_address', '_card', '_danceClasses']

  # **static**
  # Find a list of models from the storage provider that match given conditions
  # Condition is an object, whose fields are path within the dancer, with their expected values.
  # (interpreted in the same order)
  # In path, dots are supported, and allow diving in sub object or sub array.
  # An expected value may be a function, that will take as arguments the given value and it's model,
  # and must returns a boolean
  #
  # If 'registrations', 'address' or 'danceClasses' are found within path, the corresponding models
  # are automatically resolved and use for traversal
  #
  # @param conditions [Object] keys define path, values are expected values
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done models [Array<Persisted>] an array (that may be empty) of matching models
  @findWhere: (conditions, done) ->
    # check each conditions
    eachSeries _.toPairs(conditions), ([path, expected], next) =>
      steps = path.split '.'
      # check if condition include linked values
      for {search, Model, select} in [
          {search:'card.', Model: Card, select: 'cardId'}
          {search:'danceClasses.', Model: DanceClass, select: 'danceClassIds'}
          {search:'address.', Model: Address, select: 'addressId'}
        ]
        idx = path.indexOf search
        if idx >= 0
          # extract subcondition and performs query
          subCondition = {}
          subPath = path[idx+search.length..]
          subCondition[subPath] = expected
          return Model.findWhere subCondition, (err, models) ->
            return next err if err?
            # only kept dancers with relevant linked model ids
            delete conditions[path]
            path = path[0...idx] + select
            current = _.map models, 'id'
            if conditions[path]?.$in?
              # Logical and between existing conditions
              current = _.intersection conditions[path].$in, current
            conditions[path] = $in: current
            next()
      # no specific conditions
      next()
    , (err) =>
      return done err if err?
      # run superclass treatment
      super conditions, done

  created: null

  # Dancer title (M. Mme Mlle) and name
  title: null
  firstname: null
  lastname: null

  # personnal contact
  cellphone: null
  email: null

  # date of birth
  birth: null

  # link to address of this dancer, may be shared with other dancers
  addressId: null

  # link to the card of for this dancer, may be shared with other dancers
  cardId: null

  # array of dance classes this dancer is attended to
  danceClassIds: []

  # array of lesson taken
  lessons: []

  # Creates a dancer from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  #
  # @param raw [Object] raw attributes of this dancer
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      created: moment()
      title: null
      firstname: null
      lastname: null
      cellphone: null
      email: null
      birth: null
      knownBy: []
      addressId: null
      cardId: null
      danceClassIds: []
      lessons: []
    # enrich object attributes
    raw.lessons = (for rawLesson in raw.lessons
      if rawLesson?.constructor?.name isnt 'Lesson'
        new Lesson rawLesson
      else
        rawLesson
    )
    # fill attributes
    super(raw)
    # default card value
    @_card = new Card() if @cardId is null
    # enrich object attributes
    @created = moment @created
    @birth = moment @birth if @birth?

  # Consult dancer's address
  #
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  # @option done address [Address] dancer's address
  getAddress: (done) =>
    return _.defer(=> done null, @_address) if @_address?
    return done null, null unless @addressId?
    Address.find @addressId, (err, address) =>
      return done err if err?
      @_address = address
      done null, @_address

  # Set dancer's address
  #
  # @param address [Address] dancer's new address
  setAddress: (address) =>
    @addressId = address?.id or null
    @_address = address

  # Consult dancer's registration card
  #
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  # @option done card [Card] dancer's registration card
  getCard: (done) =>
    return _.defer(=> done null, @_card) if @_card?
    Card.find @cardId, (err, card) =>
      return done err if err?
      @_card = card
      done null, @_card

  # Set dancer's registration card
  #
  # @param card [Card] dancer's new registration card
  setCard: (card) =>
    @cardId = card?.id or null
    @_card = card

  # Consult dancer's classes
  #
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  # @option done danceClasses [Array<DanceClass>] list (that may be empty) of dancer's dance classes, all seasons
  getClasses: (done) =>
    return _.defer(=> done null, @_danceClasses) if @_danceClasses?
    # avoid possible duplicates
    @danceClassIds = _.uniq @danceClassIds
    # resolve models
    map @danceClassIds, (id, next) =>
      DanceClass.find id, (err, result) =>
        console.log "failed to get dance class #{id} of dancer #{@firstname} #{@lastname} (#{@id}): #{err}" if err?
        next null, result
    , (err, results) =>
      # remove undefined values (occured when a dance class was not found)
      @_danceClasses = _.compact results
      done null, @_danceClasses

  # Set dancer's classes
  #
  # @param danceClasses [Array<DanceClass>] list (that may be empty) of dancer's dance classes, all seasons
  setClasses: (danceClasses) =>
    @danceClassIds = unless danceClasses? then [] else _.map danceClasses, 'id'
    @_danceClasses = danceClasses

  # Consult dancer's last registration (ordered in time)
  #
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  # @option done registration [Registration] last registration, or null if no registration found
  getLastRegistration: (done) =>
    @getCard (err, card) =>
      return done err if err?
      registrations = _.sortBy(card.registrations.concat(), 'season').reverse()
      done null, registrations?[0] or null