_ = require 'lodash'
moment = require 'moment'
async = require 'async'
Db = require 'nedb'
{join} = require 'path'
{ensureFile} = require 'fs-extra'
{getDbPath} = require '../../util/common'

plannings = [{
  season: '2013/2014'
  classes: [
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
    {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'compétiteurs latine', start: 'Tue 20:30', end: 'Tue 22:00', hall: 'Croix-Luizet', teacher: 'Anthony'}
    {kind: 'Danse sportive/Rock/Salsa', color:'color3', level: 'Compétiteurs standard', start: 'Thu 20:30', end: 'Thu 22:00', hall: 'Gratte-ciel 1', teacher: 'Anthony'}
  ]
}, {
  season: '2014/2015'
  classes: [
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
}]

# Merge existing and expected dance classes of a given planning
#
# @param planning [Object] expected planning with season and classes properties
# @param done [Function] completion callback, invoked with arguments:
# @option done err [Error] an error object or null if no error occured
mergePlanning = (planning, done) ->
  console.log "check planning #{planning.season}"
  # lazy request to avoid circular dependencies between persisted and initializer
  DanceClass = require('../danceclass')
  DanceClass.getPlanning planning.season, (err, danceClasses) ->
    return done err if err?
    old = _.invoke danceClasses, 'toJSON'

    # merge with existing classes, and add new ones
    for newClass in planning.classes
      conditions = kind: newClass.kind
      if newClass.level?
        conditions.level = newClass.level
      else
        conditions.start = newClass.start
      existing = _.findWhere danceClasses, conditions
      if existing?
        _.extend existing, newClass 
      else
        danceClasses.push new DanceClass _.extend {season: planning.season}, newClass

    # removes old ones
    toRemove = (danceClass for danceClass in danceClasses when not _.findWhere(planning.classes, kind: danceClass.kind, start: danceClass.start)?)
    danceClasses = _.difference danceClasses, toRemove

    return done null if _.isEqual old, _.invoke danceClasses, 'toJSON'
    console.log "save #{planning.season} new classes"
    async.each danceClasses, (danceClass, next) -> 
      danceClass.save next
    , done

collections = null

module.exports = 

  # Retreived Unic reference to database collection, once init was called.
  # 
  # @param name [String] expected collection name
  # @return the expected collection object
  # @throw an error if database was not initialized 
  getCollection: (name) -> 
    throw new Error 'database not initialized !' unless collections?
    collections[name]

  # Database initialization function
  # Allow to initialize storage with a 2013 and 2014 planning.
  # Ineffective if some plannings are already present.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  init: (done) ->
    return done() if collections?
    # ensure folder existence
    path = getDbPath()
    ensureFile path, (err) ->
      return done err if err?
      collections = {}
      async.each ['DanceClass', 'Address', 'Dancer', 'Card', 'Tested'], (name, next) ->
        db = new Db filename: join path, name
        db.loadDatabase (err) ->
          return next err if err?
          collections[name] = db
          next()
      , (err) ->
        return done err if err?
        # update planning for seasons
        async.each plannings, (planning, next) ->
          mergePlanning planning, next
        , done