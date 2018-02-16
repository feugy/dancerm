_ = require 'lodash'
{eachSeries} = require 'async'
Base = require './base'
persistance = require './persistance'
{generateId} = require '../../util/common'

# instance cache. used to avoid creation.
cache = {}

# Invoke to initiate model's specific cache, unless it already exists
initCache = (name) => cache[name] = {} unless name of cache

# Superclass for models that will be persisted into underlying data store
# Automatically manage id value (created after save)
module.exports = class Persisted extends Base

  # declare id
  id: null

  # version incremented on each save
  _v: 0

  # **static** **private**
  # Nested models that are supported in findWhere.
  # For each supported model, must contain:
  # - search [String] the search prefix (like 'dancer.')
  # - Model [Class] the corresponding model class (like Dancer)
  # - select [String] property name within this instance where nested model id is stored (like 'dancerId')
  @_nestedModels: []

  # **static**
  # Clear all existing models
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  @drop: (done) ->
    initCache @name
    persistance.drop @name, (err) =>
      unless err?
        delete cache[@name]
        cache[@name] = {}
      done err

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
    initCache @name
    if cache[@name][id]?
      return _.defer => done null, cache[@name][id]
    start = Date.now()
    persistance.findById @name, id, (err, result) =>
      # TOREMOVE console.log "#{@name}.find(#{id}) #{Date.now()-start}ms"
      return done err if err?
      return done new Error "#{@name} '#{id}' not found" unless result?
      model = new @ result
      cache[@name][id] = model
      done null, model

  # **static**
  # Find all existing models from the storage manager.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done models [Array<Persisted>] an array (that may be empty) of matching models
  @findAll: (done) -> @findWhere {}, done

  # **static**
  # Find all existing raw values from the storage manager.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done models [Array<Object>] an array (that may be empty) of matching raw values
  @findAllRaw: (done) -> persistance.find @name, {}, done

  # **static**
  # Find a list of models from the storage provider that match given conditions
  # Condition is an object, whose fields are path within the instance, with their expected values.
  # (interpreted in the same order)
  # In path, dots are supported, and allow diving in sub object or sub array.
  # An expected value may be a function, that will take as arguments the given value and it's model,
  # and must returns a boolean
  #
  # If nested models prefix are found within path, the corresponding models are automatically resolved
  # and use for traversal
  #
  # @param conditions [Object] keys define path, values are expected values
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done models [Array<Persisted>] an array (that may be empty) of matching models
  @findWhere: (conditions, done) ->
    processStep = (step, stepDone) =>
      # check each conditions
      eachSeries _.toPairs(step), ([path, expected], next) =>
        return eachSeries expected, processStep, next if path is '$or' or path is '$and'
        steps = path.split '.'
        # check if condition include linked values
        for {search, Model, select} in @_nestedModels
          idx = path.indexOf search
          if idx >= 0
            # extract subcondition and performs query
            subCondition = {}
            subPath = path[idx+search.length..]
            subCondition[subPath] = expected
            return Model.findWhere subCondition, (err, models) ->
              return next err if err?
              # only kept dancers with relevant linked model ids
              delete step[path]
              path = path[0...idx] + select
              current = _.map models, 'id'
              if step[path]?.$in?
                # Logical and between existing conditions
                current = _.intersection step[path].$in, current
              step[path] = $in: current
              next()
        # no specific conditions
        next()
      , stepDone

    processStep conditions, (err) =>
      return done err if err?
      # run conventional treatment
      initCache @name
      start = Date.now()
      persistance.find @name, conditions, (err, results) =>
        # enrich with model if results available
        if results?
          for result, i in results
            model = if cache[@name][result.id]? then cache[@name][result.id] else new @ result
            results[i] = model
        # TOREMOVE console.log "#{@name}.findWhere(#{JSON.stringify conditions}) #{Date.now()-start}ms"
        done err, results

  # Build a persisted model
  # Initialize version to 0 and id to null
  constructor: (raw) ->
    initCache @constructor.name
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
    raw.id = raw.id or generateId()
    # TOREMOVE console.log "save model #{@constructor.name} ##{raw.id}", raw
    persistance.save @constructor.name, raw, (err) =>
      return done err if err?
      @id = raw.id
      @_v = raw._v
      cache[@constructor.name][raw.id] = @
      done null, @

  # Remove the current model from the persistance store.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done model [Persisted] currently removed model
  remove: (done) =>
    persistance.remove @constructor.name, @id, (err) =>
      delete cache[@constructor.name][@id] unless err?
      done null, @