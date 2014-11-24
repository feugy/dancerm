_ = require 'lodash'
Persisted = require './tools/persisted'
{getCollection} = require './tools/initializer'

# ordered week days
days = 
  mon: 0
  tue: 1
  wed: 2 
  thu: 3 
  fri: 4 
  sat: 5 
  sun: 6

module.exports = class DanceClass extends Persisted

  # corresponding season
  season: '' 

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
  teacher: null
  hall: null

  # Creates a dance class from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this dance class
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw, 
      season: ''
      kind: ''
      color: 'color1'
      level: ''
      start: 'Mon 08:00'
      end: 'Mon 09:00'
      teacher: null
      hall: null
    # fill attributes
    super(raw)

  # List existing seasons, and returns them ordered (alphabetically)
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done danceClasses [Array<DanceClass>] ordered list (that may be empty) of dance classes for this season
  @listSeasons: (done) ->
    getCollection(@name).find {}, (err, classes) =>
      return done err if err?
      done null, _.chain(classes).pluck('season').uniq().value().sort().reverse()

  # Get the list of available teachers within a given season
  #
  # @param season [String] the concerned season
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done teachers [Array<String>] ordered list (that may be empty) of teachers for this season
  @getTeachers: (season, done) ->
    @getPlanning season, (err, planning) =>
      return done err if err?
      done null, _.chain(planning).pluck('teacher').uniq().compact().value().sort()

  # Get the list of classes of a given season, named planning
  # 
  # @param season [String] the searched season
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  # @option done danceClasses [Array<DanceClass>] ordered list (that may be empty) of dance classes for this season
  @getPlanning: (season, done) ->
    @findWhere season: season, (err, classes) =>
      return done err if err?
      # sort dance classes by day, hour and quarters
      done null, classes.sort (a, b) ->
        return -1 unless a.start?
        return 1 unless b.start?
        aDay = a.start[0..2]
        aHour = parseInt a.start.replace aDay, ''
        aQuarter = parseInt a.start[a.start.indexOf(':')+1..]
        bDay = b.start[0..2]
        bHour = parseInt b.start.replace bDay, ''
        bQuarter = parseInt b.start[b.start.indexOf(':')+1..]
        aDay = aDay.toLowerCase()
        bDay = bDay.toLowerCase()
        if days[aDay] < days[bDay] then -1 else if days[aDay] > days[bDay] then 1 else
          if aHour < bHour then -1 else if aHour > bHour then 1 else
            if aQuarter < bQuarter then -1 else if aQuarter > bQuarter then 1 else 0