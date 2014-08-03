_ = require 'underscore'
async = require 'async'
moment = require 'moment'
Persisted = require '../persisted'
Address = require './address'
Registration = require './registration'
Planning = require '../planning/planning'

module.exports = class Dancer extends Persisted

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
    # check each conditions
    async.eachSeries _.pairs(conditions), ([path, expected], next) =>
      steps = path.split '.'
      condition = {}
      # check if condition include registration's planning
      for {search, prefix, select, extract} in [
          {search:'planning.', prefix:'', select: 'planningId', extract: (p, path) -> [p.id]}
          # TODO will be really eased if danceClasses are in a separated collection.
          # In this case, no need to perform projection
          {search:'danceClasses.', prefix: 'danceClasses.', select: 'danceClassIds', extract: (p, path) -> 
            [danceClass.id for danceClass in p.danceClasses when danceClass[path] is expected]
          }
        ]
        idx = path.indexOf search
        if idx >= 0
          conditionPath = path[idx+search.length..]
          condition[prefix + conditionPath] = expected
          return Planning.findWhere condition, (err, plannings) ->
            return next err if err?
            # only kept dancers with relevant planning ids
            delete conditions[path]
            path = path[0...idx] + select
            # TODO in case of autonomous danceClasses, just need to pluk ids.
            current = _.uniq _.flatten (extract planning, conditionPath for planning in plannings)
            if conditions[path]?.$in?
              # Logical and between existing conditions 
              current = _.intersection conditions[path].$in, current
            conditions[path] = $in: current
            next()
      # no specific conditions
      next()
    , (err) =>
      return callback err if err?
      # run superclass treatment
      super conditions, callback

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