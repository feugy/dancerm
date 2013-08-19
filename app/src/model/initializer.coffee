define [
  'underscore'
  'moment'
  './planning/planning'
], (_, moment, Planning) ->

  initialization = (storage) =>

    initialized = false

    storage.walk  Planning, (planning, next) ->
      # there is amodel: quit now
      initialized = true
      next true
    , (err) ->
      # quit if error is found or if already initialized
      throw err if err?
      return if initialized
      console.info 'Initialize with 2013 planning...'
      # create a planning for year 2013
      planning = new Planning
        year: 2013
        danceClasses: [
          {kind: 'Toutes danses', color:'color1', level: 'débutant', start: 'Wed 19:45', end: 'Wed 20:45', hall: 'Gratte-ciel 2'}
          {kind: 'Toutes danses', color:'color1', level: 'intermédiaire', start: 'Thu 20:00', end: 'Thu 21:00', hall: 'Gratte-ciel 1'}
          {kind: 'Toutes danses', color:'color1', level: 'confirmé', start: 'Mon 20:30', end: 'Mon 21:30', hall: 'Gratte-ciel 2'}
          {kind: 'Toutes danses', color:'color1', level: 'avancé', start: 'Mon 19:30', end: 'Mon 20:30', hall: 'Gratte-ciel 2'}

          {kind: 'Rock/Salsa', color:'color2', level: 'débutant', start: 'Tue 21:00', end: 'Tue 22:00', hall: 'Gratte-ciel 1'}
          {kind: 'Rock/Salsa', color:'color2', level: 'intermédiaire', start: 'Wed 20:45', end: 'Wed 21:45', hall: 'Gratte-ciel 2'}
          {kind: 'Rock/Salsa', color:'color2', level: 'confirmé', start: 'Mon 20:00', end: 'Mon 21:30', hall: 'Croix-Luizet'}

          {kind: 'Salsa/Bachata', color:'color3', level: '1', start: 'Tue 21:00', end: 'Tue 22:00', hall: 'Croix-Luizet'}

          {kind: "Modern'Jazz", color:'color4', level: '1/2', start: 'Mon 19:30', end: 'Mon 20:30', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '3', start: 'Wed 19:30', end: 'Wed 20:45', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '4', start: 'Mon 20:30', end: 'Mon 22:00', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: 'avancé', start: 'Wed 20:45', end: 'Wed 21:45', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '-9 ans', start: 'Wed 13:30', end: 'Wed 14:30', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '-11 ans', start: 'Wed 14:30', end: 'Wed 15:30', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '-13 ans', start: 'Wed 15:30', end: 'Wed 16:30', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '1/2 ados', start: 'Wed 18:30', end: 'Wed 19:30', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '2/3 ados', start: 'Wed 16:30', end: 'Wed 17:30', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: '4 ados', start: 'Wed 17:30', end: 'Wed 18:30', hall: 'Gratte-ciel 1'}
          {kind: "Modern'Jazz", color:'color4', level: 'cours technique', start: 'Mon 18:30', end: 'Mon 19:30', hall: 'Gratte-ciel 2'}

          {kind: 'Zumba', color:'color5', start: 'Mon 18:30', end: 'Mon 19:30', hall: 'Gratte-ciel 1'}
          {kind: 'Zumba', color:'color5', start: 'Tue 12:15', end: 'Tue 13:15', hall: 'Gratte-ciel 1'}
          {kind: 'Zumba', color:'color5', start: 'Tue 19:45', end: 'Tue 20:45', hall: 'Gratte-ciel 1'}
          {kind: 'Zumba', color:'color5', start: 'Wed 18:30', end: 'Wed 19:30', hall: 'Gratte-ciel 1'}

          {kind: 'Hip Hop', color:'color6', level: '1 8/12 ans', start: 'Tue 17:30', end: 'Tue 18:30', hall: 'Gratte-ciel 2'}
          {kind: 'Hip Hop', color:'color6', level: '1 ados', start: 'Tue 18:30', end: 'Tue 19:30', hall: 'Gratte-ciel 2'}
          {kind: 'Hip Hop', color:'color6', level: 'ados/adultes', start: 'Tue 19:30', end: 'Tue 20:30', hall: 'Gratte-ciel 2'}

          {kind: 'Ragga', color:'color6', level: '1', start: 'Tue 20:30', end: 'Tue 21:30', hall: 'Gratte-ciel 2'}

          {kind: 'Initiation', color:'color1', level: '4/5 ans', start: 'Wed 13:30', end: 'Wed 14:30', hall: 'Gratte-ciel 2'}
          {kind: 'Initiation', color:'color1', level: '6/7 ans', start: 'Wed 15:30', end: 'Wed 16:30', hall: 'Gratte-ciel 2'}
          {kind: 'Initiation', color:'color1', level: '-7 ans', start: 'Mon 17:00', end: 'Mon 17:45', hall: 'Gratte-ciel 1'}

          {kind: 'Danse sportive/Rock/Salsa', color:'color2', level: '1 8/12 ans', start: 'Wed 16:30', end: 'Wed 17:30', hall: 'Gratte-ciel 2'}
          {kind: 'Danse sportive/Rock/Salsa', color:'color2', level: '2 8/12 ans', start: 'Wed 17:30', end: 'Wed 18:30', hall: 'Gratte-ciel 2'}
          {kind: 'Danse sportive/Rock/Salsa', color:'color2', level: 'avancé', start: 'Wed 14:30', end: 'Wed 15:30', hall: 'Gratte-ciel 2'}
          {kind: 'Danse sportive/Rock/Salsa', color:'color2', level: 'danse sportive', start: 'Fri 17:30', end: 'Fri 18:30', hall: 'Gratte-ciel 1'}
        ]
      storage.add planning, (err) ->
        # throw error
        throw "Failed to initialize planning: #{err.message}" if err?
        console.info 'Initialize finished !'