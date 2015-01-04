{getDbPath, isA} = require '../../util/common'
{fork} = require 'child_process'

reqId = 1
# other possible: nedb. But does not support importing 8000 models
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
    switch workerImpl
      when 'indexeddb' 
        @_worker = new window.Worker "#{__dirname}/indexeddb_worker.js?path=#{encodeURIComponent getDbPath()}"
        @_worker.onmessage = ({data}) => @_onResult data
        @_worker.onerror = (err) => 
          err?.preventDefault()
          console.log "persistance worker (#{err?.lineno}:#{err?.colno}) #{err?.message}"

      when 'nedb'
        @_worker = fork "#{__dirname}/nedb_worker.js"
        @_worker.on 'message', (data) =>
          return @_onResult data if data?.id
          if isA data, 'error'
            console.log "persistance worker #{data.message} #{data.stack}"
          else
            console.log "persistance worker #{JSON.stringify data}"

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
# TODOC
['drop', 'findById', 'find', 'save', 'remove'].forEach (action) ->
  Persistance::[action] = (args..., done) ->
    id = reqId++
    @_queue[id] = done
    op = 'postMessage'
    if workerImpl is 'nedb' 
      op = 'send'
      # escape query regexpes
      args[1] = encodeRegExp args[1] if action is 'find'
    @_worker[op] [id, action].concat args

module.exports = new Persistance()