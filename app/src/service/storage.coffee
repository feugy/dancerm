_ = require 'underscore'
Dancer = require '../model/dancer/dancer'
Planning = require '../model/planning/planning'

# supported model classes
_supported = [Dancer, Planning]

# Storage is a service to store and retrieve models (Dancer and Planning).
# Works as a persistent hashmap.
module.exports = class Storage

  # Inner database
  db: null

  # Storage constructor
  constructor: () ->
    test = mocha?
    @dbName= "dancerm#{if test then '-test' else ''}"
    @db = null

  # **private**
  # Run a given process function that need database to be initialize.
  # Opens and initialize the database before if needed.
  #
  # @param process [Function] processing function, without any arguments
  # @param callback [Function] processing end function, invoked with arguments:
  # @option callback err [Error] an error object, or null if no error occured
  _runOrOpen: (process, callback) =>
    return process() if @db?
    request = window.indexedDB.open @dbName
      
    request.onsuccess = =>
      @db = request.result
      process()

    request.onerror = (event) =>
      @db =null
      callback request.error

    request.onupgradeneeded = =>
      @db = request.result  
      for clazz in _supported
        # clean existing database @db.deleteObjectStore clazz.name.toLowerCase()
        @db.createObjectStore clazz.name.toLowerCase()

  # Check the existence of a given key.
  #
  # @param key [String] searched key
  # @param clazz [Base] model class of the searched key
  # @param callback [Function] end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no error occured
  # @option callback exists [Boolean] true if the key exists, false otherwise
  has: (key, clazz, callback) =>
    return callback new Error "unsupported model class #{clazz?.name}" unless clazz in _supported
    return callback new Error "no key provided" unless _.isString key
    
    # opens datbase before if needed
    @_runOrOpen =>
      storeName = clazz.name.toLowerCase()
      # opens a read-only transaction
      tx = @db.transaction [storeName]

      # count number of object with this key (may be 0 or 1)
      request = tx.objectStore(storeName).count key

      # handle errors and success
      tx.onerror = -> callback tx.error
      tx.oncomplete = -> callback null, request.result isnt 0
    , callback

  # Store a model under a given key.
  #
  # @param model [Base] the stored model
  # @param callback [Function] end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no error occured
  add: (model, callback) =>
    return callback new Error "no model provided" unless model?
    unless model.constructor in _supported
      return callback new Error "unsupported model class #{model.constructor?.name}" 
    
    # opens datbase before if needed
    @_runOrOpen =>
      storeName = model.constructor.name.toLowerCase()
      # opens a read-write transaction
      tx = @db.transaction [storeName], 'readwrite'
      
      # set the value for a given key
      request = tx.objectStore(storeName).put model.toJSON(), model.id

      # handle errors and success
      tx.onerror = -> callback tx.error
      tx.oncomplete = -> callback null
    , callback

  # Retrieve a model from its key.
  #
  # @param key [String] searched key
  # @param clazz [Base] model class of the searched key
  # @param callback [Function] end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no error occured
  # @option callback obj [Object] the corresponding stored object, or undefined
  get: (key, clazz, callback) =>
    return callback new Error "unsupported model class #{clazz?.name}" unless clazz in _supported
    return callback new Error "no key provided" unless _.isString key

    # opens datbase before if needed
    @_runOrOpen =>
      storeName = clazz.name.toLowerCase()
      # opens a read-only transaction
      tx = @db.transaction [storeName]
      
      # get the value of a given key
      request = tx.objectStore(storeName).get key

      # handle errors and success
      tx.onerror = -> callback tx.error
      tx.oncomplete = -> 
        return callback new Error "model #{storeName} with key '#{key}' not found" unless request.result?
        callback null, new clazz request.result
    , callback

  # Goes to the whole list of models, ordered by key.
  # Object callback is invoked has many times has their is a model to retrieved, and you must
  # invoked the next() method to access to next model.
  # You can stop the traversal by adding a true parameter to the next method.
  #
  # @param clazz [Base] model class of the searched key
  # @param modelCallback [Function] end callback, invoked with arguments:
  # @option modelCallback model [Base] the current model object
  # @option modelCallback next [Function] function to invoke to go to next model, with true as first parameter to stop.
  # @param callback [Function] end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no error occured
  walk: (clazz, modelCallback, callback) =>
    return callback new Error "unsupported model class #{clazz?.name}" unless clazz in _supported

    # opens datbase before if needed
    @_runOrOpen =>
      storeName = clazz.name.toLowerCase()
      # opens a read-only transaction on the store
      tx = @db.transaction([storeName])
      
      # use a cursor to walk on all models
      tx.objectStore(storeName).openCursor().onsuccess = (event) ->
        cursor = event.target.result
        # no more model
        return callback null unless cursor?
        # invoke callback for each model
        modelCallback new clazz(cursor.value), (quit) ->
          # abord walk
          return callback null if quit
          cursor.continue();

      # handle errors
      tx.onerror = -> callback tx.error
    , callback

  # Removed a model.
  #
  # @param model [Base] the stored model
  # @param callback [Function] end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no error occured
  remove: (model, callback) =>
    return callback new Error "no model provided" unless model?
    unless model.constructor in _supported
      return callback new Error "unsupported model class #{model.constructor?.name}" 

    # opens datbase before if needed
    @_runOrOpen =>
      storeName = model.constructor.name.toLowerCase()
      # opens a read-only transaction
      tx = @db.transaction [storeName], 'readwrite'
      
      # get the value of a given key
      request = tx.objectStore(storeName).delete model.id

      # handle errors and success
      tx.onerror = -> callback tx.error
      tx.oncomplete = -> callback null
    , callback

  # Removed all models of a given class.
  #
  # @param clazz [Base] model class of the removed models
  # @param callback [Function] end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no error occured
  removeAll: (clazz, callback) =>
    return callback new Error "unsupported model class #{clazz?.name}" unless clazz in _supported

    # opens datbase before if needed
    @_runOrOpen =>
      storeName = clazz.name.toLowerCase()
      # opens a read-only transaction
      try 
        tx = @db.transaction [storeName], 'readwrite'
      catch err
        return callback if err?.name is 'NotFoundError' then null else err

      # get the value of a given key
      request = tx.objectStore(storeName).clear()

      # handle errors and success
      tx.onerror = -> callback tx.error
      tx.oncomplete = -> callback null
    , callback