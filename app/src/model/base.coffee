define [
  'underscore'
  'async'
], (_, async) ->


  # Abstract base functionnalities of models
  # Persistence facilities are provided out of the box, but requires to bind the model class to a storage provider.
  # This operation (bind()) has to be done only once.
  #
  # The _cache static attribute MUST be defined inside subclasses
  class Base

    # Creates a model from a set of raw JSON arguments
    # Default values will be applied, and only declared arguments are used
    #
    # @param raw [Object] raw attributes of this dancer
    constructor: (raw = {}) ->
      # only allow awaited attribtues
      allowed = (attr for attr, value of @ when not _.isFunction value)
      raw = _.pick.apply _, [raw].concat allowed

      # finally, copy attributes into current instance
      for attr, value of raw
        @[attr] = value

    # **static**
    # Binds the current class to a storage provider
    #
    # @param storage [Storage] the bound storage provider
    @bind: (storage) ->
      throw new Error "the #{@name} class cannot be bound to a null storage provider" unless storage?
      @storage = storage

    # **static**
    # Find a model from the storage provider by it's id.
    # Use and updates cache if possible.
    # An error will be reported if no existing model matches this id.
    #
    # @param id [String] the searched model's id
    # @param callback [Function] end callback, invoked with:
    # @option callback err [Error] an error object, or null if no problem occured
    # @option callback model [Base] the found model
    @find: (id, callback) ->
      return callback(new Error "#{@name} isn't bound to any storage provider") unless @storage?
      # use storage unless we have a cached value
      if id of @_cache
        return _.defer => callback null, @_cache[id]
      @storage.get id, @, (err, model) =>
        # update cache
        @_cache[model.id] = model if model?
        callback err, model 

    # **static**
    # Find all existing models from the storage manager.
    # Use and updates cache if possible.
    #
    # @param callback [Function] end callback, invoked with:
    # @option callback err [Error] an error object, or null if no problem occured
    # @option callback models [Array<Base>] the found models
    @findAll: (callback) ->
      return callback(new Error "#{@name} isn't bound to any storage provider") unless @storage?
      # use the cache unless no entry
      unless 0 is _.size @_cache
        return _.defer => callback null, _.values @_cache
      models = []
      # walk along the storage procider
      @storage.walk @, (model, next) =>
        models.push model
        # store in cache
        @_cache[model.id] = model
        next()
      , (err) ->
        callback err, models

    # **static**
    # Find a list of models from the storage provider that match given conditions
    # Condition is an object, whose fields are path within the dancer, with their expected values.
    # (interpreted in the same order)
    # In path, dots are supported, and allow diving in sub object or sub array.
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

    # **private**
    # Check the a given path inside an object has the expected value.
    # steps contains an item per from sub objects to dive in.
    # If a sub object is an array, all this items are checked, and the method exist at first match
    #
    # @param obj [Object] the checked object
    # @param steps [Array] contains names of each attributes of each sub object
    # @param expected [Object] the expected value
    # @param callback [Function] end callback, invoked with arguments:
    # @option callback match [Boolean] true if the value match, false otherwise.
    @_checkValue: (obj, steps, expected, callback) ->
      for step, i in steps
        obj = obj[step]
        # step not found: quit immediately
        return callback false unless obj? 
        if _.isArray obj
          return async.detect obj, (value, next) =>
            # check all array items
            @_checkValue value, steps[i+1..], expected, next
          , (item) =>
            # if one match, will be returned
            callback item?
      # simple value: check it
      callback obj is expected

    # Save the current model into the bound storage manager.
    #
    # @param callback [Function] end callback, invoked with:
    # @option callback err [Error] an error object, or null if no problem occured    
    save: (callback) =>
      return callback(new Error "#{@name} isn't bound to any storage provider") unless @constructor.storage?
      @constructor.storage.add @, (err) =>
        # update cache
        @constructor._cache[@id] = @ unless err?
        callback err

    # Returns a json representation of the current model.
    # Also operate on sub models
    #
    # @return raw attribute of the current model
    toJSON: =>
      raw = {} 
      for attr, value of @ when not _.isFunction value
        if _.isArray value
          raw[attr] = []
          for val, i in value
            raw[attr][i] = if val?.toJSON? then val.toJSON() else val
        else
          raw[attr] = if value?.toJSON? then value.toJSON() else value
      raw