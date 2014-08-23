_ = require 'underscore'
moment = require 'moment'
i18n = require '../labels/common'

class TagsDirective
                
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
    @$el.on 'click', '.close', @_onRemoveTag
    @scope.$watch 'src', @_onUpdateTags, true

  # **private**
  # Removes a given tag from the search criteria
  #
  # @param event [Event] click event
  _onRemoveTag: (event) =>
    tag = $(event.target).closest '.tag'
    @scope.$apply =>
      if tag.data('season')?
        @scope.src.seasons.splice @scope.src.seasons.indexOf(tag.data('season')), 1
      else if tag.data('teacher')?
        @scope.src.teachers.splice @scope.src.teachers.indexOf(tag.data('teacher')), 1
      else
        # remove selected class
        id = tag.data 'id'
        for danceClass, i in @scope.src.danceClasses when danceClass.id is id
          @scope.src.danceClasses.splice i, 1
          break
      # update search
      @scope.onRemove()

  # **private**
  # Updates displayed tags from the search criteria
  _onUpdateTags: =>
    @$el.empty()
    return unless @scope.src
    if @scope.src.seasons?
      for season in @scope.src.seasons
        @$el.append "<div class='tag season' data-season='#{season}'>#{season}<b class='close'>&times;</b></div>"
    if @scope.src.teachers?
      for teacher in @scope.src.teachers
        @$el.append "<div class='tag teacher' data-teacher='#{teacher}'>#{teacher}<b class='close'>&times;</b></div>"
    if @scope.src.danceClasses?
      for danceClass in @scope.src.danceClasses
        day = danceClass.start[0..2]
        @$el.append "<div class='tag #{danceClass.color}' data-id='#{danceClass.id}'>#{i18n.lbl[day]} #{danceClass.start.replace(day, '')}~#{danceClass.end.replace(day, '')}<b class='close'>&times;</b></div>"
    
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
    # parent scope binding.
    scope: 
      # displayed search
      src: '='
      # function to invoke on tag removal
      onRemove: '&'