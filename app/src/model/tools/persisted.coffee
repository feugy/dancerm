_ = require 'lodash'
Base = require './base'
{join} = require 'path'
{getCollection} = require './initializer'
{generateId, isA} = require '../../util/common'

isA = (obj, type) ->
  clazz = Object::toString.call(obj).slice 8, -1
  obj isnt undefined and obj isnt null and clazz is type

# Check if a single value match expected
# Supports regexp test, $in operator and exact match
#
# @param expected [Object] expected condition
# @param actual [Object] actual value
# @return true if the single condition is matched, false otherwise
checkSingle = (expected, actual) ->
  if isA expected, 'RegExp'
    expected.test actual
  else if isA(expected, 'Object') and expected.$in
    actual in expected.$in
  else 
    actual is expected

# Synchronously check if a raw model match given conditions
# Conditions follows MongoDB's behaviour: it supports nested path, regexp values, $or, $in operators 
# and exact match.
# Array values are automatically expanded
# 
# @param conditions [Object] condition to match
# @param model [Object] tested raw model
# @return true if all condition are matched, false otherwise
check = (conditions, model) ->
  for attr of conditions
    expected = conditions[attr]
    if attr is '$or'
      # check each possibilities
      return false unless _.any expected, (choice) -> check choice, model
    else
      actual = model
      isArray = false
      path = attr.split '.'
      for step, i in path
        actual = actual[step]
        return false unless actual?
        if isA actual, 'Array'
          isArray = true
          if i is path.length-1
            return false unless (checkSingle expected, value for value in actual).some (_) -> _
          else
            subCondition = {}
            subCondition[path.slice(i+1).join '.'] = expected
            return false unless (check subCondition, value for value in actual).some (_) -> _
          break
      continue if isArray
      return false unless checkSingle expected, actual
  true

# find raw models from object store
#
# @param name [String] store name
# @param conditions [Object] keys define path, values are expected values
# @param done [Function] completion callback, invoked with parameters:
# @option done err [Error] an error object or null if no problem occured
# @option done models [Array<Object>] array (that may be empty) of matching raw models
findWhere = (name, conditions, done) ->
  results = []
  getCollection(name, done).openCursor().onsuccess = ({target}) => 
    cursor = target.result
    return done null, results unless cursor?
    results.push cursor.value if check conditions, cursor.value
    cursor.continue()

# instance cache. used to avoid creation.
# TODO class initialization
cache =
  Address: {}
  Card: {}
  DanceClass: {}
  Dancer: {}
  Tested: {}

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
    getCollection(@name, done, true).clear().onsuccess = => 
      delete cache[@name]
      cache[@name] = {}
      done()

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
    if cache[@name][id]?
      return _.defer => done null, cache[@name][id]
    start = Date.now()
    req = getCollection(@name, done).get(id)
    req.onsuccess = => 
      # TOREMOVE console.log "#{@name}.find(#{id}) #{Date.now()-start}ms"
      return done new Error "#{@name} '#{id}' not found" unless req.result?
      model = new @ req.result
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
  @findAllRaw: (done) -> findWhere @name, {}, done

  # **static**
  # Find a list of models from the storage provider that match given conditions
  # Condition is an object, whose fields are path within the dancer, with their expected values.
  # (interpreted in the same order)
  # In path, dots are supported, and allow diving in sub object or sub array.
  # An expected value may be a function, that will take as arguments the given value and it's model, 
  # and must returns a boolean.
  #
  # @param conditions [Object] keys define path, values are expected values
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done models [Array<Persisted>] an array (that may be empty) of matching models
  @findWhere: (conditions, done) ->
    start = Date.now()
    findWhere @name, conditions, (err, results) =>
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
    getCollection(@constructor.name, done, true).put(raw).transaction.oncomplete = =>
      @_raw.id = raw.id
      @_raw._v = raw._v
      cache[@constructor.name][raw.id] = @
      done null, @

  # Remove the current model from the persistance store.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done model [Persisted] currently removed model
  remove: (done) =>
    getCollection(@constructor.name, done, true).delete(@_raw.id).transaction.oncomplete = => 
      delete cache[@constructor.name][@_raw.id]
      done null, @