define [
  'jquery'
  'underscore'
  'i18n!nls/common'
  '../model/planning/planning'
  '../model/dancer/payment'
  '../app'
], ($, _, i18n, Planning, Payment, app) ->

  # The registration directive displays dancer's registration to dance classes and their payments
  app.directive 'registration', ->
    # directive template
    templateUrl: 'registration.html'
    # will remplace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: RegistrationDirective
    # parent scope binding.
    scope: 
      # displayed registration
      src: '='
      # invoked when registration needs editing
      onEdit: '&'
      # invoked when registration needs removal
      onRemove: '&'
  
  class RegistrationDirective
                  
    # Controller dependencies
    @$inject: ['$scope', '$element', '$dialog']
    
    # Controller scope, injected within constructor
    scope: null
    
    # JQuery enriched element for directive root
    $el: null

    # Angular's dialog service
    dialog: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] directive scope
    # @param element [DOM] directive root element
    # @param dialog [Object] Angular's dialog service
    constructor: (@scope, element, @dialog) ->
      @$el = $(element)
      @scope.i18n = i18n
      # class use to highlight the balance state
      @scope.balanceState = ""
      @scope.$watch 'src', @_onDisplayRegistration
      @scope.$watchCollection 'src.danceClassIds', @_onDisplayRegistration
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # Creates a new payment and adds it to the current registration
    onNewPayment: =>
      @scope.src.payments.push new Payment()

    # Invoked each time a payment value changed
    # Updates the registration balance
    onPaymentChanged: =>
      @scope.src.updateBalance()
      if @scope.src.balance < @scope.src.charged 
        @scope.balanceState = 'balance-low' 
      else if @scope.src.charged isnt 0 
        @scope.balanceState = 'balance-right'
      else 
        @scope.balanceState = ''

    # Invoked when a payment needs to be removed.
    # Confirm operation with a modal popup and proceed to the removal
    #
    # @param removed [Payment] the removed payment model
    onRemovePayment: (removed) =>
      @dialog.messageBox(i18n.ttl.confirmRemove, 
        _.sprintf(i18n.msg.removePayment, i18n.paymentTypes[removed.type], removed.value), 
        [
          {result: false, label: i18n.btn.no}
          {result: true, label: i18n.btn.yes, cssClass: 'btn-warning'}
        ]).open().then (confirm) =>
          return unless confirm
          @scope.src.payments.splice @scope.src.payments.indexOf(removed), 1
          @onPaymentChanged()

    # Validates the charged input and only accepts numbers
    #
    # @param event [event] key-up event
    onChargedInput: (event) =>
      @scope.stringCharged = $(event.target).val().replace /[^\d\.]/g, ''
      # invoke method inheritted from parent scope
      @scope.src.charged = parseFloat @scope.stringCharged
      @onPaymentChanged()

    # **private**
    # When displayed registration changed, refresh rendering by retrieving planning and selected dance classes
    _onDisplayRegistration: =>
      # gets all dance classes details from the models
      Planning.find @scope.src.planningId, (err, planning) =>
        throw err if err?
        # sets year for displayal
        @scope.year = planning.year
        # retrieves full dance class objects from their ids
        @scope.danceClasses = (
          for id in @scope.src.danceClassIds
            _.findWhere planning.danceClasses, id: id
        )
        @scope.stringCharged = @scope.src.charged
        @scope.$apply()