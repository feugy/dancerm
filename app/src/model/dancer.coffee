_ = require 'lodash'
{map} = require 'async'
moment = require 'moment'
Persisted = require './tools/persisted'
Address = require './address'
DanceClass = require './dance_class'
Card = require './card'
Lesson = require './lesson'

# Dancers keeps information relative to person attended to dance class, and card
module.exports = class Dancer extends Persisted

  # extends transient fields
  @_transient = Persisted._transient.concat ['_address', '_card', '_danceClasses', '_lessons']

  # supported nested models
  @_nestedModels: [
    {search:'card.', Model: Card, select: 'cardId'}
    {search:'danceClasses.', Model: DanceClass, select: 'danceClassIds'}
    {search:'address.', Model: Address, select: 'addressId'}
    {search:'lessons.', Model: Lesson, select: 'lessonIds'}
  ]

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
  lessonIds: []

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
      lessonIds: []
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

  # Consult dancer's lessons
  #
  # @param done [Function] completion callback, invoked with arguments
  # @option done err [Error] an error object or null if no error occured
  # @option done lessons [Array<Lesson>] list (that may be empty) of dancer's lessons, all seasons
  getLessons: (done) =>
    return _.defer(=> done null, @_lessons) if @_lessons?
    # avoid possible duplicates
    @lessonIds = _.uniq @lessonIds
    # resolve models
    map @lessonIds, (id, next) =>
      Lesson.find id, (err, result) =>
        console.log "failed to get lesson #{id} of dancer #{@firstname} #{@lastname} (#{@id}): #{err}" if err?
        next null, result
    , (err, results) =>
      # remove undefined values (occured when a dance class was not found)
      @_lessons = _.compact results
      done null, @_lessons

  # Set dancer's classes
  #
  # @param lessons [Array<Lesson>] list (that may be empty) of dancer's lessons, all seasons
  setLessons: (lessons) =>
    @lessonIds = unless lessons? then [] else _.map lessons, 'id'
    @_lessons = lessons

# need to init here because of circular dependencies
Lesson._nestedModels[0].Model = Dancer