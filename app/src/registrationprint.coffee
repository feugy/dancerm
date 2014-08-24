'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'
Dancer = require '../script/model/dancer'
moment = require 'moment'
# merge underscore and underscore string functions
_ = require 'underscore'
_str = require 'underscore.string'
_.mixin _str.exports()

# make some variable globals for other scripts
global.gui = gui
global.$ = $

# on DOM loaded
win = gui.Window.get()

# size to A4 format, 3/4 height
win.resizeTo 790, 825

$(win.window).on 'load', ->

  win.showDevTools()
  
  # Angular controller for print preview
  class Print

    @$inject: ['$filter', '$rootScope']

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

    constructor: (filter, rootScope) ->
      # get data from mother window
      @registration = _.findWhere window.card.registrations, season: window.season 
      # get card dancers
      Dancer.findWhere(cardId: window.card.id).then((dancers) =>
        @dancers = dancers
        Promise.all((dancer.address for dancer in @dancers)).then (addresses) =>
          Promise.all((dancer.danceClasses for dancer in @dancers)).then (danceClasses) =>
            @danceClasses = danceClasses
            @addresses = addresses
            @names = ("#{dancer.firstname} #{dancer.lastname}" for dancer in @dancers when dancer).join ', '
            # set window title
            window.document?.title = filter('i18n') 'ttl.print', args: names: @names
            rootScope.$digest()
      ).catch (err) => console.log err

    # Retrieve home phone from address
    #
    # @param dancer [Dancer] concerned dancer
    # @return its home phone
    getPhone:(dancer) =>
      address = @addresses[@dancers.indexOf dancer]
      address.phone or ''

    # Retrieve dance classes of a given dancer
    #
    # @param dancer [Dancer] concerned dancer
    # @return list of its dance classes
    getClasses: (dancer) =>
      @danceClasses[@dancers.indexOf dancer]

    # Return V.A.T. rounded to two decimals
    #
    # @return the V.A.T.
    getVat: =>
      Math.floor(@registration.charged * 0.196 * 100) / 100

    # Format a given address for displayal
    #
    # @param dancer [Dancer] concerned dancer
    # @return its formated address
    formatAddress: (dancer) =>
      address = @addresses[@dancers.indexOf dancer]
      "#{address.street} #{address.zipcode} #{address.city}"

    # Format dancer's birth date for displayal
    #
    # @param dancer [Dancer] concerned dancer
    # @return its formated birth date
    formatBirth: (dancer) =>
      if dancer.birth? then dancer.birth.format i18n.formats.birth else ''

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

    # Print button, that close the print window
    print: =>
      $('.print').remove()
      window.print()
      win.close()

  app = angular.module('registrationPrint', []).controller 'Print', Print

  # Simple directive that whill replace current element with HTML raw text
  app.directive 'placeholder', ->
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # replace element with specified HTML
    link: (scope, elm, attrs) ->
      $(elm).replaceWith attrs.placeholder
  
  # get filters
  require('../script/util/filters')(app)

  angular.bootstrap $('body'), ['registrationPrint', 'ngSanitize']