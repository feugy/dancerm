{debounce} = require 'lodash'
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
  placeholder: null

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
  # @param conf [Object] Configuration service
  constructor: (@scope, @cardList, @invoiceList, @lessonList, @state, @conf) ->
    # select the relevant UI controls when search is triggered on an individual service
    @cardList.on 'search-start', => @select @cardList, false
    @invoiceList.on 'search-start', => @select @invoiceList, false
    @lessonList.on 'search-start', => @select @lessonList, false

    @select switch @conf.searchService
      when 'invoice' then @invoiceList
      when 'lesson' then @lessonList
      else @cardList

  # Pick a given service to search and handle search results
  #
  # @param listService [searchList] list service to select
  # @param refresh [boolean] for result refresh if true
  select: (listService, refresh = true) =>
    if @service isnt listService
      @service = listService
      # Performs search using the selected service
      @performSearch = debounce (=>
        @service.performSearch()
      ), 250
      @conf.searchService = @service.constructor.ModelClass.name.toLowerCase()
      @conf.save()
      @sort = @service.constructor.sort
      @columns = []

    if @service is @cardList
      @listClass = 'dancers'
      @emptyListMessage = 'msg.emptyDancerList'
      @listMessage = 'msg.dancerListLength'
      @placeholder = 'placeholder.searchCards'
      @columns = @constructor.colSpec.card
    else if @service is @invoiceList
      @listClass = 'invoices'
      @emptyListMessage = 'msg.emptyInvoiceList'
      @listMessage = 'msg.invoiceListLength'
      @placeholder = 'placeholder.searchInvoices'
      @columns = @constructor.colSpec.invoice
    else if @service is @lessonList
      @listClass = 'lessons'
      @emptyListMessage = 'msg.emptyLessonList'
      @listMessage = 'msg.lessonListLength'
      @placeholder = 'placeholder.searchLessons'
      @columns = @constructor.colSpec.lesson
    # refresh search
    @performSearch() if refresh

  # indicates whether a given service is active or not
  # @param kind [String] service kind (one of 'lesson', 'card', 'invoice')
  # returns [Boolean] true if this service is active
  isActive: (kind) => @service is @["#{kind.toLowerCase()}List"]

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
      @state.go 'list.invoice', invoice: model
    else if model instanceof Lesson
      @state.go 'lessons', id: model.id