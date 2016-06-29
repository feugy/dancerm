'use strict'
gui = require 'nw.gui'
_ = require 'lodash'
async = require 'async'
i18n = require '../script/labels/common'
{fixConsole} = require '../script/util/common'

fixConsole()
win = gui.Window.get()

# on DOM loaded
angular.element(win.window).on 'load', ->

  doc = angular.element(document)
  # adds dynamic styles
  doc.find('head').append "<style type='text/css'>#{global.styles['print']}</style>"

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
      dancers = win.list

      # regroup by addresses and get details
      groupByAddress = {}
      async.map dancers, (dancer, next) ->
        # first time we got this address
        groupByAddress[dancer.addressId] = [] unless dancer.addressId of groupByAddress
        groupByAddress[dancer.addressId].push dancer
        dancer.getAddress (err, address) ->
          if err?
            # do not fail on unknown address: instead, put new address with error message
            address = new Address id: generateId(), zipcode: 0, street: i18n.err.missingAddress
            dancer.setAddress address
            console.log "failed to get address of dancer #{dancer.id}: #{err}"
          next null, address
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
      doc.find('body').addClass 'printing'
      window.print()
      window.onfocus = -> win.close()

  app = angular.module('addressesPrint', []).controller 'Print', Print

  # get filters
  require('../script/util/filters')(app)

  angular.bootstrap doc.find('body'), ['addressesPrint']