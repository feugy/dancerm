_ = require 'lodash'
Persisted = require './tools/persisted'

# Store address relative informations, also persisted into separate collection
module.exports = class Address extends Persisted

  # address detailed attributes
  street: ''
  zipcode: 0
  city: ''
  phone: null

  # Creates an address from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this address
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw, 
      street: ''
      zipcode: 69100
      city: ''
      phone: null
    # fill attributes
    super(raw)