async = require 'async'
i18n = require '../labels/common'
DanceClass = require '../model/danceclass'
Payment = require '../model/payment'

class RegistrationDirective
                
  # Controller dependencies
  @$inject: ['$scope', '$element', 'dialog', '$filter', '$rootScope']
  
  # i18n labels, for rendering
  i18n: i18n

  # JQuery enriched element for directive root
  $el: null

  # Angular's dialog service
  dialog: null

  # Displayed registration
  registration: null

  # Array of card's dancer, to display dance classes
  dancers: []

  # Array of arrays of dance classes for this season.
  # Has the same number of elements as 'dancers'.
  classesPerDancer: []
  
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
  # @param rootScope [Object] Angular root scope
  constructor: (@scope, element, @dialog, @filter, rootScope) ->
    @$el = $(element)
    @scope.$watchGroup ['ctrl.registration', 'ctrl.dancers'], => @_updateRendering @registration, @dancers
    @_updateRendering @registration, @dancers

    # on cancellation, restore previous payments
    rootScope.$on 'cancel-edit', =>
      return unless @registration? and @_previousPayments?
      @registration.payments.splice.apply @registration.payments, [0, @registration.payments.length].concat @_previousPayments
  
  # Creates a new payment and adds it to the current registration
  addPayment: =>
    @registration.payments.push new Payment payer: @dancers[0].lastname
    @requiredFields.push []
    @_onChange()
    setTimeout =>
      @$el.find('.type .scrollable').last().focus()
    , 100
    null

  # Updates the payment period of the source registration object
  #
  # @param period [String] selected period
  setPeriod: (period) =>
    @registration.period = period
    @periodLabel = @i18n.periods[@registration.period]

  # Compute the registration balance
  #
  # @return a class reflecting balance state
  getBalanceState: =>
    due = @registration.due()
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
        @_onChange()

  # **private**
  # Update internal state when displayed registration or card has changed.
  #
  # @param registration [Registration] new registration value
  # @param dancers [Array<Dancer>] new dancers value
  _updateRendering: (registration, dancers) =>
    if @registration?
      @registration?.removeListener 'change', @_onChange
    if @dancers?
      dancer?.removeListener 'change', @_onChange for dancer in @dancers

    @registration = registration
    @registration?.on 'change', @_onChange
    # get the friendly labels for period
    @setPeriod @registration?.period

    # early resolve dance class
    async.map dancers, (dancer, next) =>
      dancer.getClasses next
    , (err, danceClasses) =>
      console.error err if err?
      @classesPerDancer = []
      @dancers = []
      # filter dancers that do not have classes for this registration
      for dancer, i in dancers
        classes =  (clazz for clazz in danceClasses[i] when clazz.season is @registration?.season)
        if classes.length > 0
          dancer?.on 'change', @_onChange 
          @classesPerDancer.push classes
          @dancers.push dancer

      # initialize required payment fields
      @requiredFields = ([] for payment in @registration?.payments)
      # make a copy for cancellation
      @_previousPayments = (new Payment payment.toJSON() for payment in @registration?.payments)
      # update rendering
      @scope.apply()

  # **private**
  # Value change handler: relay to card parent.
  _onChange: => @onChange?(model: @registration)

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
      # array of missing fields
      requiredFields: '='
      # invoked when printing the registration
      onPrint: '&?'
      # invoked when registration needs to be removed. Concerned registration is a 'model' parameter
      onRemove: '&?'
