define [
  'underscore'
], (_) ->

  # Abstract base functionnalities of models
  class Base

    # Creates a model from a set of raw JSON arguments
    # Default values will be applied, and only declared arguments are used
    #
    # @param raw [Object] raw attributes of this dancer
    constructor: (raw = {}) ->
      # only allow awaited attribtues
      allowed = (attr for attr, value of @ when not _.isFunction value)
      raw = _.pick.apply _, [raw].concat allowed

      # finally, copy attributes into current instance
      for attr, value of raw
        @[attr] = value

    # Returns a json representation of the current model.
    # Also operate on sub models
    #
    # @return raw attribute of the current model
    toJSON: =>
      raw = {} 
      for attr, value of @ when not _.isFunction value
        if _.isArray value
          raw[attr] = []
          for val, i in value
            raw[attr][i] = if val?.toJSON? then val.toJSON() else val
        else
          raw[attr] = if value?.toJSON? then value.toJSON() else value
      raw