{join} = require 'path'
i18n = require '../labels/common'

module.exports = class ListLayoutController

  # Controller dependencies
  @$inject: ['cardList', 'invoiceList', '$state']

  @declaration:
    controller: ListLayoutController
    controllerAs: 'listCtrl'
    templateUrl: 'list_layout.html'

  # Different available list service
  cardList: null
  invoiceList: null

  # Currently selected service
  service: null

  # Displayed columns, sort, list CSS class, messages
  # will be updated when selecting a given search service
  columns: []
  listClass: null
  sort: null
  emptyListMessage: null
  listMessage: null

  # Link to Angular's state provider
  state: null

  # contextual actions, an array of objects containing properties:
  # - label [String] displayed label with i18n filter
  # - icon [String] optionnal icon name (prepended with 'glyphicon-')
  # - action [Function] function invoked (without argument) when clicked
  # modified by main view's controller
  actions: []

  # **private**
  # Call list print preview window
  _preview: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param cardList [CardListService] service responsible for card list
  # @param invoiceList [InvoiceListService] service responsible for invoice list
  # @param state [Object] Angular's state provider
  constructor: (@cardList, @invoiceList, @state) ->
    @_preview = null
    @select @cardList

    # initialize list
    @performSearch()

  # Pick a given service to search and handle search results
  #
  # @param listService [searchList] list service to select
  select: (listService) =>
    @service = listService
    @sort = @service.constructor.sort
    @columns = []
    if @service is @cardList
      @listClass = 'dancers'
      @emptyListMessage = 'msg.emptyDancerList'
      @listMessage = 'msg.dancerListLength'
      @columns = [
        {name: 'firstname', title: 'lbl.firstname'}
        {name: 'lastname', title: 'lbl.lastname'}
        {name: 'certified', title: 'lbl.certified', attr: (dancer, done) ->
          dancer.getLastRegistration (err, registration) -> done err, registration?.certified(dancer) or false
        }
        {name: 'due', title: 'lbl.due', attr: (dancer, done) ->
          dancer.getLastRegistration (err, registration) -> done err, registration?.due() or 0
        }
      ]
    else if @service is @invoiceList
      @listClass = 'invoices'
      @emptyListMessage = 'msg.emptyInvoiceList'
      @listMessage = 'msg.invoiceListLength'
      @columns = [
        {name: 'ref', title: 'lbl.ref'}
        {name: 'customer.name', title: 'lbl.customer', attr: (invoice) -> invoice.customer.name}
        {name: 'sent', title: 'lbl.sent', attr: (invoice) -> invoice.sent?}
      ]
    # refresh search
    @performSearch()

  # Displays a given model on the main part
  #
  # @param model [Dancer|Invoice] choosen model
  display: (model) =>
    console.log "ask to display #{model.id}"
    if @service is @cardList
      @state.go 'list.card', id: model.cardId
    else
      @state.go 'list.invoice', id: model.id

  # Performs search using the selected service
  performSearch: => @service.performSearch()

  # @return true if the current list concerned a dance class
  canPrintCallList: =>
    return false unless @service is @cardList
    not @service.criteria.string and @service.criteria.danceClasses.length is 1

  # Print call list from the current day
  #
  # @param danceClass [DanceClass] danceClass concerned
  printCallList: =>
    return unless @service is @cardList
    return @_preview.focus() if @_preview?
    nw.Window.open 'app/template/call_list_print.html',
      frame: true
      title: window.document.title
      icon: require('../../../package.json')?.window?.icon
      focus: true
      # size to A4 format, landscape
      width: 1000
      height: 800
      , (created) =>
        @_preview = created
        # set displayed list and wait for closure
        @_preview.list = @cardList.list
        @_preview.danceClass = @cardList.criteria.danceClasses[0]
        @_preview.on 'closed', => @_preview = null