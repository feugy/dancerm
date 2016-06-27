_ = require 'lodash'
i18n = require '../labels/common'

# exports a function that declare filters and directive on specified application
module.exports = (app) =>

  # i18n filter replace a given expression by its i18n value.
  # the 'sep' option can be added to suffix with the fieldSeparator label
  app.filter 'i18n', ['$parse', '$interpolate', (parse, interpolate) -> (input, options) ->
    sep = ''
    if options?.sep is true
      sep = parse('lbl.fieldSeparator') i18n
    currency = ''
    if options?.currency is true
      currency = parse('lbl.currency') i18n
    try
      value = parse(input)(i18n)
      # performs replacements
      if value? and _.isObject options?.args
        value = interpolate(value)(options.args)
    catch exc
      window.console.error "failed to parse i18n key '#{input}': #{exc}"
    "#{value or input}#{sep}#{currency}"
  ]

  # classDate filter displays with friendly names start or end of a dance class
  app.filter 'classDate', [ -> (input, length) ->
    return unless input?.length is 9
    day = i18n.lbl[input[0..2]]
    "#{day} #{input[4..8]}"
  ]

  # capitalize filter displays capitalized strings
  app.filter 'capitalize', [ -> (input) -> _.capitalize input ]

  # The setNull directive set model value to null if value is empty
  app.directive 'setNull', ->
    # no replacement
    replace: false
    # applicable as attribute only
    restrict: 'A'
    require: 'ngModel'
    link: (scope, elm, attrs, ctrl) ->
      ctrl.$parsers.unshift (viewValue) ->
        return if viewValue is "" then null else viewValue

  # The disableTab directive avoid typeahead catching it as a selection
  app.directive 'disableTab', ->
    # no replacement
    replace: false
    # applicable as attribute only
    restrict: 'A'
    require: 'ngModel'
    # to ensure link will be executed after typeahead
    # this garantee that keydown will be fired BEFORE the typeahead one
    priority: -1
    link: (scope, element) ->
      element.bind 'keydown', (event) ->
        return unless event.which is 9
        # to avoid selecting an item from menu
        event.stopImmediatePropagation()
        # trigger an esc to close menu
        e = $.Event 'keydown'
        e.which = 27
        element.trigger e

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