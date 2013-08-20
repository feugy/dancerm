define [
  'underscore'
  '../base'
  './danceclass'
  '../../util/common'
], (_, Base, DanceClass,{generateId}) ->

  # A planning embed dance classes for a given year
  class Planning extends Base

    # In-memory cache, updated by finders. 
    @_cache = {}
    
    id: null

    year: 2013

    # list of dance classes
    danceClasses: []

    # Creates a planning from a set of raw JSON arguments
    #
    # @param raw [Object] raw attributes of this planning
    constructor: (raw = {}) ->
      # set default values
      _.defaults raw, 
        id: generateId()
        year: 2013
        danceClasses: []
      # fill attributes
      super(raw)
      # enrich object attributes
      @danceClasses = (new DanceClass raw for raw in @danceClasses when raw?)