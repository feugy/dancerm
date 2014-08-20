'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'
Dancer = require '../script/model/dancer'
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

  # Angular controller for print preview
  class Print

    @$inject: ['$filter', '$rootScope']

    # printed registration
    registration: null

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

    # Format a given address for displayal
    #
    # @param dancer [Dancer] concerned dancer
    # @return its formated address
    formatAddress: (dancer) =>
      address = @addresses[@dancers.indexOf dancer]
      "#{address.street} #{address.zipcode} #{address.city}"

    # Format dance classes fro a displayal
    #
    # @param dancer [Dancer] concerned dancer
    # @return its formated dance classes
    formatClasses: (dancer) =>
      classes = @danceClasses[@dancers.indexOf dancer]
      ("#{danceClass.kind} #{danceClass.level}" for danceClass in classes).join ', '

    # Print button, that close the print window
    print: =>
      $('.print').remove()
      window.print()
      win.close()

  app = angular.module('registrationPrint', []).controller 'Print', Print
  
  # get filters
  require('../script/util/filters')(app)

  angular.bootstrap $('body'), ['registrationPrint']