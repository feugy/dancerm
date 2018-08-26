_ = require 'lodash'
moment = require 'moment'
i18n = require '../labels/common'

class PaymentDirective

  # Controller dependencies
  @$inject: ['$scope']

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
  constructor: (@scope) ->
    @receiptOpts =
      showWeeks: false
      startingDay: 1
      showButtonBar: false

    # reset receipt date to payement's one
    @receiptOpts.open = false
    @scope.$watch 'ctrl.src.receipt', =>
      @receiptOpts.value = if @src?.receipt?.isValid() then @src.receipt.valueOf() else null
    @scope.$watch 'ctrl.src.type', =>
      @setType @src?.type

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) =>
    return 'invalid' if @requiredFields? and field in @requiredFields
    ''

  # Updates the payment type of the source payment object
  #
  # @param type [String] selected type
  setType: (type) =>
    @src?.type = type
    @typeLabel = @i18n.paymentTypes[@src?.type] or ''
    @onChange? $field: 'type'

  # Invoked when date change in the date picker
  # Updates the dancer's birth date
  setReceipt: =>
    @src?.receipt = moment @receiptOpts.value
    @onChange? $field: 'receipt'

  # Opens the birth selection popup
  #
  # @param event [Event] click event, prevented.
  toggleReceipt: (event) =>
    # prevent, or popup won't show
    event?.preventDefault()
    event?.stopPropagation()
    @receiptOpts.open = not @receiptOpts.open

# The payment directive displays and edit dancer's payment
module.exports = (app) ->
  app.directive 'payment', ->
    # directive template
    templateUrl: 'payment.html'
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
      # ask for removal, concerned payement as 'model' parameter
      onRemove: '&?'
      # used to propagate model modifications, invoked with $field as parameter
      onChange: '&?'