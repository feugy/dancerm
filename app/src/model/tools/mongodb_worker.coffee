{MongoClient}  = require 'mongodb'
{getDbPath, isA} = require '../../util/common'

# Database singleton, created on demand
db = null
lastId = null
# url = 'mongodb://dancerm:dancerm@ds141368.mlab.com:41368/dancerm'
url = 'mongodb://localhost:27017/dancerm'

# pending requests to get collections
pending = null

# Creates or reuse a collection to manage persistance operations
#
# @param name [String] expected model name
# @param done [Function] an end callback, invoked with parameters:
# @option done err [Error] an error object or null if no error occured
# @option done collection [Datastore] a collection object used to interract with persistance storage
getCollection = (name, done) ->
  # reuse existing collection
  return done null, db.collection name if db?
  return pending.push {name, done} if pending?
  pending = [{name, done}]
  # creates mongodb client
  console.log "initiate connection to #{url}"
  MongoClient.connect url, (err, connection) =>
    return done err if err?
    db = connection
    # honor all pending collection requests
    done null, db.collection name for {name, done} in pending
    pending = null

# MongoDB uses '_id', while DanceRM needs 'id'.
# Replaces incoming models's '_id' by 'id' equi
fixId = (model) ->
  return model unless model?
  model.id = model._id
  delete model._id
  model
fixIds = (models) ->
  return models unless models?
  (fixId model for model in models)

# Recursively walk down an object, replacing its serialized regexp object
# (that have a custom '__regexp' property) per full regexp
#
# @param obj [Object] the incoming object
# @return the object modified
decodeQuery = (obj) ->
  if isA obj, 'array'
    obj = (decodeQuery val for val in obj)
  else if isA obj, 'object'
    if obj.__regexp
      obj = new RegExp obj.pattern, obj.flags
    else
      res = {}
      for attr of obj
        # also replace 'id' fields per '_id'
        res[if attr is 'id' then '_id' else attr] = decodeQuery obj[attr]
      obj = res
  obj

# Worker message receiver
#
# @param data [Array<Object>] contains the following data:
# @option data[0] req [Number] unic id used to differentiate API calls
# @option data[1] action [String] expected action
# @option data[2] col [String] collection name
# @option data[3+] args [Any] action specific arguments
process.on 'message', (data) ->
  (([id, action, col, arg]) ->
    lastId = id
    getCollection col, (err, collection) ->
      return process.send err: err, id: id if err?
      switch action
        when 'drop'
          collection.drop (err) ->
            process.send id: id, err: err

        when 'findById'
          collection.findOne {_id: arg}, (err, model) ->
            process.send id: id, err: err, result: fixId model

        when 'find'
          collection.find(decodeQuery(arg)).toArray (err, models) ->
            process.send id: id, err: err, result: fixIds models

        when 'save'
          docId = arg.id
          arg._id = docId
          delete arg.id
          collection.replaceOne {_id: docId}, arg, {upsert:true}, (err) ->
            process.send id: id, err: err, result: fixId arg

        when 'remove'
          collection.remove {_id: arg}, (err) ->
            process.send id: id, err: err
  )(data)

# relay exception and logs to parent
console.log = (args...) -> process.send args.join ' '
console.error = (args...) -> process.send args.join ' '
process.on 'uncaughtException', (err) -> process.send id: lastId, err: err
