_ = require 'lodash'
i18n = require '../labels/common'
{extractDateDetails} = require '../util/common'

# Extract boolean value from attributes
# @param name [String] parsed attribute name
# @param attrs [Object] attributes hash
# @param def [Boolean = true] default value
parseBooleanAttr = (name, attrs, def = true) ->
  if attrs[name]? then attrs[name]?.trim()?.toLowerCase() is 'true' else def

class PlanningDirective

  # Controller dependencies
  @$inject: ['$scope', '$element', '$attrs', '$compile', '$q', '$sce']

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

  # Only show day columns that are not empty (contains at least one dance classe)
  hideEmptyDays: true

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param attrs [Object] values of attributes
  # @param compile [Object] Angular directive compiler
  # @param q [Object] Angular promise factory
  # @param sce [Object] Angular strict content escape utility
  constructor: (@scope, @element, attrs, @compile, @q, @sce) ->
    @groups = {}
    @hours = []
    @legend = {}
    @moved = null
    @days = @scope.days or i18n.planning.weekDays
    @groupBy = attrs.groupBy or 'hall'
    @widthOffset = +attrs.widthOffset or 0
    @shrinkHours = parseBooleanAttr 'shrinkHours', attrs, true
    @hideEmptyDays = parseBooleanAttr 'hideEmptyDays', attrs, false
    @clickableCells = parseBooleanAttr 'clickableCells', attrs, false

    @element.addClass 'clickable-cell' if @clickableCells

    # click on quarter: select cell and trigger onCellClick handler
    @element.on 'click', '.quarter', (event) =>
      return unless @scope.clickableCells
      quarter = $(event.target).closest '.quarter'
      day = $(event.target).closest('.day').data 'day'
      return unless day?
      @element.find('.quarter.selected').removeClass 'selected'
      quarter.addClass 'selected'
      @scope?.onCellClick $event: event, day: day, hour: "#{quarter.data 'hour'}:#{15 * quarter.data('quarter') or '00'}"

    # click on dance classes: toggle selected class, update current selection and trigger onClick handler
    @element.on 'click', '.danceClass', (event) =>
      @element.find('.quarter.selected').removeClass 'selected'
      danceClass = $(event.target).closest '.danceClass'
      selected = danceClass.hasClass 'selected'
      model = _.find @scope.danceClasses, id:danceClass.data('id').toString()
      # invoke click handler
      @scope?.onClick $event: event, danceClasses: [model], selected: selected

      # disabled unless we provide a selected array
      return unless @scope.selected?
      danceClass.toggleClass 'selected'
      if selected
        # removes already selected id
        @scope.selected.splice @scope.selected.indexOf(_.find @scope.selected, id: model.id), 1
      else
        # adds id
        @scope.selected.push model

    # click on legent: toggle darken class on all related dance classes, trigger onClick handler
    @element.on 'click', '.legend > *', (event) =>
      @element.find('.quarter.selected').removeClass 'selected'
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

    @element.on 'dragstart', '.danceClass', (event) =>
      return unless @clickableCells?
      elem = $(event.target).closest '.danceClass'
      @moved = {
        elem
        position: elem.offset()
        id: elem.data 'id'
      }
      event.originalEvent.dataTransfer.setDragImage new Image(), 0, 0

    @element.on 'drag', (event) =>
      return unless @moved?
      @moved.elem.offset top: event.originalEvent.clientY + 5, left: event.originalEvent.clientX - @moved.elem.outerWidth() / 2

    @element.on 'dragover', (event) =>
      # required to complete the operation
      event.preventDefault()

    @element.on 'dragenter', '.day .quarter', (event) =>
      return unless @moved?
      $(event.target).closest('.quarter').addClass 'drop-target'

    @element.on 'dragleave', '.day .quarter', (event) =>
      return unless @moved?
      $(event.target).closest('.quarter').removeClass 'drop-target'

    @element.on 'drop', '.day .quarter', (event) =>
      return unless @moved?
      event.preventDefault()
      quarter = $(event.target).closest '.quarter'
      danceClass =  _.find @scope.danceClasses, id: @moved.id
      return unless danceClass?
      @moved.success = true

      @scope.onMove {
        $event: event
        danceClass
        day: quarter.closest('.day').data 'day'
        hour: quarter.data 'hour'
        minutes: 15 * quarter.data 'quarter'
      }

    @element.on 'dragend', (event) =>
      return unless @moved?
      # restore initial position
      @moved.elem.offset @moved.position unless @moved.success
      @moved = null

    # free listeners
    @scope.$on '$destroy', =>
      unwatch?() for unwatch in unwatches
      @element.off()

    # now, displays dance classes
    unwatches = [
      @scope.$watch 'danceClasses', @_displayClasses, true
      @scope.$watchCollection 'selected', () =>
        return unless @scope.selected?
        @element.find('.selected').removeClass 'selected'
        @element.find("[data-id='#{id}']").addClass 'selected' for {id} in @scope.selected
    ]
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
  # Compute label for a given group
  # @param group [String] displayed group
  # @return [String] displayed group label
  _getGroup: (group) =>
    @q (resolve) => resolve @scope.getGroup(model: group) or group

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
        html.push "<span class='group' data-group='#{group}'></span>" for group in @groups[day]
      html.push "</div>"
      # add quarter from the earliest to the latest hours
      for hour in @hours
        for i in [0..3]
          html.push "<div class='quarter q#{i}' data-hour='#{hour}' data-quarter='#{i}'>&nbsp;</div>"
      html.push "</div>"
    # adds legend
    html.push "<div class='legend'></div>"

    @element.empty().append html.join ''
    @element.addClass "days#{@days.length} hours#{@hours.length}"

    @_buildLegend()
    @_buildGroups()

  # **private**
  # Refresh group conent
  _buildGroups: =>
    groups = _.chain(@groups).values().flattenDeep().uniq().value()
    @q.all(@_getGroup group for group in groups).then (labels) =>
      @element.find("[data-group='#{group}']").empty().append labels[i] for group, i in groups

  # **private**
  # Refresh legend content
  _buildLegend: =>
    legend = ("<span class='#{color}'>#{item}</span>" for color, item of @legend)
    @element.find('.legend').empty().append "#{i18n.planning.legend}#{legend.join('')}"

  # **private**
  # Extracts hour span and different dance groups, as well as legend
  _extractSpans: =>
    earliest = 24
    latest = 0
    @legend = {}
    @groups = {}
    legended = @scope.danceClasses.length
    @scope.danceClasses.forEach (course) =>
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
      @_getLegend(course).then ([color, item]) =>
        legended--
        @legend[color] = item unless color of @legend
        @_buildLegend() if legended is 0
    @hours = if @shrinkHours then [earliest..latest] else [8..22]
    # hide empty days if required
    @days = (day for day in @days when @groups[day]?.length > 0) if @hideEmptyDays and @scope.danceClasses?.length

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
      # gets start and end hours
      sDetails = extractDateDetails course.start
      eDetails = extractDateDetails course.end
      day = course.start[0..2]

      # gets horizontal positionning
      column = @days.indexOf(sDetails.day)+2
      start = @element.find(".day:nth-child(#{column}) > [data-hour='#{sDetails.hour}'][data-quarter='#{Math.round sDetails.minutes / 15}']")
      end = @element.find(".day:nth-child(#{column}) > [data-hour='#{eDetails.hour}'][data-quarter='#{Math.round eDetails.minutes / 15}']")

      # do not process unless we found a place
      unless start[0]?
        console.log "found planning item that can't be displayed #{course.id} #{course.start}-#{course.end}"
      else
        # gets vertical positionning
        width = (100-@widthOffset)/@groups[day].length
        groupCol = @groups[day].indexOf course[@groupBy]

        @_getTitle(course).then (title) => @_getLegend(course).then ([legend]) => @_getTooltipContent(course, day).then (tooltip) =>
          # and eventually positionates the rendering inside the right day
          className = "danceClass #{legend}"
          className += ' selected' if @scope.selected?.find ({id}) -> id is course.id
          render = @compile("""<div #{if @clickableCells then 'draggable="true"' else ''} class="#{className}" data-id="#{course.id}"
              data-uib-tooltip-html='#{JSON.stringify(tooltip).replace /'/g, '&#39;'}' data-uib-tooltip-popup-delay="200"
              data-uib-tooltip-animation="true"
              data-uib-tooltip-append-to-body="true">#{title}</div>""") @scope
          render.css
            height: height = (end.position()?.top or start.parent().height()) - start.position().top
            top: start.position().top
            left: "#{groupCol*width}%"
            width: "#{width}%"
            'line-height': "#{height}px"
          $(@element.children()[column-1]).append render

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
      # true to shrink displayed hours to the range that includes all danceClasses (default to true)
      shrinkHours: '@'
      # true to hide days that don't contains any item, if at least one item exists (default to true)
      hideEmptyDays: '@'
      # right offset (percentage) applied to dance classes inside a given day (default to 0)
      widthOffset: '@'
      # if true, click on cells trigger onCellClick (default to false)
      clickableCells: '@'
      # event handler for dance class click. Clicked model as 'danceClass' parameter, and 'selected' a boolean
      # indicating that model is already selected
      onClick: '&'
      # event handler for cell click. Clicked quarter day as 'day' parameter, and start time as 'hour' parameter
      onCellClick: '&'
      # function that returns tooltip content for a given dance classe (first parameter, second is day string)
      getTooltipContent: '&'
      # function that returns title for given dance classe (first parameter)
      getTitle: '&'
      # function that returns an array containing color and legend group for given dance classe (first parameter)
      getLegend: '&'
      # function taht returns a label for a given group (first parameter)
      getGroup: '&'
      # event handler for dance class moves. Moved model as 'danceClass' parameter, and 'day', 'hour' and 'minutes'
      # indicating the new slot
      onMove: '&'