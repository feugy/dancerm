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

  # The setZero directive set model value to 0 if value is empty
  app.directive 'setZero', ->
    # no replacement
    replace: false
    # applicable as attribute only
    restrict: 'A'
    require: 'ngModel'
    link: (scope, elm, attrs, ctrl) ->
      ctrl.$parsers.unshift (viewValue) ->
        return if viewValue is "" then 0 else viewValue

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

  # attribute directive to automatically expand textarea height based on their content
  # freely inspired from:
  # - https://gist.github.com/thomseddon/4703968#gistcomment-1764568
  # - https://github.com/hubertgrzeskowiak/angular-textarea-autoheight
  app.directive 'autoHeight', ->
    # needs a model
    require: 'ngModel'
    # applicable as attribute only
    restrict: 'A'
    # link function
    link: (scope, element, attrs, controller) =>
      attrs.rows = "1"
      element.css overflow: 'hidden', resize: 'none'
      updateHeight = () ->
        # The elem.scrollHeight doesn't shrink automatically - it only grows.
        # By setting it to 0px first, we ensure it grows to actual scrollHeight.
        element.css height: '0px'
        element.css height: "#{element[0].scrollHeight}px"

      element.bind 'input', updateHeight
      scope.$watch attrs.ngModel, updateHeight

  # attribute directive to automatically make input fits its content
  # freely inspired from:
  # - https://stackoverflow.com/a/21015393/1182976
  app.directive 'autoWidth', ->
    # needs a model
    require: 'ngModel'
    # applicable as attribute only
    restrict: 'A'
    # link function
    link: (scope, element, attrs, controller) =>
      canvas = document.createElement 'canvas'
      scope.$watch attrs.ngModel, () ->
        setTimeout () ->
          input = element[0]
          ctx = canvas.getContext '2d'
          text = if input.value.length then input.value else input.placeholder
          style = window.getComputedStyle input
          padding = +style.paddingLeft.replace('px', '') + +style.paddingRight.replace 'px', ''
          ctx.font = style.font
          element.css width: "#{padding + 2 + ctx.measureText(text).width}px"
        , 0