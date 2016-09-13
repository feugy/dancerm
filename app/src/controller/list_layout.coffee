{join} = require 'path'
i18n = require '../labels/common'

module.exports = class ListLayoutController

  # Controller dependencies
  @$inject: ['$scope', 'cardList', 'invoiceList', 'lessonList', '$state', 'dialog']

  @declaration:
    controller: ListLayoutController
    controllerAs: 'listCtrl'
    templateUrl: 'list_layout.html'

  # Different available list service
  cardList: null
  invoiceList: null
  lessonList: null

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

  # Link to modal popup service
  dialog: null

  # contextual actions, an array of objects containing properties:
  # - label [String] displayed label with i18n filter
  # - icon [String] optionnal icon name (prepended with 'glyphicon-')
  # - action [Function] function invoked (without argument) when clicked
  # modified by main view's controller
  actions: []

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] controller own scope, for async refresh
  # @param cardList [CardListService] service responsible for card list
  # @param invoiceList [InvoiceListService] service responsible for invoice list
  # @param lessonList [LessonListService] service responsible for lesson list
  # @param state [Object] Angular's state provider
  # @param dialog [Object] Angular dialog service
  constructor: (@scope, @cardList, @invoiceList, @lessonList, @state, @dialog) ->
    @schools = i18n.lbl.schools

    @select switch localStorage?.getItem 'search-service'
      when 'invoice' then @invoiceList
      when 'lesson' then @lessonList
      else @cardList

    # initialize list
    @performSearch()

  # Pick a given service to search and handle search results
  #
  # @param listService [searchList] list service to select
  select: (listService) =>
    @service = listService
    localStorage.setItem 'search-service', @service.constructor.ModelClass.name.toLowerCase()
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
        {name: 'school', title: 'lbl.school', attr: (invoice) -> i18n.lbl.schools[invoice.selectedSchool].owner}
        {name: 'ref', title: 'lbl.ref'}
        {name: 'customer.name', title: 'lbl.customer', attr: (invoice) -> invoice.customer.name}
        {name: 'sent', title: 'lbl.sent', attr: (invoice) -> invoice.sent?}
      ]
    else if @service is @lessonList
      @listClass = 'lessons'
      @emptyListMessage = 'msg.emptyLessonList'
      @listMessage = 'msg.lessonListLength'
      @columns = [
        {noSort: true, selectable: (model) -> not model.invoiced}
        {name: 'teacher', title: 'lbl.teacherColumn'}
        {name: 'date', title: 'lbl.hours', attr: (lesson) -> lesson.date?.format i18n.formats.lesson}
        {name: 'details', title: 'lbl.details'}
      ]
    # refresh search
    @performSearch()

  # Select a list of lessons for invoice creation
  #
  # @param lessons [Array<Lesson>] selected lessons
  selectLessons: (lessons) =>
    @service.select lessons if @service is @lessonList
    @scope.$apply()

  # Makes a new invoice for the selected lesson and their concerned dancer.
  # If an unsent invoice for that dancer, season and selected school already exists,
  # displays a popup that offers to edit the invoice.
  #
  # @param schoolIdx [Number] index of the concerned school (in i18n.lbl.schools)
  onMakeInvoice: (schoolIdx) =>
    return unless @service is @lessonList
    @service.makeInvoice schoolIdx, (err, invoice) =>
      if err?
        return console.warn err unless invoice?
        # if an unsent invoice already exist, warn the user and stop here.
        return @dialog.messageBox(i18n.ttl.confirm, i18n.msg.invoiceAlreadyExist, [
            {label: i18n.btn.yes, result: true}
            {label: i18n.btn.no}
          ]
        ).result.then (confirmed) =>
          return unless confirmed
          # if confirmed, effectively display the existing invoice
          @state.go 'list.invoice', id: invoice.id
      # display the created invoice
      @state.go 'list.invoice', id: invoice.id
      @scope.$apply()

  # Displays a given model on the main part
  #
  # @param model [Dancer|Invoice] choosen model
  display: (model) =>
    console.log "ask to display #{model?.id}"
    if @service is @cardList
      @state.go 'list.card', id: model.cardId
    else if @service is @invoiceList
      @state.go 'list.invoice', id: model.id
    # nothing on lesson click

  isActive: (kind) => @service is @["#{kind}List"]

  # Performs search using the selected service
  performSearch: => @service.performSearch()