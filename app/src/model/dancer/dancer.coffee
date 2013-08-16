define [
  'underscore'
  'moment'
  '../base'
  './address'
  './registration'
  '../../util/common'
], (_, moment, Base, Address, Registration, {generateId}) ->

  class Dancer extends Base

    id: null

    created: null

    # Dancer title (M. Mme Mlle) and name
    title: 'Mme'
    firstname: ''
    lastname: ''

    # Use a subobject to store address
    address: null

    # contact
    phone: null
    email: null

    birth: null

    # has or not a medical certificate for the current year
    certified: false

    # list of registration for given dance classes
    registrations: []

    # Creates a dancer from a set of raw JSON arguments
    # Default values will be applied, and only declared arguments are used
    #
    # @param raw [Object] raw attributes of this dancer
    constructor: (raw = {}) ->
      # set default values
      _.defaults raw, 
        id: generateId()
        created: moment()
        title: 'Mme'
        firstname: ''
        lastname: ''
        address: null
        phone: null
        email: null
        certified: false
        registrations: []
      # fill attributes
      super(raw)
      # enrich object attributes
      @created = moment @created
      @birth = moment @birth
      @address = new Address @address if @address?
      @registrations = (new Registration raw for raw in @registrations when raw?)