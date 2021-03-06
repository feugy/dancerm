{map} = require 'async'
moment = require 'moment'
i18n = require '../labels/common'
DanceClass = require '../model/dance_class'
Payment = require '../model/payment'

class RegistrationDirective

  # Controller dependencies
  @$inject: ['$scope', '$element', 'dialog', '$filter', 'conf', '$rootScope']

  # i18n labels, for rendering
  i18n: i18n

  # enriched element for directive root
  element: null

  # Configuration service
  conf: null

  # Angular's dialog service
  dialog: null

  # Displayed registration
  registration: null

  # Array of card's dancer, to display dance classes
  dancers: []

  # Array of arrays of dance classes for this season.
  # Concerned dancers id is used as key
  classesPerDancer: {}

  # Selected period label
  periodLabel: ''

  # temporary array to restore previous payment in case of cancellation
  _previousPayments: []

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param dialog [Object] Angular's dialog service
  # @param filter [Function] Angular's filters factory
  # @param conf [Object] configuration service
  # @param rootScope [Object] Angular root scope
  constructor: (@scope, @element, @dialog, @filter, @conf, rootScope) ->
    unwatches = []
    unwatches.push @scope.$on 'dance-classes-changed', (event, dancer) =>
      @_updateRendering() if dancer in @dancers

    # on cancellation, restore previous payments
    unwatches.push rootScope.$on 'cancel-edit', =>
      return unless @registration? and @_previousPayments?
      @registration.payments.splice.apply @registration.payments, [0, @registration.payments.length].concat @_previousPayments

    @scope.$on '$destroy', -> unwatch?() for unwatch in unwatches
    setTimeout @_updateRendering, 0

  # Creates a new payment and adds it to the current registration
  addPayment: =>
    receipt = moment()
    # when regitration period is quarter, get last payment date and add 3 month
    if @registration.period is 'quarter'
      last = @registration.payments.map((p) => p.receipt.valueOf()).sort().pop()
      receipt = moment(last).add 3, 'month' if last?

    @registration.payments.push new Payment
      payer: @dancers[0].lastname
      receipt:  receipt

    @requiredFields.push []
    setTimeout =>
      @element.find('.type .scrollable').last().focus()
    , 100
    @_onChange 'payments'
    # to be used directly in DOM
    null

  # Updates the payment period of the source registration object
  #
  # @param period [String] selected period
  setPeriod: (period) =>
    return unless @registration?
    @registration.period = period
    @periodLabel = @i18n.periods[@registration.period]
    @_onChange 'period'

  # Compute the registration balance
  #
  # @return a class reflecting balance state
  getBalanceState: =>
    due = @registration?.due()
    if  due > 0
      'balance-low'
    else if due is 0
      'balance-right'
    else
      ''
  # Invoked when a payment needs to be removed.
  # Confirm operation with a modal popup and proceed to the removal
  #
  # @param removed [Payment] the removed payment model
  removePayment: (removed) =>
    @dialog.messageBox(@i18n.ttl.confirm,
      @filter('i18n')('msg.removePayment', args:
        type: @i18n.paymentTypes[removed.type]
        value: removed.value
        receipt: removed.receipt.format @i18n.formats.receipt),
      [
        {result: false, label: @i18n.btn.no}
        {result: true, label: @i18n.btn.yes, cssClass: 'btn-warning'}
      ]).result.then (confirm) =>
        return unless confirm
        idx = @registration.payments.indexOf(removed)
        @registration.payments.splice idx, 1
        @requiredFields.splice idx, 1
        @_onChange "payments"

  # **private**
  # Update internal state when displayed registration or card has changed.
  _updateRendering: =>
    # get the friendly labels for period
    @setPeriod @registration?.period

    # early resolve dance class
    map @dancers, (dancer, next) =>
      dancer.getClasses next
    , (err, danceClasses) =>
      console.error err if err?
      @classesPerDancer = {}
      # only display dancers that have classes for this registration
      for dancer, i in @dancers
        classes = (clazz for clazz in danceClasses[i] when clazz.season is @registration?.season)
        if classes.length > 0
          @classesPerDancer[dancer.id] = classes

      if @registration?.payments?
        # initialize required payment fields
        @requiredFields = ([] for payment in @registration.payments)
        # make a copy for cancellation
        @_previousPayments = (new Payment payment.toJSON() for payment in @registration.payments)
      else
        @requiredFields = []
        @_previousPayments = []
      # update rendering
      @scope.$apply() unless @scope.$$phase

  # **private**
  # Relay change events
  #
  # @param field [String] modified field
  _onChange: (field) =>
    # update balance on payment modification
    @registration?.updateBalance() if 0 is field.indexOf 'payments'
    @onChange $field: field

# The registration directive displays dancer's registration to dance classes and their payments
module.exports = (app) ->
  app.directive 'registration', ->
    # directive template
    templateUrl: 'registration.html'
    # will remplace hosting element
    replace: true
    # transclusion is needed to be properly used within ngRepeat
    transclude: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: RegistrationDirective
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope:
      # card's dancers
      dancers: '='
      # displayed registration
      registration: '=src'
      # array of sent invoices for that registration
      invoices: '='
      # array of missing fields
      requiredFields: '='
      # invoked when printing settlement for that registration
      onPrintSettlement: '&?'
      # invoked when registration needs to be removed. Concerned registration is a 'model' parameter
      onRemove: '&?'
      # used to propagate model modifications, invoked with $field as parameter
      onChange: '&?'
      # invoked when editing invoice for that registration and given a selected teacher
      onEditInvoice: '&?'
      # invoked when displaying a sent invoice for that registration
      onDisplayInvoice: '&?'
