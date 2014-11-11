_ = require 'lodash'
{EventEmitter} = require 'events'

# Abstract base functionnalities of models
module.exports = class Base extends EventEmitter
  
  # transient fields are not serialized into JSON
  @_transient = ['$$hashKey']

  # Creates a model from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  # If an id attribute is not specified, it will be created
  #
  # @param raw [Object] raw attributes of this dancer
  constructor: (raw = {}) ->
    super()
    @setMaxListeners 100
    # only allow awaited attributes
    allowed = (attr for attr, value of @ when not _.isFunction value)
    raw = _.pick.apply _, [raw].concat allowed
    # keep raws values
    @_raw = raw

    # eventually, define properties aiming at raw values
    for attr of @_raw when not(attr in @constructor._transient)
      ((attr) =>
        Object.defineProperty @, attr,
          configurable: true # for subclasses
          get: -> @_raw[attr]
          set: (val) -> 
            @_raw[attr] = val
            @emit 'change', attr, val
      ) attr

  # Returns a json representation of the current model.
  # Also operate on sub models
  #
  # @return raw attribute of the current model
  toJSON: =>
    raw = {}
    for attr, value of @_raw when value isnt undefined and not (attr in @constructor._transient) 
      if _.isArray value
        raw[attr] = []
        for val, i in value
          raw[attr][i] = if val?.toJSON? then val.toJSON() else val
      else
        raw[attr] = if value?.toJSON? then value.toJSON() else if _.isObject value then JSON.parse JSON.stringify value else value
    raw