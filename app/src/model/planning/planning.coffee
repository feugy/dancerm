_ = require 'underscore'
moment = require 'moment'
Persisted = require '../persisted'
DanceClass = require './danceclass'

# A planning embed dance classes for a given season
module.exports = class Planning extends Persisted

  season: ''

  # list of dance classes
  danceClasses: []

  # Creates a planning from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this planning
  constructor: (raw = {}) ->
    now = moment()
    year = if now.month() >= 7 then now.year() else now.year()-1
    # set default values
    _.defaults raw, 
      season: "#{year}/#{year+1}"
      danceClasses: []
    # fill attributes
    super(raw)
    # enrich object attributes
    @danceClasses = (new DanceClass raw for raw in @danceClasses when raw?)