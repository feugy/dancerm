_ = require 'underscore'
{generateId} = require '../util/common'
Address = require '../model/address'

class AddressDirective
                
  # Controller dependencies
  @$inject: ['$scope']

  # edited address
  src: null

  # **private**
  # Edited address's previous values
  _previous: {}

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive own scope, used to detect changes
  constructor: (@scope) ->
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

  # **private**
  # Update internal state when displayed dancer has changed.
  #
  # @param value [Dancer] new dancer's value
  _updateRendering: (value) =>
    @src?.removeListener 'change', @_onChange
    @src = value 
    @src?.on 'change', @_onChange
    @_previous = @src?.toJSON()
    # store previous version for cancellation and change detection, if editable

  # **private**
  # Value change handler: check if dancer has changed from its previous values
  _onChange: =>
    # TODO waiting for https://github.com/angular/angular.js/pull/7645
    @scope.onChange?(model: @src, hasChanged: @src?._v is -1 or not _.isEqual @_previous, @src?.toJSON())

# The payment directive displays and edit dancer's payment
module.exports = (app) ->
  app.directive 'address', ->
    # directive template
    templateUrl: "address.html"
    # will replace hosting element
    replace: true
    # transclusion is needed to be properly used within ngRepeat
    transclude: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: AddressDirective
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope: 
      # address is displayed
      src: '='
      # read-only flag.
      readOnly: '=?'
      # array of missing fields
      requiredFields: '='
      # affectation handler, used when address needs to be changed
      onAffect: '&'
      # change handler. Concerned address is a 'model' parameter, change status is a 'hasChagned' parameter
      onChange: '&?'
