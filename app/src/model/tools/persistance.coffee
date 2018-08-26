{getDbPath, isA} = require '../../util/common'
{fork} = require 'child_process'

reqId = 1
# possible options: indexeddb & mongodb & nedb. The later one does not support importing 8000 models
workerImpl = 'indexeddb'

# Recursively walk down an object, replacing its regexp values per an array
# containing the regexp pattern and flags.
# That array has a custom '__regexp' property
# Returns a clone to avoid side effects
#
# @param obj [Object] the modified object
# @return a clone containing replaced values
encodeRegExp = (obj) ->
  result = obj
  if isA obj, 'regexp'
    result = __regexp: true, pattern: obj.source, flags: obj.flags
  else if isA obj, 'array'
    result = (encodeRegExp val for val in obj)
  else if isA obj, 'object'
    result = {}
    result[attr] = encodeRegExp obj[attr] for attr of obj
  result

class Persistance

  # **private**
  # Queue used to store caller's callback, ans associate it to request id
  _queue: {}

  # **private**
  # Worker spawned to handle persistance
  _worker: null

  constructor: ->
    @_queue = {}
    dirname = __dirname.replace 'src', 'script'
    switch workerImpl
      when 'indexeddb'
        @_worker = new window.Worker "#{dirname}/indexeddb_worker.js?path=#{encodeURIComponent getDbPath()}"
        @_worker.onmessage = (msg) =>
          return @_onResult msg.data if msg.data?
          console.error "unexpected message from persistance worker: #{JSON.stringify(msg)}"
          @_onResult err: msg
        @_worker.onerror = (err) =>
          err?.preventDefault()
          console.error "persistance worker (#{err?.lineno}:#{err?.colno}) #{err?.message}"
          @_onResult id: err.id, err

      when 'nedb', 'mongodb'
        @_worker = fork "#{dirname}/#{workerImpl}_worker.js"
        @_worker.on 'message', (data) =>
          return @_onResult data if data?.id
          if isA data, 'error'
            console.error "persistance worker: #{data.message} #{data.stack}"
            throw data
          else
            console.log "persistance worker:", data

  # **private**
  # Used when the worker answered a result
  #
  # @param data [Object] worker's result, containing the following attributes:
  # @option data id [Number] corresponding request's id
  # @option data err [Error] optionnal worker's error
  # @option data result [Object] optionnal worker's result
  _onResult: ({id, err, result}) =>
    # invoke done handler with error or result
    @_queue[id]?(err or null, result)
    delete @_queue[id]

# Add persistance operations
#
# > drop
# remove all models for this class
#
# @param name [String] model name
# @param done [Function] completion callback, invoked with arguments:
# @option done err [Error] an error object or null if no error occured
#
# > findById
# Get a single model from its id
#
# @param name [String] model name
# @param id [String] searched id
# @param done [Function] completion callback, invoked with arguments:
# @option done err [Error] an error object or null if no error occured
# @option done model [Persisted] the corresponding model, or null if no model found for this id
#
# > find
# Get a list of model matching given criteria
#
# @param name [String] model name
# @param criteria [Object] search criteria, like a mongo's query
# @param done [Function] completion callback, invoked with arguments:
# @option done err [Error] an error object or null if no error occured
# @option done models [Array<Persisted>] the matching models (may be an empty array)
#
# > save
# Add a new model (if id is not set or does not match existing) or erase existing model
#
# @param name [String] model name
# @param model [Persisted] saved model new values
# @param done [Function] completion callback, invoked with arguments:
# @option done err [Error] an error object or null if no error occured
#
# > remove
# removed an existing model
#
# @param name [String] model name
# @param id [String] deleted id
# @param done [Function] completion callback, invoked with arguments:
# @option done err [Error] an error object or null if no error occured
['drop', 'findById', 'find', 'save', 'remove'].forEach (action) ->
  Persistance::[action] = (args..., done) ->
    id = reqId++
    @_queue[id] = done
    op = 'postMessage'
    if workerImpl isnt 'indexeddb'
      op = 'send'
      # escape query regexpes
      args[1] = encodeRegExp args[1] if action is 'find'
    @_worker[op] [id, action].concat args

module.exports = new Persistance()