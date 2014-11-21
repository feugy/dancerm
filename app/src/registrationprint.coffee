'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'
Dancer = require '../script/model/dancer'
{dumpError} = require '../script/util/common'
moment = require 'moment'
# merge lodash and lodash string functions
_ = require 'lodash'
_str = require 'lodash.string'
_.mixin _str.exports()
async = require 'async'

process.on 'uncaughtException', dumpError

# make some variable globals for other scripts
global.gui = gui
global.$ = $

# on DOM loaded
win = gui.Window.get()

# size to A4 format, 3/4 height
win.resizeTo 790, 400

$(win.window).on 'load', ->

  # Angular controller for print preview
  class Print

    @$inject: ['$filter', '$rootScope']

    # printed registration
    registration: null

    # display V.A.T. or not
    withVat: false

    # displays classes details or not
    withClasses: true

    # displays charge or not
    withCharged: false

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
      @withClasses = window.withClasses
      @withVat = window.withVat
      @withCharged = window.withCharged
      # get data from mother window
      @registration = _.findWhere window.card.registrations, season: window.season 
      # get card dancers
      Dancer.findWhere {cardId: window.card.id}, (dancers, err) =>
        return console.error err if err?
        @dancers = dancers
        async.map @dancers, (dancer, next) -> 
          dancer.getAddress next
        , (err, addresses) =>
          return console.error err if err?
          async.map @dancers, (dancer, next) -> 
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
    getClasses: (dancer) => @danceClasses[@dancers.indexOf dancer]

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

    # Compute charged by taking period into account
    #
    # @return the VAT amount
    getCharged: => @registration.charged / (if @registration.period is 'quarter' then 3 else 1)

    # Compute VAT on registration
    #
    # @return the VAT amount
    getVat: => Math.floor(@getCharged()/(1+i18n.vat)*i18n.vat*100)/100

    # Check if this registration contains a given payment type
    #
    # @param type [String] searched payment type
    # @return true if this payment type is included, false otherwise
    hasPayment: (type) =>
      return true for payment in @registration.payments when payment.type is type
      false

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