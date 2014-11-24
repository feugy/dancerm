_ = require 'lodash'
Base = require './base'
{join} = require 'path'
{getCollection} = require './initializer'
{generateId} = require '../../util/common'

# Superclass for models that will be persisted into underlying data store
# Automatically manage id value (created after save)
module.exports = class Persisted extends Base

  # declare id
  id: null

  # version incremented on each save
  _v: 0

  # **static**
  # Clear all existing models
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  @drop: (done) ->
    getCollection(@name).remove {}, {multi: true}, (err) =>
      done if err? and err?.code isnt 'ENOENT' then err else null

  # **static**
  # Find a model from the storage provider by it's id.
  # Use and updates cache if possible.
  # An error will be reported if no existing model matches this id.
  #
  # @param id [String] the searched model's id
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object (for example if model does not exist) or null if no error occured
  # @option done model [Persisted] the corresponding model
  @find: (id, done) ->
    start = Date.now()
    getCollection(@name).findOne {_id: id}, (err, raw) =>
      return done err if err?
      return done new Error "'#{id}' not found" unless raw?
      raw.id = raw._id
      console.log "#{@name}.find(#{id}) #{Date.now()-start}ms"
      done null, new @ raw

  # **static**
  # Find all existing models from the storage manager.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done models [Array<Persisted>] an array (that may be empty) of matching models
  @findAll: (done) -> @findWhere {}, done

  # **static**
  # Find a list of models from the storage provider that match given conditions
  # Condition is an object, whose fields are path within the dancer, with their expected values.
  # (interpreted in the same order)
  # In path, dots are supported, and allow diving in sub object or sub array.
  # An expected value may be a function, that will take as arguments the given value and it's model, 
  # and must returns a boolean.
  #
  # @param conditions [Object] keys define path, values are expected values/functions
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done models [Array<Persisted>] an array (that may be empty) of matching models
  @findWhere: (conditions, done) ->
    start = Date.now()
    getCollection(@name).find conditions, (err, raws) =>
      return done err if err?
      models = (for raw in raws
        raw.id = raw._id
        new @ raw
      )
      console.log "#{@name}.findWhere(#{JSON.stringify conditions}) #{Date.now()-start}ms"
      done null, models

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
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done model [Persisted] currently saved model
  save: (done) =>
    raw = @toJSON()
    raw._v += 1
    # increment version
    raw._id = raw.id or generateId()
    delete raw.id
    getCollection(@constructor.name).update {_id: raw._id}, raw, {upsert: true}, (err) => 
      return done err if err?
      @_raw.id = raw._id
      @_raw._v = raw._v
      done null, @

  # Remove the current model from the persistance store.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done model [Persisted] currently removed model
  remove: (done) =>
    getCollection(@constructor.name).remove {_id: @_raw.id}, {}, (err) => done err, @