_ = require 'underscore'
async = require 'async'
moment = require 'moment'
Base = require '../base'
Address = require './address'
Registration = require './registration'
Planning = require '../planning/planning'
{generateId} = require '../../util/common'

module.exports = class Dancer extends Base

  # In-memory cache, updated by finders. 
  @_cache = {}

  # **static**
  # Find a list of models from the storage provider that match given conditions
  # Condition is an object, whose fields are path within the dancer, with their expected values.
  # (interpreted in the same order)
  # In path, dots are supported, and allow diving in sub object or sub array.
  # An expected value may be a function, that will take as arguments the given value and it's model, 
  # and must returns a boolean
  # 
  # If 'planning' or 'danceClasses' are found within path, the corresponding planning model 
  # is automatically resolved and use for traversal
  #
  # @param conditions [Object] keys define path, values are expected values
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured
  # @option callback dancers [Array<Base>] array (that may be empty) of models matching these conditions
  @findWhere: (conditions, callback) ->
    @findAll (err, models) =>
      return callback err if err?
      # check each conditions
      async.forEach _.pairs(conditions), ([path, expected], next) =>
        steps = path.split '.'
        # check if condition include planning
        idx = path.indexOf 'danceClasses.'
        idx2 = path.indexOf 'planning.'
        if idx isnt -1 or idx2 isnt -1
          condition = {}
          if idx isnt -1
            condition[path[idx..]] = expected 
          else
            condition[path[idx2+9..]] = expected
          # select relevant plannings
          Planning.findWhere condition, (err, plannings) =>
            return next 'end' if plannings.length is 0
            # only kept dancers with relevant planning ids
            ids = _.pluck plannings, 'id'
            models = _.filter models, (model) =>
              _.some model.registrations, (registration) => registration.planningId in ids
            next()
        else
          # restrict the selected models for this condition
          async.filter models, (model, next) =>
            @_checkValue model, model, steps, expected, next
          , (results) =>
            # updates the model
            models = results
            return next 'end' if models.length is 0
            next()
      , (err) =>
        return callback null, [] if err is 'end'
        callback null, models

  id: null

  created: null

  # Dancer title (M. Mme Mlle) and name
  title: 'Mme'
  firstname: ''
  lastname: ''

  # Use a subobject to store address
  address: null

  # contact
  phone: null
  cellphone: null
  email: null

  birth: null

  # has or not a medical certificate for the current season
  certified: false

  # how the dancers has known the school: leaflets, website, pagejaunesFr, searchEngine, directory, associationsBiennal, mouth, other
  knownBy: []

  # list of registration for given dance classes
  registrations: []

  # Creates a dancer from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  #
  # @param raw [Object] raw attributes of this dancer
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw, 
      id: generateId()
      created: moment()
      birth: null
      title: 'Mme'
      firstname: ''
      lastname: ''
      address: null
      phone: null
      cellphone: null
      email: null
      certified: false
      registrations: []
      knownBy: []
    # fill attributes
    super(raw)
    # enrich object attributes
    @created = moment @created
    @birth = moment @birth if @birth?
    @address = new Address @address if @address?
    @registrations = (new Registration raw for raw in @registrations when raw?)