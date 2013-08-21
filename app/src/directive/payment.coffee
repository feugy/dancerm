define [
  'jquery'
  'underscore'
  'moment'
  'i18n!nls/common'
  '../app'
], ($, _, moment, i18n, app) ->

  # The payment directive displays and edit dancer's payment
  app.directive 'payment', ->
    # directive template
    templateUrl: "payment.html"
    # will replace hosting element
    replace: true
    # transclusion is needed to be properly used within ngRepeat
    transclude: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: PaymentDirective
    # parent scope binding.
    scope: 
      # displayed payment
      src: '='
      # ask for removal
      onRemove: '&'
  
  class PaymentDirective
                  
    # Controller dependencies
    @$inject: ['$scope', '$element', '$compile']
    
    # Controller scope, injected within constructor
    scope: null
    
    # JQuery enriched element for directive root
    $el: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] directive scope
    # @param element [DOM] directive root element
    constructor: (@scope, element, @compile) ->
      @$el = $(element)
      @scope.i18n = i18n
      @scope.receiptValid = true
      @scope.$watch 'src', @_onDisplayPayment
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # Updates the payment type of the source payment object
    #
    # @param type [String] selected type
    onUpdateType: (type) =>
      @scope.src.type = type
      @scope.typeLabel = i18n.paymentTypes[@scope.src.type]

    # Validates the value input and only accepts numbers
    #
    # @param event [event] key-up event
    onValueInput: (event) =>
      @scope.stringValue = $(event.target).val().replace /[^\d\.]/g, ''
      # invoke method inheritted from parent scope
      @scope.src.value = parseFloat @scope.stringValue
      @scope.$parent.$parent.onPaymentChanged()

    # Validates the receipt input and only accepts dates
    #
    # @param event [event] key-up event
    onReceiptInput: =>
      # parse input (moment does not allow empty input)
      receipt = moment @scope.receipt or 'empty', i18n.formats.receipt
      # set validation class
      @scope.receiptValid = receipt.isValid()
      #updates model only if valid
      @scope.src.receipt = receipt if @scope.receiptValid

    # **private**
    # When displayed payment changed, refresh rendering
    _onDisplayPayment: =>
      # get the friendly labels for type
      @onUpdateType @scope.src.type
      @scope.stringValue = @scope.src.value
      @scope.receipt = @scope.src.receipt.format i18n.formats.receipt