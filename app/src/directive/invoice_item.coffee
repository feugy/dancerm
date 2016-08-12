{round} = require 'lodash'
InvoiceItem = require '../model/invoice_item'
i18n = require '../labels/common'

class InvoiceItemDirective

  # Controller dependencies
  @$inject: ['$scope', '$element']

  # computed and read-only VAT
  @property 'vat',
    get: -> @src?.vat * 100

  # Controller constructor: bind methods and attributes to current scope
  constructor: (@scope, element) ->
    @scope.$watch 'ctrl.src.vat', =>
      # force price re-render because it depends on VAT
      setTimeout () =>
        angular.element(element[0].querySelector('.duty-free-input')).trigger 'blur'
      , 0

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
    template: """
<div class="invoice-item focusable" data-ng-class="ctrl.readOnly ? 'read-only' : ''">
  <button class="btn remove" data-ng-if="!ctrl.readOnly" data-ng-click="ctrl.onRemove()"><i class="glyphicon glyphicon-trash"/></button>
  <span class="name">
    <span data-ng-if="ctrl.readOnly">{{::ctrl.src.name}}</span>
    <input type="text" name="name" data-ng-model="ctrl.src.name" data-ng-change="ctrl.onChange({$field:'name'})" data-ng-if="!ctrl.readOnly" data-set-null/>
  </span>
  <span class="quantity">
    <span data-ng-if="ctrl.readOnly">{{::ctrl.src.quantity}}</span>
    <input type="number" name="quantity" data-ng-model="ctrl.src.quantity" data-ng-change="ctrl.onChange({$field:'quantity'})" data-ng-if="!ctrl.readOnly" data-set-zero/>
  </span>
  <span class="price" data-ng-if="!ctrl.readOnly">
    <filtered-input class="duty-free-input" type="number" name="price" data-parse="ctrl.applyTax" data-format="ctrl.removeTax" data-ng-model="ctrl.src.price" data-ng-change="ctrl.onChange({$field:'price'})" data-set-zero></filtered-input>{{'lbl.currency'|i18n}}
  </span>
  <span class="price" data-ng-if="ctrl.readOnly">{{::ctrl.removeTax(ctrl.src.price)}}{{'lbl.currency'|i18n}}</span>
  <span class="vat">{{ctrl.vat|number}}%</span>
  <span class="total">{{ctrl.src.dutyFreeTotal|number}}{{'lbl.currency'|i18n}}</span>
</div>"""
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
      # invoice item displayed
      src: '='
      # read-only flag.
      readOnly: '=?'
      # removal handler, used when item needs to be removed
      onRemove: '&?'
      # used to propagate model modifications, invoked with $field as parameter
      onChange: '&?'
