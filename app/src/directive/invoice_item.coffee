{round} = require 'lodash'
InvoiceItem = require '../model/invoice_item'
i18n = require '../labels/common'

class InvoiceItemDirective

  # Controller dependencies
  @$inject: ['$scope']

  # computed and read-only VAT
  @property 'vat',
    get: -> @src?.vat * 100

  # Controller constructor: bind methods and attributes to current scope
  constructor: (@scope) ->

  # Apply taxes (if defined) to a duty-free value
  #
  # @param without {Number} duty-free value
  # @returns {Number} value with tax included
  applyTax: (without) =>
    round without * (1 + @scope.ctrl?.src?.vat), 2

  # Removes taxes (if defined) to get duty-free value
  #
  # @param withTax {Number} value with tax included
  # @returns {Number} duty-free value
  removeTax: (withTax) =>
    round withTax / (1 + @scope.ctrl?.src?.vat), 2

# The invoice item directive displays and allows to edit a given invoice item
module.exports = (app) ->
  app.directive 'invoiceItem', ->
    # directive template
    templateUrl: "invoice_item.html"
    # will replace hosting element
    replace: true
    # transclusion is needed to be properly used within ngRepeat
    transclude: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: InvoiceItemDirective
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope:
      # invoide item displayed
      src: '='
      # read-only flag.
      readOnly: '=?'
      # removal handler, used when item needs to be removed
      onRemove: '&?'
      # used to propagate model modifications, invoked with $field as parameter
      onChange: '&?'
