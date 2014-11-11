_ = require 'lodash'
i18n = require '../labels/common'

days = i18n.planning.days
    
class PlanningDirective
                
  # Controller dependencies
  @$inject: ['$scope', '$element', '$attrs', '$compile']
  
  # Controller scope, injected within constructor
  scope: null
  
  # JQuery enriched element for directive root
  $el: null

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
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param attrs [Object] values of attributes
  # @param compile [Object] Angular directive compiler
  constructor: (@scope, element, attrs, @compile) ->
    @groups = {}
    @hours = []
    @legend = {}
    @$el = $(element)
    @groupBy = attrs.groupBy or 'hall'
    # now, displays dance classes
    @scope.$watch 'danceClasses', @_displayClasses
    @_displayClasses @scope.danceClasses

    # bind clicks
    @$el.delegate '.danceClass', 'click', (event) =>
      danceClass = $(event.target).closest '.danceClass'
      model = _.findWhere @scope.danceClasses, id:danceClass.data 'id'
      # invoke click handler
      @scope.onClick $event: event, danceClasses: [model]

      # disabled unless we provide a selected array
      return unless @scope.selected?
      selected = danceClass.hasClass 'selected'
      danceClass.toggleClass 'selected'
      if selected
        # removes already selected id
        @scope.selected.splice @scope.selected.indexOf(_.findWhere @scope.selected, id: model.id), 1
      else
        # adds id
        @scope.selected.push model

    @$el.delegate '.legend > *', 'click', (event) =>
      color = $(event.target).attr 'class'
      # invoke click handler
      @scope.onClick $event: event, danceClasses: _.where @scope.danceClasses, color:color
    
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
    
    @$el.empty().append html.join ''
    @$el.addClass "days#{i18n.planning.days.length} hours#{@hours.length}"

  # **private**
  # Extracts hour span and different dance groups, as well as legend
  #
  # @param danceClasses [Array<DanceClass>] list of analyzed dance classes
  _extractSpans: (danceClasses) =>
    earliest = 24
    latest = 0
    @legend = {}
    @groups = {}
    for course in danceClasses
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
    return unless danceClasses? and not _.isEqual danceClasses, old
    # no available classes
    return @$el.empty() unless danceClasses?.length > 0
    # analyses to find hour span and dance groups
    @_extractSpans danceClasses
    # then build empty calendar
    @_buildCalendar()

    # positionnate each course in their respective day and group
    for course in danceClasses
      day = course.start[0..2]

      # gets start and end hours
      sHour = parseInt course.start.replace day, ''
      sQuarter = parseInt(course.start[course.start.indexOf(':')+1..])/15
      eHour = parseInt course.end.replace day, ''
      eQuarter = parseInt(course.end[course.end.indexOf(':')+1..])/15
      
      # gets horizontal positionning
      column = days.indexOf(day)+2
      start = @$el.find(".day:nth-child(#{column}) > [data-hour='#{sHour}'][data-quarter='#{sQuarter}']")
      end = @$el.find(".day:nth-child(#{column}) > [data-hour='#{eHour}'][data-quarter='#{eQuarter}']")
            
      # gets vertical positionning
      width = 100/@groups[day].length
      groupCol = @groups[day].indexOf course[@groupBy]

      # and eventually positionates the rendering inside the right day
      tooltip = _.sprintf i18n.lbl.classTooltip, course.kind, course.level, course.start.replace(day, ''), 
        course.end.replace(day, '')
      render = @compile("""<div class="danceClass #{course.color}" data-id="#{course.id}"
          data-tooltip="#{tooltip}" data-tooltip-popup-delay="200"
          data-tooltip-append-to-body="true">#{course.level}</div>""") @scope
      render.css 
        height: height = (end.position()?.top or start.parent().height()) - start.position().top
        top: start.position().top
        left: "#{groupCol*width}%"
        width: "#{width}%"
        'line-height': "#{height}px"
      $(@$el.children()[column-1]).append render 

    if @scope.selected?
      for {id} in @scope.selected
        @$el.find("[data-id='#{id}']").addClass 'selected'

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