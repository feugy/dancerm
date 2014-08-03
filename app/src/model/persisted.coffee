_ = require 'underscore'
Base = require './base'
Datastore = require 'nedb'
{join, resolve} = require 'path'
{generateId} = require '../util/common'

# stores underlying collections used by models, stored by name
cache = {}

isTest = process.env.NODE_ENV?.toLowerCase()?.trim() is 'test'
dbPath = resolve join __dirname, '..', '..', '..', 'data', "dancerm#{if isTest then '-test' else ''}" 

# Superclass for models that will be persisted into underlying data store
# Automatically manage id value (created after save)
module.exports = class Persisted extends Base

  # declare id
  id: null

  # **static** **private**
  # Creates or reuse a collection to manage persistance operations
  #
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured
  # @option callback collection [Object] a collection object used to interract with persistance storage
  @_collection: (callback) ->
    # opens store if necessary
    unless cache[@name]?
      cache[@name] = new Datastore
        autoload: true
        filename: join dbPath, @name
    callback null, cache[@name]

  # **static**
  # Clear all existing models
  #
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured
  @drop: (callback = ->) ->
    @_collection (err, collection) ->
      return callback err if err?
      collection.remove {}, {multi: true}, callback

  # **static**
  # Find a model from the storage provider by it's id.
  # Use and updates cache if possible.
  # An error will be reported if no existing model matches this id.
  #
  # @param id [String] the searched model's id
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured
  # @option callback model [Base] the found model
  @find: (id, callback = ->) ->
    @_collection (err, collection) =>
      return callback err if err?
      collection.findOne {_id: id}, (err, raw) =>
        return callback err if err?
        return callback new Error "'#{id}' not found" unless raw?
        raw.id = raw._id
        callback null, new @ raw

  # **static**
  # Find all existing models from the storage manager.
  # Use and updates cache if possible.
  #
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured
  # @option callback models [Array<Base>] the found models
  @findAll: (callback = ->) -> @findWhere {}, callback

  # **static**
  # Find a list of models from the storage provider that match given conditions
  # Condition is an object, whose fields are path within the dancer, with their expected values.
  # (interpreted in the same order)
  # In path, dots are supported, and allow diving in sub object or sub array.
  # An expected value may be a function, that will take as arguments the given value and it's model, 
  # and must returns a boolean.
  #
  # @param conditions [Object] keys define path, values are expected values/functions
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured
  # @option callback dancers [Array<Base>] array (that may be empty) of models matching these conditions
  @findWhere: (conditions, callback = ->) ->
    @_collection (err, collection) =>
      return callback err if err?
      collection.find conditions, (err, raws) =>
        return callback err if err?
        callback null, (for raw in raws
          raw.id = raw._id
          new @ raw
        )

  # Save the current model into the persistance store.
  #
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured    
  save: (callback) =>
    @constructor._collection (err, collection) =>
      return callback err if err?
      raw = @toJSON()
      id = raw.id or generateId()
      delete raw.id
      collection.update {_id: id}, raw, {upsert: true}, (err, replacedNb, model) => 
        return callback err if err?
        @id = model._id if model?
        callback null

  # Remove the current model from the persistance store.
  #
  # @param callback [Function] end callback, invoked with:
  # @option callback err [Error] an error object, or null if no problem occured    
  remove: (callback) =>
    @constructor._collection (err, collection) =>
      return callback err if err?
      collection.remove {_id: raw.id}, callback