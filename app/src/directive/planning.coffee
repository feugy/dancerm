_ = require 'lodash'
i18n = require '../labels/common'

class PlanningDirective

  # Controller dependencies
  @$inject: ['$scope', '$element', '$attrs', '$compile', '$q']

  # Controller scope, injected within constructor
  scope: null

  # JQuery enriched element for directive root
  element: null

  # span of displayed hours
  hours: []

  # existing groups: day used as key.
  groups: {}

  # attributes used to group classes inside days
  groupBy: 'hall'

  # list of displayed days
  days: []

  # true to shrink displayed hours to the range that includes all danceClasses
  shrinkHours: true

  # color legend used. color classe used as key
  legend: {}

  # link to Angular directive compiler
  compile: null

  # When highlighting a given legend item, store it to allow toggling
  item: null

  # right offset (percentage) applied to dance classes inside a given day
  widthOffset: 0

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param attrs [Object] values of attributes
  # @param compile [Object] Angular directive compiler
  constructor: (@scope, @element, attrs, @compile, @q) ->
    @groups = {}
    @hours = []
    @legend = {}
    @days = @scope.days or i18n.planning.weekDays
    @groupBy = attrs.groupBy or 'hall'
    @widthOffset = +attrs.widthOffset or 0
    @shrinkHours = if attrs.shrinkHours? then attrs.shrinkHours.trim().toLowerCase() is 'true' else true

    # bind clicks
    @element.on 'click', '.quarter', (event) =>
      quarter = $(event.target).closest '.quarter'
      day = $(event.target).closest '.day'
      @scope?.onCellClick $event: event, day: day.data('day'), hour: "#{quarter.data 'hour'}:#{15 * quarter.data('quarter') or '00'}"

    @element.on 'click', '.danceClass', (event) =>
      danceClass = $(event.target).closest '.danceClass'
      model = _.find @scope.danceClasses, id:danceClass.data('id').toString()
      # invoke click handler
      @scope?.onClick $event: event, danceClasses: [model]

      # disabled unless we provide a selected array
      return unless @scope.selected?
      selected = danceClass.hasClass 'selected'
      danceClass.toggleClass 'selected'
      if selected
        # removes already selected id
        @scope.selected.splice @scope.selected.indexOf(_.find @scope.selected, id: model.id), 1
      else
        # adds id
        @scope.selected.push model

    @element.on 'click', '.legend > *', (event) =>
      color = $(event.target).attr('class').replace('darken', '').trim()
      @element.find('.darken').removeClass 'darken'
      if @item is color
        @item = null
        @scope.onClick $event: event, danceClasses: []
      else
        @item = color
        @element.find(".danceClass:not(.#{color}), .legend *:not(.#{color})").addClass 'darken'
        # invoke click handler
        @scope.onClick $event: event, danceClasses: _.filter @scope.danceClasses, color:color

    # free listeners
    @scope.$on '$destroy', =>
      unwatch?()
      @element.off()

    # now, displays dance classes
    unwatch = @scope.$watch 'danceClasses', @_displayClasses
    _.defer => @_displayClasses @scope.danceClasses

  # **private**
  # Compute tooltip for a given course
  # @param course [DanceClass] displayed course
  # @param day [String] day name extracted from start
  # @return [String] course's tooltip content
  _getTooltipContent: (course, day) =>
    @q (resolve) => resolve @scope.getTooltipContent(model: course, day: day) or _.template(i18n.lbl.classTooltip)
      kind: course.kind
      level: course.level
      start: course.start.replace(day, '').trim()
      end: course.end.replace(day, '').trim()

  # **private**
  # Compute title for a given course
  # @param course [DanceClass] displayed course
  # @return [String] course's level
  _getTitle: (course) =>
    @q (resolve) => resolve @scope.getTitle(model: course) or course.level

  # **private**
  # Compute color and legend item for a given course
  # @param course [DanceClass] displayed course
  # @return [Array<String>] course's color and legend item
  _getLegend: (course) =>
    @q (resolve) => resolve @scope.getLegend(model: course) or [course.color, course.kind]

  # **private**
  # Rebuild the empty calendar. Hour span and dance groups must have been initialized
  _buildCalendar: =>
    html = []
    html.push "<div class='time'><div class='title'>&nbsp;</div><div class='groups'>&nbsp;</div>"
    # add quarter from the earliest to the latest hours
    for hour in @hours
      for i in [0..3]
        html.push "<div class='quarter q#{i}' data-hour='#{hour}' data-quarter='#{i}'>#{unless i then "#{hour}:00" else '&nbsp;'}</div>"
    html.push "</div>"

    # creates days are parametrized
    for day in @days
      html.push "<div class='day' data-day='#{day}'><div class='title'>#{i18n.lbl[day]}</div><div class='groups'>"
      if @groups[day]?
        html.push "<span>#{group}</span>" for group in @groups[day]
      html.push "</div>"
      # add quarter from the earliest to the latest hours
      for hour in @hours
        for i in [0..3]
          html.push "<div class='quarter q#{i}' data-hour='#{hour}' data-quarter='#{i}'>&nbsp;</div>"
      html.push "</div>"
    # adds legend
    html.push "<div class='legend'>#{i18n.planning.legend}"
    html.push "<span class='#{color}'>#{item}</span>" for color, item of @legend
    html.push '</div>'

    @element.empty().append html.join ''
    @element.addClass "days#{@days.length} hours#{@hours.length}"

  # **private**
  # Extracts hour span and different dance groups, as well as legend
  _extractSpans: =>
    earliest = 24
    latest = 0
    @legend = {}
    @groups = {}
    for course in @scope.danceClasses
      # computes earliest and latest hours
      day = course.start[0..2]
      earliest = Math.min earliest, parseInt course.start.replace day, ''
      latest = Math.max latest, parseInt(course.end.replace day, '') - (if parseInt(course.end[course.end.indexOf(':')+1..]) > 0 then 0 else 1)
      # extracts dance groups
      @groups[day] = [] unless @groups[day]?
      unless course[@groupBy] in @groups[day]
        @groups[day].push course[@groupBy]
        @groups[day].sort()
      # keep legend if necessary
      [color, item] = @_getLegend course
      @legend[color] = item unless color of @legend
    @hours = if @shrinkHours then [earliest..latest] else [7..22]

  # **private**
  # Display each available dance class on the planning
  #
  # @param danceClasses [Array<DanceClass>] list of dance class to display
  _displayClasses: (danceClasses, old) =>
    return unless @scope.danceClasses? and not _.isEqual @scope.danceClasses, old
    # analyses to find hour span and dance groups
    @_extractSpans()
    # then build empty calendar
    @_buildCalendar()

    # positionnate each course in their respective day and group
    @scope.danceClasses.forEach (course) =>
      day = course.start[0..2]

      # gets start and end hours
      sHour = parseInt course.start.replace day, ''
      sQuarter = Math.round parseInt(course.start[course.start.indexOf(':')+1..])/15
      eHour = parseInt course.end.replace day, ''
      eQuarter = Math.round parseInt(course.end[course.end.indexOf(':')+1..])/15

      # gets horizontal positionning
      column = @days.indexOf(day)+2
      start = @element.find(".day:nth-child(#{column}) > [data-hour='#{sHour}'][data-quarter='#{sQuarter}']")
      end = @element.find(".day:nth-child(#{column}) > [data-hour='#{eHour}'][data-quarter='#{eQuarter}']")

      # do not process unless we found a place
      unless start[0]? and end[0]?
        console.log "found planning item that can't be displayed #{course.id} #{course.start}-#{course.end}"
      else
        # gets vertical positionning
        width = (100-@widthOffset)/@groups[day].length
        groupCol = @groups[day].indexOf course[@groupBy]

        @_getTitle(course).then (title) => @_getLegend(course).then ([legend]) => @_getTooltipContent(course, day).then (tooltip) =>
          # and eventually positionates the rendering inside the right day
          render = @compile("""<div class="danceClass #{legend}" data-id="#{course.id}"
              data-uib-tooltip="#{tooltip}" data-uib-tooltip-popup-delay="200"
              data-uib-tooltip-animation="true"
              data-uib-tooltip-append-to-body="true">#{title}</div>""") @scope
          render.css
            height: height = (end.position()?.top or start.parent().height()) - start.position().top
            top: start.position().top
            left: "#{groupCol*width}%"
            width: "#{width}%"
            'line-height': "#{height}px"
          $(@element.children()[column-1]).append render

    if @scope.selected?
      for {id} in @scope.selected
        @element.find("[data-id='#{id}']").addClass 'selected'

# The planning directive displays a given planning in a calendar fancy way
module.exports = (app) ->
  app.directive 'planning', ->
    # directive template
    template: """<div class="planning"></div>"""
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: PlanningDirective
    # parent scope binding.
    scope:
      # displayed dance classes (array)
      danceClasses: '=src'
      # array of selected dance classes
      # if not provided, dance class cannot be selected
      selected: '='
      # displayed days
      days: '=?'
      # attribute used for groupBy
      groupBy: '@'
      # true to shrink displayed hours to the range that includes all danceClasses
      shrinkHours: '@'
      # right offset (percentage) applied to dance classes inside a given day
      widthOffset: '@'
      # event handler for dance class click. Clicked model as 'danceClass' parameter.
      onClick: '&'
      # event handler for cell click. Clicked quarter day as 'day' parameter, and start time as 'hour' parameter
      onCellClick: '&'
      # function that returns tooltip content for a given dance classe (first parameter, second is day string)
      getTooltipContent: '&'
      # function that returns title for given dance classe (first parameter)
      getTitle: '&'
      # function that returnsand array containing color and legend group for given dance classe (first parameter)
      getLegend: '&'