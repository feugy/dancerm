_ = require 'lodash'
{generateId} = require '../util/common'
Address = require '../model/address'

class AddressDirective
                
  # Controller dependencies
  @$inject: []

  # **private**
  # Edited address's previous values
  _previous: {}

  # Controller constructor: bind methods and attributes to current scope
  constructor: () ->

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) => 
    return 'invalid' if @requiredFields? and field in @requiredFields
    ''

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
      onAffect: '&?'
      # removal handler, used when address needs to be removed
      onRemove: '&?'
      # used to propagate model modifications, invoked with $field as parameter
      onChange: '&?'
