_ = require 'lodash'
moment = require 'moment'
isPrintCtx = not module?
# if used in print context, path to other dependencies are different
i18n = require "../#{if isPrintCtx then 'script/' else ''}labels/common"
Invoice = require "../#{if isPrintCtx then 'script/' else ''}model/invoice"
{invoiceRefExtract} = require "../#{if isPrintCtx then 'script/' else ''}util/common"

# Displays and edits a given invoice
# Also usable as print controller
class InvoiceController

  # Controller dependencies
  @$inject: ['$scope', '$rootScope'].concat unless isPrintCtx then ['dialog', '$filter', '$stateParams'] else []

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

  # Option used to configure date selection popup
  dateOpts:
    value: null
    open: false
    showWeeks: false
    startingDay: 1
    showButtonBar: false

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
  # @param stateParams [Object] invokation route parameters
  constructor: (@scope, @rootScope, @dialog, @filter, stateParams) ->
    @invoice = null
    @hasChanged = false
    @_modalOpened = false
    @_previous = {}
    @isReadOnly = false
    @suggestedRef = null

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

    @scope.listCtrl.actions = [
      {label: 'btn.markAsSent', icon: 'send', action: @markAsSent}
      {label: 'btn.print', icon: 'print', action: @print}
    ]

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
        # if confirmed, effectively go on desired state
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
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no problem occured
  save: (done = ->) =>
    return done null unless @hasChanged and not @isReadOnly
    console.log "save invoice #{@invoice.ref} (#{@invoice.id})"
    @invoice.save (err) =>
      if err?
        console.error err
        return done err
      @_previous = @invoice.toJSON()
      console.log "invoice saved"
      @_onChange()
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
      @save (err) =>
        return if err?
        # reset everything to reflect read-only state
        @_onLoad @invoice

  # Invoked when date change in the date picker
  # Updates the invoice's' date
  setDate: =>
    return if @isReadOnly
    @invoice?.date = moment @dateOpts.value
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
    @save (err) =>
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

  # @returns [String] formated date for printing
  displayDate: => @invoice?.date.format @i18n.formats.invoice

  # **private**
  # initialize controller for a given invoice
  # @param invoice [Invoice] Loaded invoice
  _onLoad: (invoice) =>
    @invoice = invoice
    @isReadOnly = @invoice?.sent?
    @dateOpts.value = @invoice?.date.valueOf()
    @_previous = @invoice.toJSON()
    console.log "load invoice #{@invoice.ref} (#{@invoice.id})"
    # reset changes and displays everything
    @_setChanged false
    # remove all buttons except print if relevant
    @scope.listCtrl?.actions.splice 0, @scope.listCtrl?.actions.length - 1 if @isReadOnly
    @scope.$apply() unless @scope.$$phase

  # **private**
  # Update hasChanged flag and contextual actions
  #
  # @param changed [Boolean] new hasChanged flag value
  _setChanged: (changed) =>
    if changed
      if @invoice._v > 0
        # can cancel only if already saved once
        @scope.listCtrl.actions.splice 0, 0, {label: 'btn.cancel', icon: 'ban-circle', action: @cancel}
      @scope.listCtrl.actions.splice 0, 0, {label: 'btn.save', icon: 'floppy-disk', action: @save}
    else if @hasChanged
      # remove save and cancel
      @scope.listCtrl.actions.splice 0, if @invoice._v > 0 then 2 else 1
    @hasChanged = changed

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

# Export as print controller for print preview, or classical node export
unless isPrintCtx
  module.exports = InvoiceController
else
  window.customClass = InvoiceController