define [
  'underscore'
  'async'
  'moment'
  '../base'
  './address'
  './registration'
  '../planning/planning'
  '../../util/common'
], (_, async, moment, Base, Address, Registration, Planning, {generateId}) ->

  class Dancer extends Base

    # In-memory cache, updated by finders. 
    @_cache = {}

    # **private**
    # Check the a given path inside an object has the expected value.
    # steps contains an item per from sub objects to dive in.
    # If a sub object is an array, all this items are checked, and the method exist at first match.
    #
    # Enhance to auto resolve planning values
    #
    # @param obj [Object] the checked object
    # @param steps [Array] contains names of each attributes of each sub object
    # @param expected [Object] the expected value
    # @param callback [Function] end callback, invoked with arguments:
    # @option callback match [Boolean] true if the value match, false otherwise.

    # **static**
    # Find a list of models from the storage provider that match given conditions
    # Condition is an object, whose fields are path within the dancer, with their expected values.
    # (interpreted in the same order)
    # In path, dots are supported, and allow diving in sub object or sub array.
    # 
    # If planning is found within path, the planning corresponding model is automatically retrieved 
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
              @_checkValue model, steps, expected, next
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