define [
  'underscore'
  './base'
], (_, Base) ->

  class Address extends Base

    # address detailed attributes
    street: ''
    zipcode: 0
    city: ''

    # Creates an address from a set of raw JSON arguments
    #
    # @param raw [Object] raw attributes of this address
    constructor: (raw = {}) ->
      # set default values
      _.defaults raw, 
        street: ''
        zipcode: 0
        city: ''
      # fill attributes
      super(raw)