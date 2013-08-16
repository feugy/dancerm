define [
  'underscore'
], (_) ->

  # Abstract base functionnalities of models
  # Persistence facilities are provided out of the box, but requires to bind the model class to a storage provider.
  # This operation (bind()) has to be done only once.
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
    # Find a model from the storage provider by it's id
    # An error will be reported if no existing model matches this id.
    #
    # @param id [String] the searched model's id
    # @param callback [Function] end callback, invoked with:
    # @option callback err [Error] an error object, or null if no problem occured
    # @option callback model [Base] the found model
    @find: (id, callback) ->
      return callback(new Error "#{@name} isn't bound to any storage provider") unless @storage?
      @storage.get id, @, callback

    # **static**
    # Find all existing models from the storage manager.
    #
    # @param callback [Function] end callback, invoked with:
    # @option callback err [Error] an error object, or null if no problem occured
    # @option callback models [Array<Base>] the found models
    @findAll: (callback) ->
      return callback(new Error "#{@name} isn't bound to any storage provider") unless @storage?
      models = []
      @storage.walk @, (model, next) ->
        models.push model
        next()
      , (err) ->
        callback err, models

    # Save the current model into the bound storage manager.
    #
    # @param callback [Function] end callback, invoked with:
    # @option callback err [Error] an error object, or null if no problem occured    
    save: (callback) =>
      return callback(new Error "#{@name} isn't bound to any storage provider") unless @constructor.storage?
      @constructor.storage.add @, callback

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