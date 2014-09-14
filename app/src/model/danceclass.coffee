_ = require 'underscore'
Persisted = require './tools/persisted'

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
  # @return a promise with the ordered list of seasons as paramter
  @listSeasons: ->
    @_collection().then (collection) =>
      new Promise (resolve, reject) =>
        collection.find {}, (err, classes) =>
          return reject err if err?
          resolve _.chain(classes).pluck('season').uniq().value().sort().reverse()

  # Get the list of available teachers within a given season
  #
  # @param season [String] the concerned season
  # @return a promise with the ordered list (that may be empty) of teachers for this season
  @getTeachers: (season) ->
    @getPlanning(season).then (planning) =>
      _.chain(planning).pluck('teacher').uniq().compact().value().sort()

  # Get the list of classes of a given season, named planning
  # 
  # @param season [String] the searched season
  # @return a promise with the ordered list (that may be empty) of dance classes for this season
  @getPlanning: (season) ->
    @findWhere(season: season).then (classes) =>
      new Promise (resolve, reject) =>
        # sort dance classes by day, hour and quarters
        resolve classes.sort (a, b) ->
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