_ = require 'lodash'
i18n = require '../labels/common'

class TagsDirective
                
  # Controller dependencies
  @$inject: ['$scope', '$element']
  
  # Controller scope, injected within constructor
  scope: null
  
  # JQuery enriched element for directive root
  element: null
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  constructor: (@scope, @element) ->
    @element.on 'click', '.close', @_onRemoveTag
    unwatch = @scope.$watch 'ctrl.src', @_onUpdateTags, true
    # free listeners
    scope.$on '$destroy', => 
      unwatch?()
      @element.off()

  # **private**
  # Removes a given tag from the search criteria
  #
  # @param event [Event] click event
  _onRemoveTag: (event) =>
    tag = $(event.target).closest '.tag'
    @scope.$apply =>
      if tag.data('season')?
        @src.seasons.splice @src.seasons.indexOf(tag.data('season')), 1
      else if tag.data('teacher')?
        @src.teachers.splice @src.teachers.indexOf(tag.data('teacher')), 1
      else
        # remove selected class
        id = tag.data 'id'
        for danceClass, i in @src.danceClasses when danceClass.id is id
          @src.danceClasses.splice i, 1
          break
      # update search
      @onRemove()

  # **private**
  # Updates displayed tags from the search criteria
  _onUpdateTags: =>
    @element.empty()
    return unless @src?
    empties = @showEmpties?() or []
    if @src.seasons?
      for season in @src.seasons
        @element.append "<div class='tag season' data-season='#{season}'>#{season}<b class='close'>&times;</b></div>"
      if @src.seasons.length is 0 and 'season' in empties
        @element.append "<div class='tag season'>#{i18n.lbl.allSeasons}</div>"
    if @src.teachers?
      for teacher in @src.teachers
        @element.append "<div class='tag teacher' data-teacher='#{teacher}'>#{teacher}<b class='close'>&times;</b></div>"
      if @src.teachers.length is 0 and 'teacher' in empties
        @element.append "<div class='tag teacher'>#{i18n.lbl.allTeachers}</div>"
    if @src.danceClasses?
      for danceClass in @src.danceClasses
        day = danceClass.start[0..2]
        @element.append "<div class='tag #{danceClass.color}' data-id='#{danceClass.id}'>#{i18n.lbl[day]} #{danceClass.start.replace(day, '')}~#{danceClass.end.replace(day, '')}<b class='close'>&times;</b></div>"
      if @src.danceClasses.length is 0 and 'danceClass' in empties
        @element.append "<div class='tag dance-class'>#{i18n.lbl.allDanceClasses}</div>"
    
# The tags directive displays tags relative at search criteria
module.exports = (app) ->
  app.directive 'tags', ->
    # directive template
    template: "<div class='tags'></div>"
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: TagsDirective
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope: 
      # displayed search
      src: '='
      # arrays indicating which empty criteria should be represented by unclosable tag
      # may contain 'danceClass', 'season' and 'teacher' to show the corresponding tag
      showEmpties: '&?'
      # function to invoke on tag removal
      onRemove: '&'