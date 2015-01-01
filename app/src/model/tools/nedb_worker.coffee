Datastore = require 'nedb'
{join} = require 'path'
{getDbPath, isA} = require '../../util/common'

# stores underlying collections used by models, stored by name
cache = {}

dbPath = getDbPath()

# Creates or reuse a collection to manage persistance operations
#
# @param name [String] expected model name
# @param done [Function] an end callback, invoked with parameters:
# @option done err [Error] an error object or null if no error occured
# @option done collection [Datastore] a collection object used to interract with persistance storage
getStore = (name, done) ->
  # reuse existing collection
  return done null, cache[name] if cache[name]?
  # creates the store
  cache[name] = new Datastore filename: join dbPath, name
  # loads it
  cache[name].loadDatabase (err) =>
    return done err if err?
    done null, cache[name]

# NeDB uses '_id', while DanceRM needs 'id'.
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
# @option data[0] id [Number] unic id used to differentiate API calls
# @option data[1] action [String] expected action
# @option data[2] clazz [String] object store name
# @option data[3+] args [Any] action specific arguments
process.on 'message', (data) ->
  (([id, action, clazz, arg]) ->
    getStore clazz, (err, store) ->
      return process.send err: err, id: id if err?
      switch action
        when 'drop'
          store.remove {}, {multi: true}, (err, removedNb) -> 
            process.send err: err, id: id

        when 'findById' 
          store.findOne {_id: arg}, (err, result) -> 
            process.send id:id, err:err, result: fixId result

        when 'find'
          store.find decodeQuery(arg), (err, result) -> 
            process.send id:id, err:err, result: fixIds result

        when 'save'
          docId = arg.id
          arg._id = docId
          delete arg.id
          store.update {_id: docId}, arg, {upsert:true}, (err, replacedNb, result) -> 
            process.send id:id, err:err, result: fixId result
        
        when 'remove'
          store.remove {_id: arg}, (err) -> 
            process.send id:id, err:err
  )(data)

# relay exception and logs to parent
console.log = (args...) -> process.send args.join ' '
console.error = (args...) -> process.send args.join ' '
process.on 'uncaughtException', process.send