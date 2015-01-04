'use strict'
gui = require 'nw.gui'
moment = require 'moment'
_ = require 'lodash'

# on DOM loaded
win = gui.Window.get()

angular.element(win.window).on 'load', ->
  
  doc = angular.element(document)
  # adds dynamic styles
  doc.find('head').append "<style type='text/css'>#{global.styles['print']}</style>"

  # Angular controller for print preview
  class Print

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
      @danceClass = win.danceClass

      # group by card and then order by firstname
      @list = _.chain(win.list)
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

    # Display dance class title
    #
    # @return start and end hour
    danceClassHour: =>
      day = @filter('i18n') "lbl.#{@danceClass.start[0..2]}"
      hour = "#{@danceClass.start[4..]}~#{@danceClass.end[4..]}"
      "#{day} #{hour}"

    # Print button, that close the print window
    print: =>
      doc.find('body').addClass 'printing'
      window.print()
      win.close()

  app = angular.module('callListPrint', []).controller 'Print', Print
  
  # get filters
  require('../script/util/filters')(app)

  angular.bootstrap doc.find('body'), ['callListPrint']