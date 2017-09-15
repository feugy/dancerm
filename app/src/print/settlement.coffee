_ = require 'lodash'
{map} = require 'async'
{remote} = require 'electron'
windowManager = remote.require 'electron-window-manager'
i18n = require '../script/labels/common'
Dancer = require '../script/model/dancer'

# Angular controller for settlement print preview
window.customClass = class Print

  @$inject: ['$filter', '$rootScope', 'conf']

  # configuration service
  conf: null

  # printed registration
  registration: null

  # for rendering
  i18n: i18n

  # array of printed dancers
  dancers: []

  # dancer's names concatenated
  names: ''

  # dancer's addresses, in the same order as dancers
  addresses: []

  # dancer's classes, in the same order as dancers
  danceClasses: []

  constructor: (filter, rootScope, @conf) ->
    # get data from mother window
    card = windowManager.sharedData.fetch 'card'
    season = windowManager.sharedData.fetch 'season'
    @selectedTeacher = windowManager.sharedData.fetch 'selectedTeacher'
    @registration = _.find card.registrations, season: season

    # get card dancers
    Dancer.findWhere {cardId: card.id}, (err, dancers) =>
      return console.error err if err?
      @dancers = dancers
      map @dancers, (dancer, next) ->
        dancer.getAddress next
      , (err, addresses) =>
        return console.error err if err?
        map @dancers, (dancer, next) ->
          dancer.getClasses next
        , (err, danceClasses) =>
          return console.error err if err?
          @addresses = addresses
          @danceClasses = []
          # only keep dance class for this season
          for classes, i in danceClasses
            seasonClasses = (danceClass for danceClass in classes when danceClass.season is @registration.season)
            if seasonClasses.length >= 1
              @danceClasses.push seasonClasses
            else
              # nothing for this season
              @dancers.splice i, 1
              @addresses.splice i, 1

          @names = ("#{dancer.firstname} #{dancer.lastname}" for dancer in @dancers when dancer).join ', '
          # set window title
          window.document?.title = filter('i18n') 'ttl.print', args: names: @names
          rootScope.$apply()

          remote.getCurrentWindow().show()
          window.print()
          _.delay ->
            remote.getCurrentWindow().close()
          , 100

  # Retrieve dance classes of a given dancer
  #
  # @param dancer [Dancer] concerned dancer
  # @return list of its dance classes
  getClasses: (dancer) => @danceClasses[@dancers.indexOf dancer]

  # Format a given address for displayal
  #
  # @param dancer [Dancer] concerned dancer
  # @return its formated address
  formatAddress: (dancer) =>
    address = @addresses[@dancers.indexOf dancer]
    "#{address.street} #{address.zipcode} #{address.city}"

  # Format dance class's day for displayal
  #
  # @param danceClass [DanceClass] concerned dance class
  # @return its formated day
  formatDay: (danceClass) =>
    i18n.lbl[danceClass.start[0..2]]

  # Format dance class's hours for displayal
  #
  # @param danceClass [DanceClass] concerned dance class
  # @return its formated hours
  formatHours: (danceClass) =>
    start = danceClass.start[4..]
    end = danceClass.end[4..]
    "#{start}~#{end}"