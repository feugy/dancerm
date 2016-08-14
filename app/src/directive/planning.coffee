_ = require 'lodash'
i18n = require '../labels/common'

days = i18n.planning.days

class PlanningDirective

  # Controller dependencies
  @$inject: ['$scope', '$element', '$attrs', '$compile']

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

  # color legend used. color classe used as key
  legend: {}

  # link to Angular directive compiler
  compile: null

  # When highlighting a given kind, store it to allow toggling
  kind: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param attrs [Object] values of attributes
  # @param compile [Object] Angular directive compiler
  constructor: (@scope, @element, attrs, @compile) ->
    @groups = {}
    @hours = []
    @legend = {}
    @groupBy = attrs.groupBy or 'hall'
    # now, displays dance classes
    unwatch = @scope.$watch 'danceClasses', @_displayClasses
    @_displayClasses @scope.danceClasses

    # bind clicks
    @element.on 'click', '.danceClass', (event) =>
      danceClass = $(event.target).closest '.danceClass'
      model = _.find @scope.danceClasses, id:danceClass.data('id').toString()
      # invoke click handler
      @scope.onClick $event: event, danceClasses: [model]

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
      if @kind is color
        @kind = null
        @scope.onClick $event: event, danceClasses: []
      else
        @kind = color
        @element.find(".danceClass:not(.#{color}), .legend *:not(.#{color})").addClass 'darken'
        # invoke click handler
        @scope.onClick $event: event, danceClasses: _.filter @scope.danceClasses, color:color

    # free listeners
    @scope.$on '$destroy', =>
      unwatch?()
      @element.off()

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
    for day in days
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
    html.push "<span class='#{color}'>#{kind}</span>" for color, kind of @legend
    html.push '</div>'

    @element.empty().append html.join ''
    @element.addClass "days#{i18n.planning.days.length} hours#{@hours.length}"

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
      @legend[course.color] = course.kind unless course.color of @legend
    @hours = [earliest..latest]

  # **private**
  # Display each available dance class on the planning
  #
  # @param danceClasses [Array<DanceClass>] list of dance class to display
  _displayClasses: (danceClasses, old) =>
    return unless @scope.danceClasses? and not _.isEqual @scope.danceClasses, old
    # no available classes
    return @element.empty() unless @scope.danceClasses?.length > 0
    # analyses to find hour span and dance groups
    @_extractSpans()
    # then build empty calendar
    @_buildCalendar()

    # positionnate each course in their respective day and group
    for course in @scope.danceClasses
      day = course.start[0..2]

      # gets start and end hours
      sHour = parseInt course.start.replace day, ''
      sQuarter = parseInt(course.start[course.start.indexOf(':')+1..])/15
      eHour = parseInt course.end.replace day, ''
      eQuarter = parseInt(course.end[course.end.indexOf(':')+1..])/15

      # gets horizontal positionning
      column = days.indexOf(day)+2
      start = @element.find(".day:nth-child(#{column}) > [data-hour='#{sHour}'][data-quarter='#{sQuarter}']")
      end = @element.find(".day:nth-child(#{column}) > [data-hour='#{eHour}'][data-quarter='#{eQuarter}']")

      # gets vertical positionning
      width = 100/@groups[day].length
      groupCol = @groups[day].indexOf course[@groupBy]

      # and eventually positionates the rendering inside the right day
      tooltip = _.template(i18n.lbl.classTooltip)
        kind: course.kind
        level: course.level
        start: course.start.replace(day, '').trim()
        end: course.end.replace(day, '').trim()
      render = @compile("""<div class="danceClass #{course.color}" data-id="#{course.id}"
          data-tooltip="#{tooltip}" data-tooltip-popup-delay="200"
          data-tooltip-animation="true"
          data-tooltip-append-to-body="true">#{course.level}</div>""") @scope
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
      # event handler for dance class click. Clicked model as 'danceClass' parameter.
      onClick: '&'
      # attribute used for groupBy
      groupBy: '@'