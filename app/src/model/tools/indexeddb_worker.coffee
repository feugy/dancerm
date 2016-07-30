# lodash must be loaded
importScripts '../../../../node_modules/lodash/index.js'

# get database path from url
path = decodeURIComponent location.search.replace '?path=', ''

# cache for database
db = null

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
# Conditions follows MongoDB's behaviour: it supports nested path, regexp values, $regex, $or, $in operators
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
    else if attr is '$regex'
      # check $regexp operator
      return false unless checkSingle new RexExp(expected), model
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
            return false unless (checkSingle expected, value for value in actual).some (x) -> x
          else
            subCondition = {}
            subCondition[path.slice(i+1).join '.'] = expected
            return false unless (check subCondition, value for value in actual).some (x) -> x
          break
      continue if isArray
      return false unless checkSingle expected, actual
  true

# Retrieve object store, and initialize dedicated database if needed.
#
# @param name [String] object store name (case sensitive)
# @param write [Boolean] true to open store for writing, false for reading
# @param done [Function] completion callback, invoked with arguments:
# @option done err [Error] an error object or null if no error occured
# @option done store [ObjectStore] object store ready to use
getStore = (name, write, done) ->
  proceed = ->
    tx = db.transaction [name], if write then 'readwrite' else 'readonly'
    tx.onerror = (event) -> done event
    done null, tx.objectStore name

  # immediately proceed if possible
  return proceed() if db?

  # initialize database
  request = indexedDB.open path

  request.onsuccess = ->
    db = request.result
    proceed()

  request.onerror = (event) ->
    db = null
    done request.error

  request.onupgradeneeded = ({target}) ->
    for name in ['Invoice', 'Dancer', 'Address', 'Card', 'DanceClass', 'Tested']
      target.result.createObjectStore name, keyPath: 'id'

# Worker message receiver
#
# @param data [Array<Object>] contains the following data:
# @option data[0] id [Number] unic id used to differentiate API calls
# @option data[1] action [String] expected action
# @option data[2] clazz [String] object store name
# @option data[3+] args [Any] action specific arguments
onmessage = ({data}) ->
  (([id, action, clazz, arg]) ->
    getStore clazz, action in ['drop', 'save', 'remove'], (err, store) ->
      return postMessage err: err, id: id if err?
      switch action
        when 'drop'
          store.clear().onsuccess = -> postMessage id: id

        when 'findById'
          req = store.get(arg)
          req.onsuccess = -> postMessage id:id, result: req.result

        when 'find'
          results = []
          req = store.openCursor()
          req.onsuccess = ({target}) ->
            cursor = target.result
            return postMessage id:id, result: results unless cursor?
            results.push cursor.value if check arg, cursor.value
            cursor.continue()

        when 'save'
          store.put(arg).transaction.oncomplete = -> postMessage id:id

        when 'remove'
          store.delete(arg).transaction.oncomplete = -> postMessage id:id
  )(data)
