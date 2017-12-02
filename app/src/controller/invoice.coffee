_ = require 'lodash'
moment = require 'moment'
{remote} = require 'electron'
windowManager = remote.require 'electron-window-manager'
isPrintCtx = global.isPrintCtx or false
# if used in print context, path to other dependencies are different
i18n = require "../#{if isPrintCtx then 'script/' else ''}labels/common"
Invoice = require "../#{if isPrintCtx then 'script/' else ''}model/invoice"
InvoiceItem = require "../#{if isPrintCtx then 'script/' else ''}model/invoice_item"
{invoiceRefExtract} = require "../#{if isPrintCtx then 'script/' else ''}util/common"

# Simple validation function that check if a given value is defined and acceptable
isInvalidString = (value) -> not(value?) or value.trim?()?.length is 0
isInvalidDate = (value) -> not(value?) or not moment(value).isValid()

# Displays and edits a given invoice
# Also usable as print controller
class InvoiceController

  # Controller dependencies
  @$inject: ['$scope', '$rootScope', 'conf'].concat unless isPrintCtx then ['dialog', '$state', '$filter', '$stateParams', 'invoiceList'] else []

  # Route declaration
  @declaration:
    controller: InvoiceController
    controllerAs: 'ctrl'
    templateUrl: 'invoice.html'

  # for rendering
  i18n: i18n

  # Controller's own scope, for change detection
  scope: null

  # Angular's global scope, for digest triggering
  rootScope: null

  # Link to modal popup service
  dialog: null

  # Angular's state service
  state: null

  # Configuration service
  conf: null

  # Angular's filters factory
  filter: null

  # Service that list invoices
  invoiceList: null

  # displayed invoice
  invoice: null

  # Indicates wether this invoice is read only
  isReadOnly: false

  # flag indicating wether the invoice has been changed or not
  hasChanged: false

  # local copy of due date cause directive can't watch computed field changes
  dueDate: null

  # in case of invalid reference, ref suggested
  suggestedRef: null

  # apply VAT or not
  withVat: false

  # shortcut to @conf.teachers[@invoice.selectedTeacher]
  teacher: null

  # Option used to configure date selection popup
  dateOpts:
    value: null
    open: false
    showWeeks: false
    startingDay: 1
    showButtonBar: false

  # contains an array of required fields
  required:
    invoice: []
    items: []

  # possible prices displayed when editing lines
  priceList: []

  # **private**
  # Store if a modal is currently opened
  _modalOpened: false

  # **private**
  # Stores previous models values (model id used as key) for change detection
  _previous: {}

  # **private**
  # Registration print preview window
  _preview: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Controller's own scope, for change detection
  # @param rootscope [Object] Angular global scope for digest triggering
  # @param dialog [Object] Angular dialog service
  # @param filter [Function] Angular's filter factory
  # @param state [Object] Angular state provider
  # @param stateParams [Object] invokation route parameters
  constructor: (@scope, @rootScope, @conf, @dialog, @state, @filter, stateParams, @invoiceList) ->
    @invoice = null
    @hasChanged = false
    @hideItemDiscount = false
    @_modalOpened = false
    @_previous = {}
    @isReadOnly = false
    @dueDate = null
    @suggestedRef = null
    @withVat = false
    @required =
      invoice: []
      items: []

    # list of actions used to listCtrl
    @_actions =
      print: label: 'btn.print', icon: 'print', action: @print
      markAsSent: label: 'btn.markAsSent', icon: 'inbox', action: @markAsSent
      cancel: label: 'btn.cancel', icon: 'ban-circle', action: @cancel
      save: label: 'btn.save', icon: 'floppy-disk', action: @save

    @dateOpts =
      value: null
      open: false
      showWeeks: false
      startingDay: 1
      showButtonBar: false

    # if used in the context of printing, skip internal init as we are just displaying preview
    if isPrintCtx
      @_onLoad new Invoice JSON.parse windowManager.sharedData.fetch 'invoiceRaw'
      _.defer ->
        remote.getCurrentWindow().show()
        window.print()
        ### _.delay ->
          remote.getCurrentWindow().close()
        , 100 ###
      return

    # abort if no invoice parameter found
    return unless stateParams.invoice?

    # load invoice to display values
    @_onLoad stateParams.invoice

    @rootScope.$on '$stateChangeStart', (event, toState, toParams) =>
      return unless @hasChanged
      # stop state change until user choose what to do with pending changes
      event.preventDefault()
      # confirm if dancer changed
      @dialog.messageBox(@i18n.ttl.confirm, @i18n.msg.confirmGoBack, [
          {label: @i18n.btn.no, cssClass: 'btn-warning'}
          {label: @i18n.btn.yes, result: true}
        ]
      ).result.then (confirmed) =>
        return unless confirmed
        # if confirmed, effectively go on desired state after reseting previous values
        @_reset()
        @state.go toState.name, toParams

  # Goes back to list, after a confirmation if dancer has changed
  back: => @state.go 'invoice'

  # restore previous values
  cancel: =>
    return unless @hasChanged and not @_modalOpened
    @_modalOpened = true
    @dialog.messageBox(@i18n.ttl.confirm,
      @filter('i18n')('msg.cancelEdition', args: names: @invoice.ref), [
        {label: @i18n.btn.no, cssClass: 'btn-warning'}
        {label: @i18n.btn.yes, result: true}
      ]
    ).result.then (confirmed) =>
      @_modalOpened = false
      return unless confirmed
      # cancel and restore previous values
      @rootScope.$broadcast 'cancel-edit'
      @_reset()
      @scope.$apply() unless @scope.$$phase

  # Save the current values inside storage
  #
  # @param force [Boolean] true to ignore required fields. Default to false.
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no problem occured
  save: (force = false, done = ->) =>
    return done null unless @hasChanged and not @isReadOnly
    # check required fields
    if not force and @_checkRequired()
      return @dialog.messageBox(@i18n.ttl.confirm, i18n.msg.requiredInvoiceFields, [
          {label: @i18n.btn.no, cssClass: 'btn-warning'}
          {label: @i18n.btn.yes, result: true}
        ]
      ).result.then (confirmed) =>
        # important ! don't invoke done on cancellation, so the print/markAsSent
        # process is cancelled
        return unless confirmed
        @save true, done

    console.log "save invoice #{@invoice.ref} (#{@invoice.id})"
    @invoice.save (err) =>
      if err?
        console.error err
        return @dialog.messageBox(@i18n.ttl.saveError, err.message, [
            {label: @i18n.btn.ok}
          ]
        ).result.then done
      @_previous = @invoice.toJSON()
      console.log "invoice saved"
      @invoiceList.performSearch()
      @_onChange()
      @required =
        invoice: []
        items: ([] for item in @invoice.items)
      @scope.$apply() unless @scope.$$phase
      done()

  # After a confirmation, mark the invoice as sent.
  markAsSent: =>
    return if @isReadOnly
    @dialog.messageBox(@i18n.ttl.confirm, @i18n.msg.confirmMarkAsSent, [
        {label: @i18n.btn.yes, result: true, cssClass: 'btn-warning'}
        {label: @i18n.btn.no}
      ]
    ).result.then (confirmed) =>
      return unless confirmed
      # if confirmed, effectively mark as sent
      @invoice.sent = moment()
      @hasChanged = true
      @save false, (err) =>
        return console.error err if err?
        # reset everything to reflect read-only state
        @_onLoad @invoice

  # @returns [String] formated date for printing
  displayDate: (date) => date?.format? @i18n.formats.invoice

  # Invoked when date change in the date picker
  # Updates the invoice's' date
  setDate: =>
    return if @isReadOnly or not @invoice?
    newDate = moment @dateOpts.value
    @invoice.changeDate newDate
    @dueDate = @invoice.dueDate
    @_onChange 'date'

  # Opens the date selection popup
  #
  # @param event [Event] click event, prevented.
  toggleDate: (event) =>
    # prevent, or popup won't show
    event?.preventDefault()
    event?.stopPropagation()
    @dateOpts.open = not @dateOpts.open

  # Save current invoice and display print preview
  print: =>
    return @_preview.focus() if @_preview?
    # save will be effective only it has changed
    @save false, (err) =>
      return console.error err if err?

      windowManager.sharedData.set 'styles', global.styles.print
      # for an unknown reason, sending @invoice, or even the JSON equivalent
      # introduct serialization glitches in getter and setter.
      windowManager.sharedData.set 'invoiceRaw', JSON.stringify @invoice.toJSON()

      # open hidden print window
      @_preview = windowManager.createNew 'invoice', window.document.title, null, 'print'
      @_preview.open '/invoice_print.html', true
      @_preview.focus()

      @_preview.object.on 'closed', =>
        # dereference the window object, to destroy it
        @_preview = null

  # Add a new item to the current invoice
  addItem: =>
    return if @isReadOnly
    @invoice.items.push new InvoiceItem vat: if @withVat then @conf.vat else 0
    @_onChange 'items'

  # Removes an existing item from the current invoice
  #
  # @param item [InvoiceItem] removed item
  removeItem: (item) =>
    return if @isReadOnly
    idx = @invoice.items.indexOf item
    return if idx is -1
    @invoice.items.splice idx, 1
    @_onChange 'items'

  # Change VAT of each existing items
  changeVat: =>
    return unless @invoice
    for item, i in @invoice.items
      item.vat = if @withVat then @conf.vat else 0
    @_onChange 'item[0].vat'

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) =>
    return 'invalid' if @required.invoice?.includes field
    ''

  # **private**
  # Reset current fields to previous values
  _reset: =>
    Object.assign @invoice, @_previous
    @invoice.changeDate @_previous.date
    @dateOpts.value = @invoice.date.valueOf()
    @_previous = @invoice.toJSON()
    @priceList = @i18n.priceList[@invoice.season] or @i18n.priceList.default
    @_setChanged false

  # **private**
  # initialize controller for a given invoice
  # @param invoice [Invoice] Loaded invoice
  _onLoad: (invoice) =>
    @invoice = invoice
    @teacher = @conf.teachers[@invoice.selectedTeacher]
    @priceList = @i18n.priceList[@invoice.season] or @i18n.priceList.default
    @dueDate = @invoice.dueDate
    @isReadOnly = @invoice.sent?
    @dateOpts.value = @invoice.date.valueOf()
    @required =
      invoice: []
      items: ([] for item in @invoice.items)
    # hide item discount if reado-only and no items has discount
    @hideItemDiscount = @isReadOnly and not @invoice.items.find((item) => item.discount > 0)?
    @_previous = @invoice.toJSON()
    # set vat depending on the first item content
    @withVat = @invoice.items.some (item) -> item.vat > 0
    console.log "load invoice #{@invoice.ref} (#{@invoice.id})"
    # reset changes and displays everything
    @_setChanged false
    # remove all buttons except print if relevant
    @scope.listCtrl?.actions = [@_actions.print] if @isReadOnly
    @scope.$apply() unless @scope.$$phase

  # **private**
  # Update hasChanged flag and contextual actions
  #
  # @param changed [Boolean] new hasChanged flag value
  _setChanged: (changed) =>
    next = if @invoice.items?.length then [@_actions.markAsSent] else []
    @scope.listCtrl.actions = [@_actions.markAsSent]
    if changed
      # can cancel only if already saved once
      next.unshift @_actions.cancel if @invoice._v > 0
      next.unshift @_actions.save
    @hasChanged = changed
    # only update actions if they have changed
    @scope.listCtrl?.actions = next unless _.isEqual next, @scope.listCtrl?.actions

  # **private**
  # Change handler: check if any displayed model has changed from its previous values
  #
  # @param field [String] modified field
  _onChange: (field) =>
    # performs comparison between current and old values
    @_setChanged false
    @_setChanged not _.isEqual @_previous, @invoice.toJSON()
    # on reference changes (and if values differ), check validity
    if field is 'ref'
      @suggestedRef = null
      newRef = @invoice.ref
      return if @_previous.ref is newRef
      Invoice.isRefValid newRef, @invoice, (err, isValid) =>
        unless isValid
          # in cas of invalidity, get the next ref for expected month
          matched = newRef.match(invoiceRefExtract) or []
          year = +matched[1] or moment().year()
          month = +matched[2] or moment().month() + 1
          matched = @_previous.ref?.match(invoiceRefExtract) or []
          currYear = +matched[1]
          currMonth = +matched[2]
          Invoice.getNextRef year, month, @invoice.selectedTeacher, (err, next) =>
            unless err?
              # reuse previous ref if keeping same year and month
              @suggestedRef = if year is currYear and month is currMonth then @_previous.ref else next
            @scope.$apply() unless @scope.$$phase

  # **private**
  # Check required fields when saving invoice
  #
  # @return true if a required field is missing
  _checkRequired: =>
    @required =
      invoice: []
      items: ([] for item in @invoice.items)
    # check the invoice itself
    @required.invoice.push 'ref' if isInvalidString @invoice.ref
    @required.invoice.push 'date' if isInvalidDate @invoice.date
    @required.invoice.push (field for field in ['name', 'street', 'city', 'zipcode'] when isInvalidString @invoice.customer?[field])...
    # check each items
    for item, i in @invoice.items or []
      @required.items[i].push 'name' if isInvalidString item.name
    # returns true if invoice or any of its item is missing a field
    @required.invoice.length isnt 0 or @required.items.some (item) -> item.length isnt 0

# Export as print controller for print preview, or classical node export
unless isPrintCtx
  module.exports = InvoiceController
else
  window.customClass = InvoiceController