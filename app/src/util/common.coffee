_ = require 'underscore'
_hexa = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

module.exports = 

	# Generate a random id containing 12 characters
	# @return a generated id
	generateId: ->
	  (_hexa[Math.floor Math.random()*_hexa.length] for i in [0...12]).join ''

  # Get the attribute value of an object along a given path
  #
  # @param obj [Object] the root object
  # @param path [String] attribute pas, '.' are allowed.
  # @return the corresponding value, if available
  getAttr: (obj, path) ->
    path = path.split '.'
    obj = obj[path[0]]
    # avoid NPE
    return obj unless obj?
    # recurse or quit
    if path.length > 1
      module.exports.getAttr obj, path[1..].join '.'
    else
      obj