moment = require 'moment'
Invoice = require '../model/invoice'

# Displays a list of invoices
module.exports = class InvoiceListController

  # Route declaration
  @declaration:
    controller: InvoiceListController
    controllerAs: 'ctrl'
    templateUrl: 'invoice_list.html'

  # Option used to configure date selection popup
  dateOpts:
    value: null
    open: false
    showWeeks: false
    startingDay: 1
    showButtonBar: false

  # Build invoice list by selecting all invoice for a given month
  constructor: () ->
    @list = []

    @dateOpts =
      value: moment().toDate()
      open: false
      showWeeks: false
      startingDay: 1
      showButtonBar: false

    @pickDate()

  # Invoked when date change in the date picker
  # Refresh invoice list
  pickDate: =>
    date = moment @dateOpts.value
    Invoice.findWhere date: new RegExp("^#{date.year()}-0?#{date.month()+1}"), (err, invoices) =>
      return console.log err if err?
      @list = invoices

  # Opens the date selection popup
  #
  # @param event [Event] click event, prevented.
  toggleDate: (event) =>
    # prevent, or popup won't show
    event?.preventDefault()
    event?.stopPropagation()
    @dateOpts.open = not @dateOpts.open