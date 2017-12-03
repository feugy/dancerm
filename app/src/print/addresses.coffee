_ = require 'lodash'
{map} = require 'async'
{remote} = require 'electron'
windowManager = remote.require 'electron-window-manager'
i18n = require '../script/labels/common'

# Angular controller for addresses print preview
window.customClass = class Print

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
    console.log "Print addresses"

    # get data from mother window
    dancers = windowManager.sharedData.fetch 'list'

    # regroup by addresses and get details
    groupByAddress = {}
    map dancers, (dancer, next) ->
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
          address = _.find addresses, id:id
          {
            selected: true
            dancers: dancers
            street: address.street
            zipcode: address.zipcode
            city: address.city
          }
      )
      scope.$apply()
      remote.getCurrentWindow().show()

  # Stop click propagation on checkboxes to avoid double toggleing a stamp.
  #
  # @param event [Event] the event to be stopped
  stopEvent: (event) =>
    event.stopPropagation()

  # Print button, that close the print window
  print: =>
    # remove configuration and unselected stamps
    angular.element(document).find('body').addClass 'printing'
    win = remote.getCurrentWindow()
    win.webContents.print {}, => win.close()