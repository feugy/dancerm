_ = require 'lodash'
i18n = require '../labels/common'
Invoice = require '../model/invoice'

# Displays and edits a given invoice
module.exports = class InvoiceController

  # Controller dependencies
  @$inject: ['$scope', '$rootScope', '$stateParams']

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

  # displayed invoice
  invoice: null

  # flag indicating wether the invoice has been changed or not
  hasChanged: false

  # **private**
  # Store if a modal is currently opened
  _modalOpened: false

  # **private**
  # Stores previous models values (model id used as key) for change detection
  _previous: {}

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Controller's own scope, for change detection
  # @param rootscope [Object] Angular global scope for digest triggering
  # @param stateParams [Object] invokation route parameters
  constructor: (@scope, @rootScope, stateParams) ->
    @invoice = null
    @hasChanged = false
    @_modalOpened = false
    @_previous = {}

    # redirect to invoice list if needded
    return @back() unless stateParams.id?

    # load invoice to display values
    @load stateParams.id

    @rootScope.$on '$stateChangeStart', (event, toState, toParams) =>
      return unless @hasChanged
      # stop state change until user choose what to do with pending changes
      event.preventDefault()
      # confirm if dancer changed
      @dialog.messageBox(@i18n.ttl.confirm, i18n.msg.confirmGoBack, [
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

  # loads a given invoide from its id
  # @param id [String] Loaded invoice's id
  load: (id) =>
    Invoice.find id, (err, invoice) =>
      return console.error err if err?
      @invoice = invoice
      @_previous = @invoice.toJSON()
      console.log "load invoice #{invoice.ref} (#{invoice.id})"
      # reset changes and displays everything
      @_setChanged false
      @scope.$apply()

  # restore previous values
  cancel: =>
    return unless @hasChanged and not @_modalOpened
    @_modalOpened = true
    @dialog.messageBox(@i18n.ttl.confirm,
      @filter('i18n')('msg.cancelEdition', args: name: @invoice.ref), [
        {label: @i18n.btn.no, cssClass: 'btn-warning'}
        {label: @i18n.btn.yes, result: true}
      ]
    ).result.then (confirmed) =>
      @_modalOpened = false
      return unless confirmed
      # cancel and restore values by reloadingfrom storage
      @rootScope.$broadcast 'cancel-edit'
      @load @invoice.id

  # Save the current values inside storage
  #
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no problem occured
  save: (done = ->) =>
    return done null unless @hasChanged
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

  # **private**
  # Update hasChanged flag and contextual actions
  #
  # @param changed [Boolean] new has changed flag value
  _setChanged: (changed) =>
    if changed
      if @invoice._v > 0
        # can cancel only if already saved once
        @scope.listCtrl.actions.splice 0, 0, {label: 'btn.cancel', icon: 'ban-circle', action: @cancel}
      @scope.listCtrl.actions.splice 0, 0, {label: 'btn.save', icon: 'floppy-disk', action: @save}
    else if @hasChanged
      # remove save and cancel
      @scope.listCtrl.actions.splice 0, 2
    @hasChanged = changed

  # **private**
  # Change handler: check if any displayed model has changed from its previous values
  #
  # @param field [String] modified field
  _onChange: (field) =>
    # performs comparison between current and old values
    @_setChanged false
    if not _.isEqual @_previous, @invoice.toJSON()
      # console.log "invoice has changed on #{field}"
      # quit at first modification
      return @_setChanged true