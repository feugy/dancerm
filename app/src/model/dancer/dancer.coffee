define [
  'underscore'
  'moment'
  '../base'
  './address'
  './registration'
  '../../util/common'
], (_, moment, Base, Address, Registration, {generateId}) ->

  class Dancer extends Base

    # In-memory cache, updated by finders. 
    @_cache = {}

    # **static**
    # Find a list of models from the storage provider that have been registered for a given dance class
    #
    # @param id [String] the searched dance class id
    # @param callback [Function] end callback, invoked with:
    # @option callback err [Error] an error object, or null if no problem occured
    # @option callback dancers [Array<Dancer>] array (that may be empty) of registered dancers for this class
    @findByClass: (id, callback) =>
      @findAll (err, dancers) =>
        return callback err if err?
        # filter dancers by registrations
        callback null, _.filter dancers, (dancer) ->
          # looks for the first registration that contains the class
          _.some dancer.registrations, (registration) -> _.contains registration.danceClassIds, id

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

    # how the dancers has known the school: leaflets, website, pagejaunesFr, searchEngine, directory, biennialAssociations, mouth, other
    knownBy: []

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
        knownBy: []
      # fill attributes
      super(raw)
      # enrich object attributes
      @created = moment @created
      @birth = moment @birth
      @address = new Address @address if @address?
      @registrations = (new Registration raw for raw in @registrations when raw?)