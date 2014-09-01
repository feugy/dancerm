_ = require 'underscore'
{generateId} = require '../util/common'
Address = require '../model/address'

class AddressDirective
                
  # Controller dependencies
  @$inject: ['$scope']

  # **private**
  # Edited address's previous values
  _previous: {}

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive own scope, used to detect changes
  constructor: (scope) ->
    scope.$watch 'ctrl.src', => @_updateRendering @src
    @_updateRendering @src

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) => 
    return 'invalid' if @requiredFields? and field in @requiredFields
    ''

  # **private**
  # Update internal state when displayed dancer has changed.
  #
  # @param value [Dancer] new dancer's value
  _updateRendering: (value) =>
    @src?.removeListener 'change', @_onChange
    @src = value 
    @src?.on 'change', @_onChange
    # store previous version for cancellation and change detection, if editable
    @_previous = @src?.toJSON()

  # **private**
  # Value change handler: check if dancer has changed from its previous values
  _onChange: =>
    @onChange?(model: @src, hasChanged: @src?._v is -1 or not _.isEqual @_previous, @src?.toJSON())

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
      # removal flag.
      canRemove: '=?'
      # array of missing fields
      requiredFields: '='
      # affectation handler, used when address needs to be changed
      onAffect: '&'
      # removal handler, used when address needs to be removed
      onRemove: '&'
      # change handler. Concerned address is a 'model' parameter, change status is a 'hasChagned' parameter
      onChange: '&?'
