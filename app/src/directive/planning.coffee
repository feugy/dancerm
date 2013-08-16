define [
  'jquery'
  'underscore'
  'i18n!nls/common'
  '../app'
], ($, _, i18n, app) ->

  # The planning directive displays a given planning in a calendar fancy way
  app.directive 'planning', ->
    # directive template
    template: """<div class="planning"></div>"""
    # will remplace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: PlanningDirective
    # parent scope binding.
    scope: 
      # displayed planning
      src: '='
      # array of selected dance class ids
      selected: '='

  days = i18n.planning.days
  hours = [i18n.planning.earliest..i18n.planning.latest]
      
  class PlanningDirective
                  
    # Controller dependencies
    @$inject: ['$scope', '$element']
    
    # Controller scope, injected within constructor
    scope: null
    
    # JQuery enriched element for directive root
    $el: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] directive scope
    # @param element [DOM] directive root element
    constructor: (@scope, element) ->
      @$el = $(element)
      html = []
      # adds time column
      html.push "<div class='time'><div class='title'>&nbsp;</div>"
      # add quarter from the earliest to the latest hours
      for hour in hours
        for i in [0..3]
          html.push "<div class='quarter q#{i}' data-hour='#{hour}' data-quarter='#{i}'>#{unless i then "#{hour}:00" else '&nbsp;'}</div>"
      html.push "</div>"

      # creates days are parametrized
      for day in days
        html.push "<div class='day' data-day='#{day}'><div class='title'>#{i18n.lbl[day]}</div>"
        # add quarter from the earliest to the latest hours
        for hour in hours
          for i in [0..3]
            html.push "<div class='quarter q#{i}' data-hour='#{hour}' data-quarter='#{i}'>&nbsp;</div>"
        html.push "</div>"

      @$el.append html.join ''
      @$el.addClass "days#{i18n.planning.days.length} hours#{hours.length}"

      # now, displays dance classes
      @scope.$watch 'src', @_displayClasses
      @_displayClasses @scope.src

      # bind clicks
      @$el.delegate '.danceClass', 'click', (event) =>
        danceClass = $(event.target).closest '.danceClass'
        selected = danceClass.hasClass 'selected'
        danceClass.toggleClass 'selected'
        if selected
          # removes already selected id
          @scope.selected.splice @scope.selected.indexOf(danceClass.data 'id'), 1
        else
          # adds id
          @scope.selected.push danceClass.data 'id'
      
    # **private**
    # Display each available dance class on the planning
    _displayClasses: (planning, old) =>
      return unless planning? and planning isnt old
      @$el.find('.danceClass').remove()

      # to order courses in the same day, compute an overlap matrix 
      matrix = ([] for i in days)
      for course in planning.danceClasses
        day = course.start[0..2]
        # store occupation by days
        matrix[days.indexOf day].push 
          sHour: sH = parseInt course.start.replace day, ''
          sQuarter: sQ = parseInt(course.start[course.start.indexOf(':')+1..])/15
          eHour: eH = parseInt course.end.replace day, ''
          eQuarter: eQ = parseInt(course.end[course.end.indexOf(':')+1..])/15
          start: sH*4 + sQ
          end: eH*4 + eQ
          free: true
          name: "#{course.kind} #{course.level}"
          # creates dance class rendering with level as text
          render: $("""<div class="danceClass #{course.color}" data-id="#{course.id}">#{course.level}</div>""")

      # now, positinonate courses quarter by quarter
      for courses, rank in matrix
        # sort day by begin
        courses.sort (d1, d2) -> (d1.sHour*4+d1.sQuarter) - (d2.sHour*4+d2.sQuarter)
        for hour in hours
          for i in [0..3]
            # find a dance class that begins at this quarter
            course = _.findWhere courses, sHour: hour, sQuarter: i, free: true
            overlap = []
            if course?
              # find other courses that overlap this one
              overlap = []
              for other in courses
                if course.start < other.end <= course.end or course.start <= other.start < course.end
                  overlap.push other
            # finally, positionnate the elements
            for course, column in overlap when course.free
              column -= _.reduce overlap, ((count, course) -> count + (if course.free then 0 else 1)), 0
              # gets the anchor position
              start = @$el.find(".day:nth-child(#{rank+2}) > [data-hour='#{course.sHour}'][data-quarter='#{course.sQuarter}']")
              end = @$el.find(".day:nth-child(#{rank+2}) > [data-hour='#{course.eHour}'][data-quarter='#{course.eQuarter}']")
              # compute width regarding overlap
              width = 100/(overlap.length)
              # and positionnate absolutely
              course.render.css 
                height: (end.position()?.top or start.parent().height()) - start.position().top
                top: start.position().top
                left: "#{column*width}%"
                width: "#{width}%"
              $(@$el.children()[rank+1]).append course.render 
            # mark as rendered to avoid reuse
            _.each overlap, (course) -> course.free = false     

      for id in @scope.selected
        @$el.find("[data-id='#{id}']").addClass 'selected'