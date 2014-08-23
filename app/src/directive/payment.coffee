_ = require 'underscore'
moment = require 'moment'
i18n = require '../labels/common'

class PaymentDirective
                
  # Controller dependencies
  @$inject: ['$scope', '$element']
  
  # Labels, for rendering
  i18n: i18n
  
  # Type label displayed
  typeLabel: ''

  # Option used to configure receipt selection popup
  receiptOpts: 
    value: null
    open: false
    showWeeks: false
    startingDay: 1
    showButtonBar: false
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  constructor: (@scope, element) ->
    @$el = $(element)

    @receiptOpts =
      showWeeks: false
      startingDay: 1
      showButtonBar: false

    # TODO waiting for https://github.com/angular/angular.js/pull/7645
    @scope.$watch 'src', => @_updateRendering @scope.src
    @_updateRendering @scope.src

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) => 
    return '' unless @scope?
    return 'invalid' if field in @scope.requiredFields
    ''
    
  # Updates the payment type of the source payment object
  #
  # @param type [String] selected type
  setType: (type) =>
    @src?.type = type
    @typeLabel = @i18n.paymentTypes[@src?.type] or ''

  # Invoked when date change in the date picker
  # Updates the dancer's birth date
  setReceipt: =>
    @src?.receipt = moment @receiptOpts.value
    @_onChange()
    
  # Opens the birth selection popup
  #
  # @param event [Event] click event, prevented.
  toggleReceipt: (event) =>
    # prevent, or popup won't show
    event?.preventDefault()
    event?.stopPropagation()
    @receiptOpts.open = not @receiptOpts.open

  # Ask to parent controller to remove this payment
  remove: =>
    @scope.onRemove?(model: @src)

  # **private**
  # Update internal state when displayed dancer has changed.
  #
  # @param value [Dancer] new dancer's value
  _updateRendering: (value) =>
    @src?.removeListener 'change', @_onChange
    @src = value
    @src?.on 'change', @_onChange
    @setType @src?.type

    # reset receipt date to payement's one
    @receiptOpts.open = false
    @receiptOpts.value = if moment.isMoment @src?.receipt then @src?.receipt.toDate() else null

  # **private**
  # Value change handler: relay to registration parent.
  _onChange: =>
    # TODO waiting for https://github.com/angular/angular.js/pull/7645
    @scope.onChange?(model: @src)

# The payment directive displays and edit dancer's payment
module.exports = (app) ->
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
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope: 
      # displayed payment
      src: '='
      # array of missing fields
      requiredFields: '='
      # change handler. Concerned dancer is a 'model' parameter, no change detection are performed
      onChange: '&?'
      # ask for removal, concerned payement as 'model' parameter
      onRemove: '&?'