'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'
moment = require 'moment'
_ = require 'underscore'

# make some variable globals for other scripts
global.gui = gui
global.$ = $

# on DOM loaded
win = gui.Window.get()

# size to A4 format, landscape
win.resizeTo 1131, 800

$(win.window).on 'load', ->

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
      @danceClass = window.danceClass

      # group by card and then order by firstname
      groups = _.groupBy window.list.concat(), 'cardId'
      _.each groups, (group, key, list) ->
        list[key] = _.sortBy group, 'firstname'
      @list = _.flatten groups

      # Compute next 11 dates
      order = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      start = moment().day order.indexOf(@danceClass.start[0..2])+7
      @dates = (start.day(i*7).format i18n.formats.callList for i in [0..11])

    # Display dance class title
    #
    # @return start and end hour
    danceClassHour: =>
      day = @filter('i18n') "lbl.#{@danceClass.start[0..2]}"
      hour = "#{@danceClass.start[4..]}~#{@danceClass.end[4..]}"
      "#{day} #{hour}"

    # Print button, that close the print window
    print: =>
      $('.print').remove()
      window.print()
      win.close()

  app = angular.module('callListPrint', []).controller 'Print', Print
  
  # get filters
  require('../script/util/filters')(app)

  angular.bootstrap $('body'), ['callListPrint']