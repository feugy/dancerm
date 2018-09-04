{roundEuro} = require '../util/common'
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
    # global change handler, to catch all types of change (prefill, manual editing)
    @scope.$watch 'ctrl.src', =>
      @onChange?($field:'')
    , true

  # Apply taxes (if defined) to a duty-free value
  #
  # @param without {Number} duty-free value
  # @returns {Number} value with tax included
  applyTax: (without) =>
    # roundEuro without * (1 + @src?.vat), 2
    round without * (1 + @src?.vat), 2

  # Removes taxes (if defined) to get duty-free value
  #
  # @param withTax {Number} value with tax included
  # @returns {Number} duty-free value
  removeTax: (withTax) =>
    # roundEuro withTax / (1 + @src?.vat), 2
    round withTax / (1 + @src?.vat), 2

  # Prefill current edited values with given option
  #
  # @param option {Object} option assigned to current edited values
  prefill: (option) =>
    @src.name = option.name
    @src.quantity = option.quantity
    @src.price = option.price

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) =>
    return 'invalid' if @requiredFields?.includes field
    ''

# The invoice item directive displays and allows to edit a given invoice item
module.exports = (app) ->
  app.directive 'invoiceItem', ->
    # directive template
    # Can't be set as template URL because during printing, the template can't be fetched (without explanation...)
    template: """
<div class="invoice-item focusable" data-ng-class="ctrl.readOnly ? 'read-only' : ''">
  <button class="btn remove" data-ng-if="!ctrl.readOnly" data-ng-click="ctrl.onRemove()"><i class="glyphicon glyphicon-trash"/></button>
  <span class="name">
    <textarea data-auto-height readonly data-ng-if="ctrl.readOnly" data-ng-model="::ctrl.src.name"></textarea>
    <span data-ng-if="!ctrl.readOnly" class="input-group" data-uib-dropdown keyboard-nav>
      <textarea data-auto-height name="name" data-ng-model="ctrl.src.name" data-ng-class="ctrl.isRequired('name')" data-set-null></textarea>
      <a href="" class="input-group-addon" uib-dropdown-toggle><i class="glyphicon glyphicon-triangle-bottom"></i></a>
      <ul class="dropdown-menu price-list">
        <li data-ng-repeat="price in ctrl.priceList.flatList()">
          <a href="" data-ng-if="!price.category" data-ng-click="ctrl.prefill(price)">{{price.label || price.name}}</a>
          <span data-ng-if="price.category" class="category">{{price.category}}</span>
        </li>
      </ul>
    </span>
  </span>
  <span class="quantity">
    <span data-ng-if="ctrl.readOnly">{{::ctrl.src.quantity}}</span>
    <input type="number" name="quantity" data-ng-model="ctrl.src.quantity" data-ng-class="ctrl.isRequired('quantity')" data-ng-if="!ctrl.readOnly" data-set-zero/>
  </span>
  <span class="price" data-ng-if="!ctrl.readOnly">
    <filtered-input class="duty-free-input" type="number" name="price" data-parse="ctrl.applyTax" data-format="ctrl.removeTax" data-ng-model="ctrl.src.price" data-ng-class="ctrl.isRequired('price')" data-set-zero></filtered-input>{{'lbl.currency'|i18n}}
  </span>
  <span class="price" data-ng-if="ctrl.readOnly">{{::ctrl.removeTax(ctrl.src.price)}}{{'lbl.currency'|i18n}}</span>
  <span class="discount">
    <span data-ng-if="ctrl.readOnly">{{::ctrl.src.discount}}</span>
    <input type="number" name="discount" data-ng-model="ctrl.src.discount" data-ng-class="ctrl.isRequired('discount')" data-ng-if="!ctrl.readOnly" data-set-zero/>%
  </span>
  <span class="vat" data-ng-if="ctrl.withVat">{{ctrl.vat|number}}%</span>
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
      # array of missing fields
      requiredFields: '='
      # the price list used to prefill src.
      priceList: '=?'
      # read-only flag.
      readOnly: '=?'
      # Vat column flag.
      withVat: '=?'
      # removal handler, used when item needs to be removed
      onRemove: '&?'
      # used to propagate model modifications, invoked with $field as parameter
      onChange: '&?'
