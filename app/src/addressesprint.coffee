'use strict'

gui = require 'nw.gui'
i18n = require '../script/labels/common'
{dumpError} = require '../script/util/common'
moment = require 'moment'
_ = require 'lodash'
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

    @$inject: ['$scope']

    # stamp initial dimensions, in mm
    stampDim: 
      w: 63.5
      h: 38.1
      # vertical and horizontal pagging
      vp: 5
      hp: 5
      # vertical and horizontal margins
      vm: 0
      hm: 2

    # list of stamps to print
    stamps: []

    # Build controller for the call list preview
    #
    # @param scope [Object] controller's own scope
    constructor: (scope) ->
      # get data from mother window
      dancers = window.list

      # regroup by addresses and get details
      groupByAddress = {}
      async.map dancers, (dancer, next) ->
        # first time we got this address
        groupByAddress[dancer.addressId] = [] unless dancer.addressId of groupByAddress
        groupByAddress[dancer.addressId].push dancer
        dancer.getAddress next
      , (err, addresses) =>
        return console.error err if err?
        # then make stamps
        @stamps = (
          for id, dancers of groupByAddress
            # get common address
            address = _.findWhere addresses, id:id
            {
              selected: true
              dancers: dancers
              street: address.street
              zipcode: address.zipcode
              city: address.city
            }
        )
        scope.$apply()
        
    # Stop click propagation on checkboxes to avoid double toggleing a stamp.
    #
    # @param event [Event] the event to be stopped
    stopEvent: (event) =>
      event.stopPropagation()

    # Print button, that close the print window
    print: =>
      # remove configuration and unselected stamps
      $('body').addClass 'printing'
      window.print()
      win.close()

  app = angular.module('addressesPrint', []).controller 'Print', Print
  
  # get filters
  require('../script/util/filters')(app)

  angular.bootstrap $('body'), ['addressesPrint']