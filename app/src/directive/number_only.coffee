# attribute directive that ensure that input content is a valid number
app.directive 'numberOnly', ->
  replace: false
  # needs a model
  require: 'ngModel'
  # applicable as attribute only
  restrict: 'A'
  # link function
  link: (scope, element, attrs, controller) =>
    controller.$parsers.push (value) =>
      number = +value
      valid = not isNaN number
      controller.$setValidity 'notANumber', valid
      if valid then number else undefined