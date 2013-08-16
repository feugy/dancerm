define [
  'underscore'
  '../base'
  '../../util/common'
], (_, Base, {generateId}) ->

  class DanceClass extends Base

    id: null

    # Dance kind: ballroom, rock, west coast...
    kind: ''

    # css class used to display inside plannings
    color: 'color1'

    # Dance level: 1,2,3, beginers...
    level: ''

    # Start/end hour and day: "ddd HH:mm"
    start: "Mon 08:00"
    end: "Mon 09:00"

    # Dance teacher and dancing hall
    teatcher: null
    hall: null

    # Creates a dance class from a set of raw JSON arguments
    #
    # @param raw [Object] raw attributes of this dance class
    constructor: (raw = {}) ->
      # set default values
      _.defaults raw, 
        id: generateId()
        kind: ''
        color: 'color1'
        level: ''
        start: 'Mon 08:00'
        end: 'Mon 09:00'
        teatcher: null
        hall: null
      # fill attributes
      super(raw)