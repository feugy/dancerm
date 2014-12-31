_ = require 'lodash'
async = require 'async'
Db = require 'nedb'
{join} = require 'path'
{ensureFile} = require 'fs-extra'
{getDbPath} = require '../../util/common'

plannings = [{
  season: '2013/2014'
  classes: [
    {kind:'Toutes danses', color:'color1', level:'débutant', start:'Wed 19:45', end:'Wed 20:45', teacher:'Michelle', hall:'Gratte-ciel 2', _id:'abe3737ddd7c'}
    {kind:'Toutes danses', color:'color1', level:'intermédiaire', start:'Thu 20:00', end:'Thu 21:00', teacher:'Michelle', hall:'Gratte-ciel 2', _id:'ece5997a5b20'}
    {kind:'Toutes danses', color:'color1', level:'confirmé', start:'Mon 20:30', end:'Mon 21:30', teacher:'Michelle', hall:'Gratte-ciel 2', _id:'3a5919fbf7d1'}
    {kind:'Toutes danses', color:'color1', level:'avancé', start:'Mon 19:30', end:'Mon 20:30', teacher:'Michelle', hall:'Gratte-ciel 2', _id:'f215f9e925c3'}
    
    {kind:'Rock/Salsa', color:'color2', level:'débutant', start:'Tue 21:00', end:'Tue 22:00', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'b02afe6e235b'}
    {kind:'Rock/Salsa', color:'color2', level:'intermédiaire', start:'Wed 20:45', end:'Wed 21:45', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'a3eebdcc8649'}
    {kind:'Rock/Salsa', color:'color2', level:'confirmé', start:'Mon 20:00', end:'Mon 21:30', teacher:'Anthony', hall:'Croix-Luizet', _id:'57e822351776'}
    
    {kind:'Salsa/Bachata', color:'color2', level:'1', start:'Thu 21:00', end:'Thu 22:00', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'25cbbf4cf68f'}
    
    {kind:"Modern'Jazz", color:'color4', level:'1/2', start:'Mon 19:30', end:'Mon 20:30', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'66b8d781e50a'}
    {kind:"Modern'Jazz", color:'color4', level:'3', start:'Wed 19:30', end:'Wed 20:45', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'bfd5121e5388'}
    {kind:"Modern'Jazz", color:'color4', level:'4', start:'Mon 20:30', end:'Mon 22:00', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'6379b6d075d2'}
    {kind:"Modern'Jazz", color:'color4', level:'avancé', start:'Wed 20:45', end:'Wed 21:45', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'4677c7ca05fb'}
    {kind:"Modern'Jazz", color:'color4', level:'-9 ans', start:'Wed 13:30', end:'Wed 14:30', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'467eef89cffc'}
    {kind:"Modern'Jazz", color:'color4', level:'-11 ans', start:'Wed 14:30', end:'Wed 15:30', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'c47f511123c2'}
    {kind:"Modern'Jazz", color:'color4', level:'-13 ans', start:'Wed 15:30', end:'Wed 16:30', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'c6f23ef20e77'}
    {kind:"Modern'Jazz", color:'color4', level:'1/2 ados', start:'Wed 18:30', end:'Wed 19:30', teacher:'Delphine', hall:'Gratte-ciel 2', _id:'5a4d79ade0fd'}
    {kind:"Modern'Jazz", color:'color4', level:'2/3 ados', start:'Wed 16:30', end:'Wed 17:30', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'b9323ca19998'}
    {kind:"Modern'Jazz", color:'color4', level:'4 ados', start:'Wed 17:30', end:'Wed 18:30', teacher:'Delphine', hall:'Gratte-ciel 1', _id:'dd47b37d5aa2'}
    {kind:"Modern'Jazz", color:'color4', level:'cours technique', start:'Mon 18:30', end:'Mon 19:30', teacher:'Delphine', hall:'Gratte-ciel 2', _id:'540ccbdfbc0a'}
    
    {kind:'Zumba', color:'color5', level:'', start:'Mon 18:30', end:'Mon 19:30', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'09f73e6a4506'}
    {kind:'Zumba', color:'color5', level:'', start:'Tue 12:15', end:'Tue 13:15', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'55f6fce3ed5d'}
    {kind:'Zumba', color:'color5', level:'', start:'Tue 19:45', end:'Tue 20:45', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'6858081797f8'}
    {kind:'Zumba', color:'color5', level:'', start:'Wed 18:30', end:'Wed 19:30', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'06771b926603'}
    {kind:'Zumbatomic', color:'color5', level:'4/7 ans', start:'Thu 17:00', end:'Thu 17:45', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'5f25e35e0aab'}
    {kind:'Zumbatomic', color:'color5', level:'7/12 ans', start:'Mon 17:45', end:'Mon 18:30', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'cf66102bbe74'}
    
    {kind:'Hip Hop', color:'color6', level:'1 8/12 ans', start:'Tue 17:30', end:'Tue 18:30', teacher:'Nassim', hall:'Gratte-ciel 2', _id:'6268f4c4ceee'}
    {kind:'Hip Hop', color:'color6', level:'1 ados', start:'Tue 18:30', end:'Tue 19:30', teacher:'Nassim', hall:'Gratte-ciel 2', _id:'d4734dd32cc8'}
    {kind:'Hip Hop', color:'color6', level:'ados/adultes', start:'Tue 19:30', end:'Tue 20:30', teacher:'Nassim', hall:'Gratte-ciel 2', _id:'ebea741a1ef3'}
    {kind:'Ragga', color:'color6', level:'1', start:'Tue 20:30', end:'Tue 21:30', teacher:'Nassim', hall:'Gratte-ciel 2', _id:'9ae1afa1d206'}
    
    {kind:'Initiation', color:'color1', level:'4/5 ans', start:'Wed 13:30', end:'Wed 14:30', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'e6d878ade208'}
    {kind:'Initiation', color:'color1', level:'6/7 ans', start:'Wed 15:30', end:'Wed 16:30', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'6aa456a8788a'}
    {kind:'Initiation', color:'color1', level:'-7 ans', start:'Mon 17:00', end:'Mon 17:45', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'049adf9efa5c'}
    
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'avancé', start:'Wed 14:30', end:'Wed 15:30', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'a083cf8d7e63'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'danse sportive', start:'Fri 17:30', end:'Fri 18:30', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'ba80af6c8352'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'1 8/12 ans', start:'Wed 16:30', end:'Wed 17:30', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'f80ec0cbc65c'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'2 8/12 ans', start:'Wed 17:30', end:'Wed 18:30', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'53b8f5097d9b'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'compétiteurs latine', start:'Tue 20:30', end:'Tue 22:00', teacher:'Anthony', hall:'Croix-Luizet', _id:'1152f080e034'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'compétiteurs standard', start:'Thu 20:30', end:'Thu 22:00', teacher:'Anthony', hall:'Gratte-ciel 1', _id:'3b2ecc05e3d0'}
  ]
}, {
  season: '2014/2015'
  classes: [
    {kind:'Toutes danses', color:'color1', level:'1', start:'Mon 19:30', end:'Mon 20:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'23bd6bc9a646'}
    {kind:'Toutes danses', color:'color1', level:'2', start:'Tue 20:30', end:'Tue 21:30', teacher:'Anthony', hall:'Gratte-ciel 1',  _id:'45646849a5db'}
    
    {kind:'Rock/Salsa', color:'color2', level:'1', start:'Wed 20:00', end:'Wed 21:00', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'48ec486a84c0'}
    {kind:'Rock/Salsa', color:'color2', level:'2', start:'Mon 20:30', end:'Mon 21:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'7d49bc92d150'}
    {kind:'Rock/Salsa', color:'color2', level:'3', start:'Wed 21:00', end:'Wed 22:00', teacher:'Anthony', hall:'Gratte-ciel 1',  _id:'2824879c9eb6'}
    
    {kind:'Zumbakid', color:'color5', level:'4/6 ans', start:'Tue 17:00', end:'Tue 17:45', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'bf96faf21257'}
    {kind:'Zumbakid', color:'color5', level:'7/10 ans', start:'Mon 17:45', end:'Mon 18:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'4eea31d6e380'}
    {kind:'Zumbakid', color:'color5', level:'11/14 ans', start:'Tue 17:45', end:'Tue 18:30', teacher:'Anthony', hall:'Gratte-ciel 1',  _id:'b81ec58a3966'}
    
    {kind:'Zumba', color:'color5', level:'ados/adultes', start:'Wed 18:30', end:'Wed 19:30', teacher:'Anthony', hall:'Gratte-ciel 1',  _id:'c509982bd5d4'}
    {kind:'Zumba', color:'color5', level:'adultes', start:'Tue 19:30', end:'Tue 20:30', teacher:'Anthony', hall:'Gratte-ciel 1',  _id:'ea0105f91440'}
     
    {kind:'Salsa/Bachata', color:'color2', level:'1', start:'Thu 20:00', end:'Thu 21:00', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'f76f713ed555'}
    {kind:'Salsa/Bachata', color:'color2', level:'2', start:'Thu 21:00', end:'Thu 22:00', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'7a044e04cc9e'}
    
    {kind:"Modern'Jazz", color:'color4', level:'1/2', start:'Mon 19:30', end:'Mon 20:30', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'2b859f34b2b6'}
    {kind:"Modern'Jazz", color:'color4', level:'3', start:'Wed 19:30', end:'Wed 21:00', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'9a428103694b'}
    {kind:"Modern'Jazz", color:'color4', level:'4', start:'Mon 20:30', end:'Mon 22:00', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'1ed0757bc24e'}
    {kind:"Modern'Jazz", color:'color4', level:'atelier choré.', start:'Wed 21:00', end:'Wed 22:00', teacher:'Delphine', hall:'Gratte-ciel 2',  _id:'25d6c7eb2fa4'}
    {kind:"Modern'Jazz", color:'color4', level:'-9 ans', start:'Wed 13:30', end:'Wed 14:30', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'994a9ccc4ae0'}
    {kind:"Modern'Jazz", color:'color4', level:'-11 ans', start:'Wed 14:30', end:'Wed 15:30', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'ff5f3a165b80'}
    {kind:"Modern'Jazz", color:'color4', level:'1 ados', start:'Wed 18:30', end:'Wed 19:30', teacher:'Delphine', hall:'Gratte-ciel 2',  _id:'91abd4e9f19f'}
    {kind:"Modern'Jazz", color:'color4', level:'2 11/15 ans', start:'Wed 15:30', end:'Wed 16:30', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'82ff504f1193'}
    {kind:"Modern'Jazz", color:'color4', level:'3 11/15 ans', start:'Wed 16:30', end:'Wed 17:30', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'efbc1f704078'}
    {kind:"Modern'Jazz", color:'color4', level:'4 ados', start:'Wed 17:30', end:'Wed 18:30', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'5446c314f250'}
    {kind:"Modern'Jazz", color:'color4', level:'cours technique', start:'Mon 18:30', end:'Mon 19:30', teacher:'Delphine', hall:'Gratte-ciel 1',  _id:'6c04a88a6c34'}
    
    {kind:'Hip Hop', color:'color6', level:'1 8/12 ans', start:'Tue 17:45', end:'Tue 18:30', teacher:'Nassim', hall:'Gratte-ciel 2',  _id:'55f6c8a4bbc9'}
    {kind:'Hip Hop', color:'color6', level:'1 ados', start:'Tue 18:30', end:'Tue 19:30', teacher:'Nassim', hall:'Gratte-ciel 2',  _id:'d6008abd6d00'}
    {kind:'Hip Hop', color:'color6', level:'2 ados', start:'Tue 19:30', end:'Tue 20:30', teacher:'Nassim', hall:'Gratte-ciel 2',  _id:'6e25ba22d5f2'}
    {kind:'Hip Hop', color:'color6', level:'ados/adultes', start:'Tue 19:30', end:'Tue 20:30', teacher:'Nassim', hall:'Gratte-ciel 2',  _id:'c883032ac42f'}
    {kind:'Ragga', color:'color6', level:'adultes', start:'Tue 20:30', end:'Tue 21:30', teacher:'Nassim', hall:'Gratte-ciel 2',  _id:'decb4a059471'}
    
    {kind:'Initiation', color:'color1', level:'4/5 ans', start:'Wed 13:30', end:'Wed 14:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'bf7d39a62adc'}
    {kind:'Initiation', color:'color1', level:'5/7 ans', start:'Mon 17:00', end:'Mon 17:45', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'d211bb4b7605'}
    {kind:'Initiation', color:'color1', level:'6/7 ans', start:'Wed 14:30', end:'Wed 15:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'179dfd2f98af'}
    
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'1 8/12 ans', start:'Wed 16:30', end:'Wed 17:30', teacher:'Anthony', hall:'Gratte-ciel 2', _id:'0249f2c4b254'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'2', start:'Wed 17:30', end:'Wed 18:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'bd5638194d79'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'avancé', start:'Wed 15:30', end:'Wed 16:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'6993e582e1a0'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'danse sportive', start:'Fri 17:30', end:'Fri 18:30', teacher:'Anthony', hall:'Gratte-ciel 2',  _id:'89b1ca336a50'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'compétiteurs latine', start:'Tue 20:30', end:'Tue 22:00', teacher:'Anthony', hall:'Croix-Luizet',  _id:'6f77eb96fb09'}
    {kind:'Danse sportive/Rock/Salsa', color:'color3', level:'compétiteurs standard', start:'Thu 20:30', end:'Thu 22:00', teacher:'Anthony', hall:'Gratte-ciel 1',  _id:'e1e9fae49e84'}
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
  DanceClass = require('../dance_class')
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

merged = false

module.exports = 

  # Database initialization function
  # Allow to initialize storage with a 2013 and 2014 planning.
  # Ineffective if some plannings are already present.
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  init: (done) ->
    return done() if merged
    merged = true
    # update planning for seasons
    async.each plannings, (planning, next) ->
      mergePlanning planning, next
    , done