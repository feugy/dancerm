# This particular input allows to input a given input and to display something else
# When input has focus, the real value is editable, otherwise, the formatted equivalent is displayed
module.exports = (app) ->
  app.directive 'filteredInput', ->
    replace: true
    template: '<input/>'
    # applicable as element and attribute
    restrict: 'EA'
    # uses Angular ngModel to manipulate input displayed and model
    require: 'ngModel'
    # parent scope binding.
    scope:
      # format function that takes the model value and return the displayed value
      format: '='
      # format function that takes the displayed value and return the model value
      parse: '='

    # wire to ngModel controller to apply formatting and parsing on the fly
    link: (scope, element, attrs, modelController) ->
      focused = false

      modelController.$parsers.push (data) ->
        if focused then data else scope.parse data
      modelController.$formatters.push (data) ->
        if focused then data else scope.format data

      element.on 'blur mouseleave', () =>
        focused = false
        # Don't know why, formatter are not applied on blur, maybe because view and model value are equals'
        modelController.$setViewValue scope.format modelController.$modelValue
        modelController.$render()
        scope.$apply()

      element.on 'focus mouseenter', () =>
        focused = true
        modelController.$setViewValue modelController.$modelValue
        modelController.$render()
        scope.$apply()

      scope.$on '$destroy', () ->
        element.off 'focus'
        element.off 'mouseenter'
        element.off 'blur'
        element.off 'mouseleave'