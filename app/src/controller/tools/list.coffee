Invoice = require '../../model/invoice'
Dancer = require '../../model/dancer'
Lesson = require '../../model/lesson'

# Base class for small and expanded lists
module.exports = class ListController

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
  constructor: (@scope, @cardList, @invoiceList, @lessonList, @state) ->
    @select switch localStorage?.getItem 'search-service'
      when 'invoice' then @invoiceList
      when 'lesson' then @lessonList
      else @cardList

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
      @columns = @constructor.colSpec.card
    else if @service is @invoiceList
      @listClass = 'invoices'
      @emptyListMessage = 'msg.emptyInvoiceList'
      @listMessage = 'msg.invoiceListLength'
      @columns = @constructor.colSpec.invoice
    else if @service is @lessonList
      @listClass = 'lessons'
      @emptyListMessage = 'msg.emptyLessonList'
      @listMessage = 'msg.lessonListLength'
      @columns = @constructor.colSpec.lesson
    # refresh search
    @performSearch()

  isActive: (kind) => @service is @["#{kind}List"]

  # Performs search using the selected service
  performSearch: => @service.performSearch()

  # Select a list of lessons for invoice creation
  #
  # @param lessons [Array<Lesson>] selected lessons
  selectLessons: (lessons) =>
    @service.select lessons if @service is @lessonList
    @scope.$apply()

  # Displays a given model on the main part
  #
  # @param model [Dancer|Invoice|Lesson] choosen model
  display: (model) =>
    console.log "ask to display #{model?.id}"
    if model instanceof Dancer
      @state.go 'list.card', id: model.cardId
    else if model instanceof Invoice
      @state.go 'list.invoice', id: model.id
    else if model instanceof Lesson
      @state.go 'lessons', id: model.id