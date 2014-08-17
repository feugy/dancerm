_ = require 'underscore'
i18n = require '../labels/common'
DanceClass = require '../model/danceclass'
Payment = require '../model/payment'

class RegistrationDirective
                
  # Controller dependencies
  @$inject: ['$scope', '$element', 'dialog']
  
  # Controller scope, injected within constructor
  scope: null

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
  
  # Selected period label
  periodLabel: ''

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param dialog [Object] Angular's dialog service
  constructor: (@scope, element, @dialog) ->
    @$el = $(element)

    # TODO waiting for https://github.com/angular/angular.js/pull/7645
    @scope.$watchGroup ['scope.registration', 'scope.dancers'], => @_updateRendering @scope.registration, @scope.dancers
    @_updateRendering @scope.registration, @scope.dancers
    
    #@scope.$watchCollection 'src.card.dancers.danceClassIds', @_onDisplayRegistration
  
  # Creates a new payment and adds it to the current registration
  addPayment: =>
    @registration.payments.push new Payment payer: @dancers[0].lastname
    @_onChange()
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
    if @registration.balance < @registration.charged 
      'balance-low' 
    else if @registration.charged isnt 0 
      'balance-right'
    else 

  # Filter dancers when displaying registered dance classes
  #
  # @param dancer [Dancer] tested dancer
  # @return true if this dancer has classes for this season
  filterDancer: (dancer) =>
    # TODO for now, promise are not supported in filters. Use resolve dance classes
    return unless dancer._danceClasses?
    # quit at first class of the current season 
    return true for danceClass in dancer._danceClasses when danceClass.season is @registration.season
    false

  # Filter dance classes when displaying them
  #
  # @param danceClass [DanceClass] tested class
  # @return trur if this dance class belongs to the current season
  filterDanceCalss: (danceClass) => danceClass?.season is @registration.season

  # Invoked when a payment needs to be removed.
  # Confirm operation with a modal popup and proceed to the removal
  #
  # @param removed [Payment] the removed payment model
  removePayment: (removed) =>
    @dialog.messageBox(@i18n.ttl.confirm, 
      _.sprintf(@i18n.msg.removePayment, 
        @i18n.paymentTypes[removed.type], 
        removed.value, 
        removed.receipt.format @i18n.formats.receipt), 
      [
        {result: false, label: @i18n.btn.no}
        {result: true, label: @i18n.btn.yes, cssClass: 'btn-warning'}
      ]).result.then (confirm) =>
        return unless confirm
        @registration.payments.splice @registration.payments.indexOf(removed), 1
        @_onChange()

  # **private**
  # Update internal state when displayed registration or card has changed.
  #
  # @param registration [Registration] new registration value
  # @param dancers [Array<Dancer>] new dancers value
  _updateRendering: (registration, dancers) =>
    if registration?
      @registration?.removeListener 'change', @_onChange
      @registration = registration 
      @registration?.on 'change', @_onChange
      # get the friendly labels for period
      @setPeriod @registration.period
    if dancers?
      if @dancers?
        dancer?.removeListener 'change', @_onChange for dancer in @dancers
      @dancers = dancers
      dancer?.on 'change', @_onChange for dancer in @dancers
    @_onChange()

  # **private**
  # Value change handler: relay to card parent.
  _onChange: =>
    # TODO waiting for https://github.com/angular/angular.js/pull/7645
    @scope.onChange?(model: @registration)

# The registration directive displays dancer's registration to dance classes and their payments
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
    # invoked when registration needs editing
    #onEdit: '&'
    # invoked when registration needs removal
    #onRemove: '&'
    # invoked when printing the registration
    #onPrint: '&'