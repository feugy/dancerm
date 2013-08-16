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
    @$inject: ['$scope', '$element']
    
    # Controller scope, injected within constructor
    scope: null
    
    # JQuery enriched element for directive root
    $el: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] directive scope
    # @param element [DOM] directive root element
    constructor: (@scope, element) ->
      @$el = $(element)
      @scope.i18n = i18n
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

    # Validates the charged input and only accepts numbers
    #
    # @param event [event] key-up event
    onChargedInput: (event) =>
      @scope.stringCharged = $(event.target).val().replace /[^\d\.]/g, ''
      # invoke method inheritted from parent scope
      @scope.src.charged = parseFloat @scope.stringCharged

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