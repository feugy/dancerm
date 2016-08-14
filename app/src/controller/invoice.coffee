_ = require 'lodash'
moment = require 'moment'
isPrintCtx = not module?
# if used in print context, path to other dependencies are different
i18n = require "../#{if isPrintCtx then 'script/' else ''}labels/common"
Invoice = require "../#{if isPrintCtx then 'script/' else ''}model/invoice"
InvoiceItem = require "../#{if isPrintCtx then 'script/' else ''}model/invoice_item"
{invoiceRefExtract} = require "../#{if isPrintCtx then 'script/' else ''}util/common"

# Simple validation function that check if a given value is defined and acceptable
isInvalidString = (value) -> not(value?) or value.trim?()?.length is 0
isInvalidDate = (value) -> not(value?) or not value.isValid()

# Displays and edits a given invoice
# Also usable as print controller
class InvoiceController

  # Controller dependencies
  @$inject: ['$scope', '$rootScope'].concat unless isPrintCtx then ['dialog', '$state', '$filter', '$stateParams'] else []

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

  # Angular's filters factory
  filter: null

  # displayed invoice
  invoice: null

  # Indicates wether this invoice is read only
  isReadOnly: false

  # flag indicating wether the invoice has been changed or not
  hasChanged: false

  # in case of invalid reference, ref suggested
  suggestedRef: null

  # apply VAT or not
  withVat: false

  # copy of invoice's selected school, to allow default value
  selectedSchool: 0

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
  constructor: (@scope, @rootScope, @dialog, @state, @filter, stateParams) ->
    @invoice = null
    @hasChanged = false
    @_modalOpened = false
    @_previous = {}
    @isReadOnly = false
    @suggestedRef = null
    @withVat = false
    @selectedSchool = 0
    @required =
      invoice: []
      items: []

    # list of actions used to listCtrl
    @_actions =
      print: label: 'btn.print', icon: 'print', action: @print
      markAsSent: label: 'btn.markAsSent', icon: 'send', action: @markAsSent
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
      @_onLoad win.invoice
      window.print()
      _.defer -> win.close()
      return

    # redirect to invoice list if needded
    return @back() unless stateParams.id?

    @scope.listCtrl.actions = [@_actions.markAsSent, @_actions.print]

    # load invoice to display values
    Invoice.find stateParams.id, (err, invoice) =>
      return console.error err if err?
      @_onLoad invoice

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
        Object.assign @invoice, @_previous
        @_setChanged false
        @state.go toState.name, toParams

  # Goes back to list, after a confirmation if dancer has changed
  back: => @state.go 'invoices'

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
      Object.assign @invoice, @_previous
      @_previous = @invoice.toJSON()
      @_setChanged false
      @scope.$apply()

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
        return @dialog.messageBox(@i18n.ttl.invoiceError, err.message, [
            {label: @i18n.btn.ok}
          ]
        ).result.then done
      @_previous = @invoice.toJSON()
      console.log "invoice saved"
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
  displayDate: (date) => date?.format @i18n.formats.invoice

  # Invoked when date change in the date picker
  # Updates the invoice's' date
  setDate: =>
    return if @isReadOnly
    @invoice?.date = moment @dateOpts.value
    @_onChange 'date'

  # Select a given school
  #
  # @param value [Number] new selected school
  selectSchool: (value) =>
    @invoice?.selectedSchool = value
    @selectedSchool = value
    @_onChange 'selectedSchool'

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
      nw.Window.open 'app/template/invoice_print.html',
        frame: true
        icon: require('../../../package.json')?.window?.icon
        focus: true
        # size to A4 format, 3/4 height
        width: 1000
        height: 800
        , (created) =>
          @_preview = created
          # set parameters and wait for closure
          @_preview.invoice = @invoice
          @_preview.on 'closed', => @_preview = null

  # Add a new item to the current invoice
  addItem: =>
    return if @isReadOnly
    @invoice.items.push new InvoiceItem vat: if @withVat then @i18n.vat else 0
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
      item.vat = if @withVat then @i18n.vat else 0
    @_onChange 'item[0].vat'

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) =>
    return 'invalid' if @required.invoice?.includes field
    ''

  # **private**
  # initialize controller for a given invoice
  # @param invoice [Invoice] Loaded invoice
  _onLoad: (invoice) =>
    @invoice = invoice
    @isReadOnly = @invoice?.sent?
    @dateOpts.value = @invoice?.date.valueOf()
    @selectedSchool = @invoice?.selectedSchool or 0
    @required =
      invoice: []
      items: ([] for item in @invoice.items)
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
    next = [@_actions.markAsSent, @_actions.print]
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
      Invoice.isRefValid newRef, (err, isValid) =>
        unless isValid
          # in cas of invalidity, get the next ref for expected month
          matched = newRef.match(invoiceRefExtract) or []
          Invoice.getNextRef +matched[1] or moment().year(), +matched[2] or moment().month() + 1, (err, next) =>
            @suggestedRef = next unless err?
            @scope.$apply()

  # **private**
  # Check required fields when saving invoice
  #
  # @return true if a required field is missing
  _checkRequired: =>
    @required =
      invoice: []
      items: ([] for item in @invoice.items)
    # check the invoice itself
    @required.invoice.push 'ref' if isInvalidString @invoice?.ref
    @required.invoice.push 'date' if isInvalidDate @invoice?.date
    @required.invoice.push (field for field in ['name', 'street', 'city', 'zipcode'] when isInvalidString @invoice?.customer?[field])...
    # check each items
    for item, i in @invoice?.items or []
      @required.items[i].push 'name' if isInvalidString item.name
    # returns true if invoice or any of its item is missing a field
    @required.invoice.length isnt 0 or @required.items.some i -> i.length isnt 0

# Export as print controller for print preview, or classical node export
unless isPrintCtx
  module.exports = InvoiceController
else
  window.customClass = InvoiceController