_ = require 'underscore'
Base = require './base'
Datastore = require 'nedb'
{Promise} = require 'es6-promise'
{join} = require 'path'
{generateId, getDbPath} = require '../../util/common'

# stores underlying collections used by models, stored by name
cache = {}

dbPath = getDbPath()

# Superclass for models that will be persisted into underlying data store
# Automatically manage id value (created after save)
# All asynchronous operations returns promises
module.exports = class Persisted extends Base

  # declare id
  id: null

  # version incremented on each save
  _v: 0

  # **static** **private**
  # Creates or reuse a collection to manage persistance operations
  #
  # @return a promise with collection object used to interract with persistance storage
  @_collection: ->
    new Promise (resolve, reject) =>
      # opens store if necessary
      unless cache[@name]?
        cache[@name] = new Datastore
          autoload: true
          filename: join dbPath, @name
      resolve cache[@name]

  # **static**
  # Clear all existing models
  #
  # @return a promise without parameter
  @drop: ->
    @_collection().then (collection) =>
      new Promise (resolve, reject) =>
        collection.remove {}, {multi: true}, (err) =>
          return reject err if err?
          resolve()

  # **static**
  # Find a model from the storage provider by it's id.
  # Use and updates cache if possible.
  # An error will be reported if no existing model matches this id.
  #
  # @param id [String] the searched model's id
  # @return a promise with the corresponding model
  @find: (id) ->
    @_collection().then (collection) =>
      new Promise (resolve, reject) =>
        collection.findOne {_id: id}, (err, raw) =>
          return reject err if err?
          return reject new Error "'#{id}' not found" unless raw?
          raw.id = raw._id
          resolve new @ raw

  # **static**
  # Find all existing models from the storage manager.
  #
  # @return a promise with an array (that may be empty) of matching models
  @findAll: -> @findWhere {}

  # **static**
  # Find a list of models from the storage provider that match given conditions
  # Condition is an object, whose fields are path within the dancer, with their expected values.
  # (interpreted in the same order)
  # In path, dots are supported, and allow diving in sub object or sub array.
  # An expected value may be a function, that will take as arguments the given value and it's model, 
  # and must returns a boolean.
  #
  # @param conditions [Object] keys define path, values are expected values/functions
  # @return a promise with an array (that may be empty) of matching models
  @findWhere: (conditions) ->
    @_collection().then (collection) =>
      new Promise (resolve, reject) =>
        collection.find conditions, (err, raws) =>
          return reject err if err?
          resolve (for raw in raws
            raw.id = raw._id
            new @ raw
          )

  # Build a persisted model
  # Initialize version to 0 and id to null
  constructor: (raw) ->
    raw._v = -1 unless raw._v?
    if raw._id?
      raw.id = raw._id
      delete raw._id
    raw.id = null unless raw.id?
    super raw

  # Save the current model into the persistance store.
  #
  # @return a promise with current model as parameter.
  save: =>
    @constructor._collection().then (collection) =>
      new Promise (resolve, reject) =>
        raw = @toJSON()
        raw._v += 1
        # increment version
        id = raw.id or generateId()
        delete raw.id
        collection.update {_id: id}, raw, {upsert: true}, (err, replacedNb, model) => 
          return reject err if err?
          @_raw.id = model._id if model?
          @_raw._v = raw._v
          resolve @

  # Remove the current model from the persistance store.
  #
  # @return a promise with current model as parameter.
  remove: =>
    @constructor._collection().then (collection) =>
      new Promise (resolve, reject) =>
        collection.remove {_id: raw.id}, (err) =>
          return reject err if err?
          resolve @