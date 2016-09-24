{join} = require 'path'
i18n = require '../labels/common'
ListController = require './tools/list'

module.exports = class ListLayoutController extends ListController

  # Controller dependencies
  @$inject: ['$scope', 'cardList', 'invoiceList', 'lessonList', '$state', 'dialog']

  @declaration:
    controller: ListLayoutController
    controllerAs: 'listCtrl'
    templateUrl: 'list_layout.html'

  # Columns used depending on the selected service
  @colSpec:
    card: [
      {name: 'firstname', title: 'lbl.firstname'}
      {name: 'lastname', title: 'lbl.lastname'}
      {
        name: 'certified'
        title: 'lbl.certified'
        attr: (dancer, done) ->
          dancer.getLastRegistration (err, registration) -> done err, registration?.certified(dancer) or false
      }
      {
        name: 'due'
        title: 'lbl.due'
        attr: (dancer, done) ->
          dancer.getLastRegistration (err, registration) -> done err, registration?.due() or 0
      }
    ]
    invoice: [
      {name: 'school', title: 'lbl.school', attr: (invoice) -> i18n.lbl.schools[invoice.selectedSchool].owner}
      {name: 'ref', title: 'lbl.ref'}
      {name: 'customer.name', title: 'lbl.customer', attr: (invoice) -> invoice.customer.name}
      {name: 'sent', title: 'lbl.sent', attr: (invoice) -> invoice.sent?}
    ]
    lesson: [
      {selectable: (model) -> not model.invoiceId?}
      {name: 'teacher', title: 'lbl.teacherColumn'}
      {
        name: 'date'
        title: 'lbl.hours'
        attr: (lesson) -> lesson.date?.format i18n.formats.lesson
        sorter: (lesson) -> lesson.date?.valueOf()
      }
      {name: 'details', title: 'lbl.details'}
    ]

  # Link to modal popup service
  dialog: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] controller own scope, for async refresh
  # @param cardList [CardListService] service responsible for card list
  # @param invoiceList [InvoiceListService] service responsible for invoice list
  # @param lessonList [LessonListService] service responsible for lesson list
  # @param state [Object] Angular's state provider
  # @param dialog [Object] Angular dialog service
  constructor: (scope, cardList, invoiceList, lessonList, state, @dialog) ->
    @schools = i18n.lbl.schools
    super scope, cardList, invoiceList, lessonList, state

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
      # display the created invoice and refresh lesson list
      @state.go 'list.invoice', id: invoice.id
      console.log "refresh lesson list"
      @performSearch()
      @scope.$apply()