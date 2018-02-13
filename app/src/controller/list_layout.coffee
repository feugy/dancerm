{join} = require 'path'
i18n = require '../labels/common'
ListController = require './tools/list'

module.exports = class ListLayoutController extends ListController

  # Controller dependencies
  @$inject: ['$scope', 'cardList', 'invoiceList', 'lessonList', '$state', 'conf', 'dialog']

  @declaration:
    controller: ListLayoutController
    controllerAs: 'listCtrl'
    templateUrl: 'list_layout.html'

  # Columns used depending on the selected service
  @colSpec:
    card: []
    invoice: []
    lesson: []

  # Link to modal popup service
  dialog: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] controller own scope, for async refresh
  # @param cardList [CardListService] service responsible for card list
  # @param invoiceList [InvoiceListService] service responsible for invoice list
  # @param lessonList [LessonListService] service responsible for lesson list
  # @param state [Object] Angular's state provider
  # @param conf [Object] Configuration service
  # @param dialog [Object] Angular dialog service
  constructor: (scope, cardList, invoiceList, lessonList, state, conf, @dialog) ->
    super scope, cardList, invoiceList, lessonList, state, conf

    unless @constructor.colSpec.card.length
      @constructor.colSpec.card.push {name: 'firstname', title: 'lbl.firstname'},
        {name: 'lastname', title: 'lbl.lastname'},
        {
          name: 'certified'
          title: 'lbl.certified'
          attr: (dancer, done) ->
            dancer.getLastRegistration (err, registration) -> done err, registration?.certified(dancer) or false
        },
        {
          name: 'due'
          title: 'lbl.due'
          attr: (dancer, done) ->
            dancer.getLastRegistration (err, registration) -> done err, registration?.due() or 0
        },
        {
          name: 'period'
          title: 'lbl.period'
          attr: (dancer, done) ->
            dancer.getLastRegistration (err, registration) -> done err, registration?.period or 'year'
        }

      @constructor.colSpec.invoice.push {name: 'teacher', title: 'lbl.teacherColumn', attr: (invoice) => @conf.teachers[invoice.selectedTeacher]?.owner},
        {name: 'ref', title: 'lbl.ref'},
        {name: 'customer.name', title: 'lbl.customer', attr: (invoice) -> invoice.customer.name},
        {name: 'sent', title: 'lbl.sent', attr: (invoice) -> invoice.sent?}

      @constructor.colSpec.lesson.push {selectable: (model) -> not model.invoiceId?},
        {name: 'teacher', title: 'lbl.teacherColumn', attr: (lesson) => @conf.teachers[lesson.selectedTeacher]?.owner},
        {
          name: 'date'
          title: 'lbl.hours'
          attr: (lesson) -> lesson.date?.format i18n.formats.lesson
          sorter: (lesson) -> lesson.date?.valueOf()
        },
        {name: 'details', title: 'lbl.details'}

  # Makes a new invoice for the selected lesson and their concerned dancer.
  # If an unsent invoice for that dancer, season and selected teacher already exists,
  # displays a popup that offers to edit the invoice.
  onMakeInvoice: () =>
    return unless @service is @lessonList
    @service.makeInvoice (err, invoice) =>
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
          @state.go 'list.invoice', {invoice}
      # display the created invoice and refresh lesson list
      @state.go 'list.invoice', {invoice}
      console.log "refresh lesson list"
      @performSearch()
      @scope.$apply()