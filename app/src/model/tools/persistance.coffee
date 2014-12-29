{getDbPath} = require '../../util/common'

reqId = 1

class Persistance

  constructor: ->
    @worker = new window.Worker __dirname + '/persistance_worker.js?path=' + encodeURIComponent getDbPath()
    @queue = {}
    @worker.onmessage = ({data}) =>
      # invoke done handler with error or result
      @queue[data.id]?(data.err or null, data.result)
      delete @queue[data.id]

    @worker.onerror = (err) => 
      err?.preventDefault()
      console.log "persistance worker (#{err?.lineno}:#{err?.colno}) #{err?.message}"

['drop', 'findById', 'find', 'save', 'remove'].forEach (action) ->
  Persistance::[action] = (args..., done) ->
    id = reqId++
    @queue[id] = done
    @worker.postMessage [id, action].concat args

module.exports = new Persistance()