_ = require 'lodash'
{remote} = require 'electron'
windowManager = remote.require 'electron-window-manager'
moment = require 'moment'

# Angular controller for call list print preview
window.customClass = class CallListPrint

  @$inject: ['$filter']

  # Angular's filters factory
  filter: null

  # printed dance class
  danceClass: null

  # array of printed dancers
  list: []

  # array of dates to be check
  dates: []

  # Build controller for the call list preview
  #
  # @param filter [Function] angular's filter factory
  constructor: (@filter) ->

    # get data from mother window
    @danceClass = windowManager.sharedData.fetch 'danceClass'

    console.log "Print call list for #{@danceClass.level} #{@danceClass.kind} #{@danceClass.id}"

    # group by card and then order by firstname
    @list = _.chain(windowManager.sharedData.fetch 'list')
      .groupBy('cardId')
      .each((group, key, list) -> list[key] = _.sortBy group, 'firstname')
      .values()
      .flatten()
      .value()

    # Compute next 11 dates
    order = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

    # get the next class's day, and remove a week for loop init
    start = moment().day(order.indexOf @danceClass.start[0..2]).subtract 7, 'day'
    # then add a week and print for next 12 occurences
    @dates = (start.add(7, 'day').format @filter('i18n')('formats.callList') for i in [0..11])

    _.defer ->
      remote.getCurrentWindow().show()
      window.print()
      _.defer -> remote.getCurrentWindow().close()

  # Display dance class title
  #
  # @return start and end hour
  danceClassHour: =>
    day = @filter('i18n') "lbl.#{@danceClass.start[0..2]}"
    hour = "#{@danceClass.start[4..]}~#{@danceClass.end[4..]}"
    "#{day} #{hour}"