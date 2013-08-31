_ = require 'underscore'
_hexa = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

module.exports = 

	# Generate a random id containing 12 characters
	# @return a generated id
	generateId: ->
	  (_hexa[Math.floor Math.random()*_hexa.length] for i in [0...12]).join ''