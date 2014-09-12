_ = require 'underscore'
moment = require 'moment'
async = require 'async'
DanceClass = require '../danceclass'

# Allow to initialize storage with a 2013 planning.
# Inefective if some plannings are already present.
#
# @return a promise without a boolean argument which is true if the planning was initialized, false if some models are already present
module.exports = () ->
  # update planning for season 2014/2015
  currentSeason = '2014/2015'
  DanceClass.getPlanning(currentSeason).then((danceClasses) ->
    new Promise (resolve, reject) ->
      old = _.invoke danceClasses, 'toJSON'

      newClasses = [
        {kind: 'Toutes danses', color:'color1', level: '1', start: 'Mon 19:30', end: 'Mon 20:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Toutes danses', color:'color1', level: '2', start: 'Tue 20:30', end: 'Tue 21:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        
        {kind: 'Rock/Salsa', color:'color2', level: '1', start: 'Wed 20:00', end: 'Wed 21:00', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Rock/Salsa', color:'color2', level: '2', start: 'Mon 20:30', end: 'Mon 21:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Rock/Salsa', color:'color2', level: '3', start: 'Wed 21:00', end: 'Wed 22:00', hall: 'Gratte-ciel 1', teacher: 'Anthony'}

        {kind: 'Zumba', color:'color5', level: 'ados/adultes', start: 'Wed 18:30', end: 'Wed 19:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        {kind: 'Zumba', color:'color5', level: 'adultes', start: 'Tue 19:30', end: 'Tue 20:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        
        {kind: 'Salsa/Bachata', color:'color2', level: '1', start: 'Thu 20:00', end: 'Thu 21:00', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Salsa/Bachata', color:'color2', level: '2', start: 'Thu 21:00', end: 'Thu 22:00', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        
        {kind: "Modern'Jazz", color:'color4', level: '1/2', start: 'Mon 19:30', end: 'Mon 20:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '3', start: 'Wed 19:30', end: 'Wed 21:00', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '4', start: 'Mon 20:30', end: 'Mon 22:00', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: 'atelier choré.', start: 'Wed 21:00', end: 'Wed 22:00', hall: 'Gratte-ciel 2', teacher: 'Delphine'}
        
        {kind: 'Hip Hop', color:'color6', level: 'ados/adultes', start: 'Tue 19:30', end: 'Tue 20:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}

        {kind: 'Ragga', color:'color6', level: 'adultes', start: 'Tue 20:30', end: 'Tue 21:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}

        {kind: 'Initiation', color:'color1', level: '4/5 ans', start: 'Wed 13:30', end: 'Wed 14:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Initiation', color:'color1', level: '6/7 ans', start: 'Wed 14:30', end: 'Wed 15:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Initiation', color:'color1', level: '5/7 ans', start: 'Mon 17:00', end: 'Mon 17:45', hall: 'Gratte-ciel 2', teacher: 'Anthony'}

        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: '1 8/12 ans', start: 'Wed 16:30', end: 'Wed 17:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: '2', start: 'Wed 17:30', end: 'Wed 18:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'avancé', start: 'Wed 15:30', end: 'Wed 16:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'danse sportive', start: 'Fri 17:30', end: 'Fri 18:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'compétiteurs latine', start: 'Tue 20:30', end: 'Tue 22:00', hall: 'Croix-Luizet', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'compétiteurs standard', start: 'Thu 20:30', end: 'Thu 22:00', hall: 'Gratte-ciel 1', teacher: 'Anthony'}

        {kind: 'Zumbakid', color:'color5', level:'4/6 ans', start: 'Tue 17:00', end: 'Tue 17:45', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Zumbakid', color:'color5', level:'7/10 ans', start: 'Mon 17:45', end: 'Mon 18:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Zumbakid', color:'color5', level:'11/14 ans', start: 'Tue 17:45', end: 'Tue 18:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}

        {kind: "Modern'Jazz", color:'color4', level: '-9 ans', start: 'Wed 13:30', end: 'Wed 14:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '-11 ans', start: 'Wed 14:30', end: 'Wed 15:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '2 11/15 ans', start: 'Wed 15:30', end: 'Wed 16:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '3 11/15 ans', start: 'Wed 16:30', end: 'Wed 17:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '4 ados', start: 'Wed 17:30', end: 'Wed 18:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '1 ados', start: 'Wed 18:30', end: 'Wed 19:30', hall: 'Gratte-ciel 2', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: 'cours technique', start: 'Mon 18:30', end: 'Mon 19:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        
        {kind: 'Hip Hop', color:'color6', level: '1 8/12 ans', start: 'Tue 17:45', end: 'Tue 18:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}
        {kind: 'Hip Hop', color:'color6', level: '1 ados', start: 'Tue 18:30', end: 'Tue 19:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}
        {kind: 'Hip Hop', color:'color6', level: '2 ados', start: 'Tue 19:30', end: 'Tue 20:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}
      ]

      # merge with existing classes, and add new ones
      for newClass in newClasses
        conditions = kind: newClass.kind
        if newClass.level?
          conditions.level = newClass.level
        else
          conditions.start = newClass.start
        existing = _.findWhere danceClasses, conditions
        if existing?
          _.extend existing, newClass 
        else
          danceClasses.push new DanceClass _.extend {season: currentSeason}, newClass

      # removes old ones
      toRemove = (danceClass for danceClass in danceClasses when not _.findWhere(newClasses, kind: danceClass.kind, start: danceClass.start)?)
      danceClasses = _.difference danceClasses, toRemove

      return resolve false if _.isEqual old, _.invoke danceClasses, 'toJSON'
      async.each danceClasses, (danceClass, next) ->
        danceClass.save().then(-> next()).catch next
      , (err) ->
        return reject new Error "Failed to initialize planning: #{err.message}" if err?
        resolve true
  ).catch (err) ->
    console.error err