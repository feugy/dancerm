_ = require 'underscore'
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

  # add directive for stacked bar charts
  app.directive 'tcChartjsStackedBar', () ->
    return {
      restrict: 'A'
      scope:
        data: '=chartData'
        options: '=chartOptions'
        id: '@'
        type: '@chartType'
      link: ($scope, $elem) ->
        ctx = $elem[0].getContext '2d'
        chart = new window.Chart(ctx)
        graph = null
        $scope.$watch 'data', ->
          console.log $scope.data, $scope.options
          return unless $scope.data?.labels?
          graph.destroy() if graph?
          graph = chart.EnhancedStackedBar $scope.data, $scope.options
        , true

    }

  # Extends StackedBar to provide our own tooltips and scale
  window.Chart.types.StackedBar.extend 
      name: "EnhancedStackedBar"

      buildScale: (labels) ->
        empties = ('' for i in [0...labels.length])
        # do not display labels
        window.Chart.types.StackedBar.prototype.buildScale.call @, empties

      showTooltip: (chartElements, forceRedraw) ->
        # Only redraw the chart if we've actually changed what we're hovering on.
        @activeElements = [] unless @activeElements?


        changed = true
        if chartElements.length is @activeElements.length
          changed = false
          for element, i in chartElements when element isnt @activeElements[i]
            changed = true
        
        return if not changed and not forceRedraw
        @activeElements = chartElements
        @draw()

        if chartElements.length > 0
          if @datasets?.length > 1
            dataArray = []
            dataIndex = -1
            for dataset, i in @datasets
              dataArray = dataset.points or dataset.bars or dataset.segments
              dataIndex = dataArray.indexOf chartElements[0]
              break unless dataIndex is -1
            
            tooltipLabels = []
            tooltipColors = []
            elements = []
            xPositions = []
            yPositions = []
            for dataset in @datasets
              dataCollection = dataset.points or dataset.bars or dataset.segments
              # Customization: ignore 0 values
              elements.push dataCollection[dataIndex] if dataCollection[dataIndex]?.value

            for element in elements
              xPositions.push element.x
              yPositions.push element.y

              # Customization: use datasetLabel if possible
              tooltipLabels.push "#{element.datasetLabel} (#{element.value})" 
              tooltipColors.push
                fill: element._saved.fillColor or element.fillColor
                stroke: element._saved.strokeColor or element.strokeColor

            yMin = _.min yPositions
            yMax = _.max yPositions

            xMin = _.min xPositions
            xMax = _.max xPositions

            new window.Chart.MultiTooltip(
              x: if xMin > @chart.width/2 then xMin else xMax
              y: (yMin + yMax)/2
              xPadding: @options.tooltipXPadding
              yPadding: @options.tooltipYPadding
              xOffset: @options.tooltipXOffset
              fillColor: @options.tooltipFillColor
              textColor: @options.tooltipFontColor
              fontFamily: @options.tooltipFontFamily
              fontStyle: @options.tooltipFontStyle
              fontSize: @options.tooltipFontSize
              titleTextColor: @options.tooltipTitleFontColor
              titleFontFamily: @options.tooltipTitleFontFamily
              titleFontStyle: @options.tooltipTitleFontStyle
              titleFontSize: @options.tooltipTitleFontSize
              cornerRadius: @options.tooltipCornerRadius
              labels: tooltipLabels,
              legendColors: tooltipColors,
              legendColorBackground : @options.multiTooltipKeyBackground
              title: chartElements[0].label
              chart: @chart
              ctx: @chart.ctx
            ).draw()

          else
            for element in chartElements
              tooltipPosition = window.Element.tooltipPosition()
              new window.Chart.Tooltip(
                x: Math.round tooltipPosition.x
                y: Math.round tooltipPosition.y
                xPadding: @options.tooltipXPadding
                yPadding: @options.tooltipYPadding
                fillColor: @options.tooltipFillColor
                textColor: @options.tooltipFontColor
                fontFamily: @options.tooltipFontFamily
                fontStyle: @options.tooltipFontStyle
                fontSize: @options.tooltipFontSize
                caretHeight: @options.tooltipCaretSize
                cornerRadius: @options.tooltipCornerRadius
                text: window.Chart.helpers.template @options.tooltipTemplate, Element
                chart: @chart
              ).draw()
        @