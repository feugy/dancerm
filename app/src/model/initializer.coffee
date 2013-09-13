_ = require 'underscore'
moment = require 'moment'
Planning = require './planning/planning'
DanceClass = require './planning/danceclass'

# Allow to initialize storage with a 2013 planning.
# Inefective if some plannings are already present.
#
# @param callback [Function] end callback, invoked with argumetns:
# @option callback err [Error] an error object, or null if no error occured
# @option callback initialized [Boolean] true if the planning was initialized, false if some models are already present
module.exports = (callback) =>

    # update planning for season 2013/2014
    Planning.findWhere season:'2013/2014', (err, plannings) ->
      # quit if error is found
      return callback err if err?
      planning = plannings[0] or new Planning()
      old = planning.toJSON()

      newClasses = [
        {kind: 'Toutes danses', color:'color1', level: 'débutant', start: 'Wed 19:45', end: 'Wed 20:45', hall: 'Gratte-ciel 2', teacher: 'Michelle'}
        {kind: 'Toutes danses', color:'color1', level: 'intermédiaire', start: 'Thu 20:00', end: 'Thu 21:00', hall: 'Gratte-ciel 2', teacher: 'Michelle'}
        {kind: 'Toutes danses', color:'color1', level: 'confirmé', start: 'Mon 20:30', end: 'Mon 21:30', hall: 'Gratte-ciel 2', teacher: 'Michelle'}
        {kind: 'Toutes danses', color:'color1', level: 'avancé', start: 'Mon 19:30', end: 'Mon 20:30', hall: 'Gratte-ciel 2', teacher: 'Michelle'}

        {kind: 'Rock/Salsa', color:'color2', level: 'débutant', start: 'Tue 21:00', end: 'Tue 22:00', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        {kind: 'Rock/Salsa', color:'color2', level: 'intermédiaire', start: 'Wed 20:45', end: 'Wed 21:45', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Rock/Salsa', color:'color2', level: 'confirmé', start: 'Mon 20:00', end: 'Mon 21:30', hall: 'Croix-Luizet', teacher: 'Anthony'}

        {kind: 'Salsa/Bachata', color:'color2', level: '1', start: 'Thu 21:00', end: 'Thu 22:00', hall: 'Gratte-ciel 2', teacher: 'Anthony'}

        {kind: "Modern'Jazz", color:'color4', level: '1/2', start: 'Mon 19:30', end: 'Mon 20:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '3', start: 'Wed 19:30', end: 'Wed 20:45', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '4', start: 'Mon 20:30', end: 'Mon 22:00', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: 'avancé', start: 'Wed 20:45', end: 'Wed 21:45', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '-9 ans', start: 'Wed 13:30', end: 'Wed 14:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '-11 ans', start: 'Wed 14:30', end: 'Wed 15:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '-13 ans', start: 'Wed 15:30', end: 'Wed 16:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '1/2 ados', start: 'Wed 18:30', end: 'Wed 19:30', hall: 'Gratte-ciel 2', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '2/3 ados', start: 'Wed 16:30', end: 'Wed 17:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: '4 ados', start: 'Wed 17:30', end: 'Wed 18:30', hall: 'Gratte-ciel 1', teacher: 'Delphine'}
        {kind: "Modern'Jazz", color:'color4', level: 'cours technique', start: 'Mon 18:30', end: 'Mon 19:30', hall: 'Gratte-ciel 2', teacher: 'Delphine'}

        {kind: 'Zumba', color:'color5', start: 'Mon 18:30', end: 'Mon 19:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        {kind: 'Zumba', color:'color5', start: 'Tue 12:15', end: 'Tue 13:15', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        {kind: 'Zumba', color:'color5', start: 'Tue 19:45', end: 'Tue 20:45', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        {kind: 'Zumba', color:'color5', start: 'Wed 18:30', end: 'Wed 19:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        {kind: 'Zumbatomic', color:'color5', level:'7/12 ans', start: 'Mon 17:45', end: 'Mon 18:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
        {kind: 'Zumbatomic', color:'color5', level:'4/7 ans', start: 'Thu 17:00', end: 'Thu 17:45', hall: 'Gratte-ciel 2', teacher: 'Anthony'}

        {kind: 'Hip Hop', color:'color6', level: '1 8/12 ans', start: 'Tue 17:30', end: 'Tue 18:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}
        {kind: 'Hip Hop', color:'color6', level: '1 ados', start: 'Tue 18:30', end: 'Tue 19:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}
        {kind: 'Hip Hop', color:'color6', level: 'ados/adultes', start: 'Tue 19:30', end: 'Tue 20:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}

        {kind: 'Ragga', color:'color6', level: '1', start: 'Tue 20:30', end: 'Tue 21:30', hall: 'Gratte-ciel 2', teacher: 'Nassim'}

        {kind: 'Initiation', color:'color1', level: '4/5 ans', start: 'Wed 13:30', end: 'Wed 14:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Initiation', color:'color1', level: '6/7 ans', start: 'Wed 15:30', end: 'Wed 16:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Initiation', color:'color1', level: '-7 ans', start: 'Mon 17:00', end: 'Mon 17:45', hall: 'Gratte-ciel 2', teacher: 'Anthony'}

        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: '1 8/12 ans', start: 'Wed 16:30', end: 'Wed 17:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: '2 8/12 ans', start: 'Wed 17:30', end: 'Wed 18:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'avancé', start: 'Wed 14:30', end: 'Wed 15:30', hall: 'Gratte-ciel 2', teacher: 'Anthony'}
        {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'danse sportive', start: 'Fri 17:30', end: 'Fri 18:30', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
      ]

      # merge with existing classes, and add new ones
      for newClass in newClasses
        conditions = kind: newClass.kind
        if newClass.level?
          conditions.level = newClass.level
        else
          conditions.start = newClass.start
        existing = _.findWhere planning.danceClasses, conditions
        if existing?
          _.extend existing, newClass 
        else
          planning.danceClasses.push new DanceClass newClass
      # removes old ones
      toRemove = (danceClass for danceClass in planning.danceClasses when not _.findWhere(newClasses, kind: danceClass.kind, start: danceClass.start)?)
      planning.danceClasses = _.difference planning.danceClasses, toRemove

      return callback null, false if _.isEqual old, planning.toJSON()
      planning.save (err) ->
        # throw error
        err = "Failed to initialize planning: #{err.message}" if err?
        callback err, true
