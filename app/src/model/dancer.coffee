_ = require 'lodash'
async = require 'async'
moment = require 'moment'
Persisted = require './tools/persisted'
Address = require './address'
DanceClass = require './danceclass'
Card = require './card'

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
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured
  # @option callback dancers [Array<Base>] array (that may be empty) of models matching these conditions
  @findWhere: (conditions) ->
    new Promise (resolve, reject) =>
      # check each conditions
      async.eachSeries _.pairs(conditions), ([path, expected], next) =>
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
            return Model.findWhere(subCondition).then((models) ->
              # only kept dancers with relevant linked model ids
              delete conditions[path]
              path = path[0...idx] + select
              current = _.pluck models, 'id'
              if conditions[path]?.$in?
                # Logical and between existing conditions 
                current = _.intersection conditions[path].$in, current
              conditions[path] = $in: current
              next()
            ).catch(next)
        # no specific conditions
        next()
      , (err) =>
        return reject err if err?
        # run superclass treatment
        super(conditions).then resolve

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

  # address property, getter returns a promise
  @property 'address',
    get: -> 
      new Promise (resolve, reject) =>
        return resolve @_address if @_address?
        return resolve null unless @addressId?
        Address.find(@addressId).then (address) => 
          @_address = address
          resolve @_address
    set: (address) -> 
      @addressId = address?.id or null
      @_address = address

  # link to the card of for this dancer, may be shared with other dancers
  cardId: null

  # card property, getter returns a promise
  @property 'card',
    get: -> 
      new Promise (resolve, reject) =>
        return resolve @_card if @_card?
        Card.find(@cardId).then (card) => 
          @_card = card
          resolve @_card
    set: (card) ->
      @cardId = card?.id or null
      @_card = card

  # array of dance classes this dancer is attended to
  danceClassIds: []
  
  # registration property, getter returns a promise
  @property 'danceClasses',
    get: -> 
      new Promise (resolve, reject) =>
        return resolve @_danceClasses if @_danceClasses?
        DanceClass.findWhere(_id: $in: @danceClassIds).then (danceClasses) => 
          @_danceClasses = danceClasses
          resolve @_danceClasses
    set: (danceClasses) -> 
      @danceClassIds = unless danceClasses? then [] else _.pluck danceClasses, 'id'
      @_danceClasses = danceClasses

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
    # fill attributes
    super(raw)
    # default card value
    @_card = new Card() if @cardId is null
    # enrich object attributes
    @created = moment @created
    @birth = moment @birth if @birth?

  # Consult dancer's last registration (ordered in time)
  #
  # @return a promise resolve with last registration or null
  lastRegistration: =>
    @card.then (card) =>
      registrations = _.sortBy(card.registrations.concat(), 'season').reverse()
      Promise.resolve registrations?[0] or null