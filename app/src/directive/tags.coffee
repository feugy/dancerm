_ = require 'underscore'
moment = require 'moment'

# The tags directive displays tags relative at search criteria
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
      if tag.hasClass 'season'
        @scope.src.season = null
        @scope.src.danceClasses = []
      else if tag.hasClass 'teacher'
        @scope.src.teacher = null
        @scope.src.danceClasses = []
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
    if @scope.src.season
      @$el.append "<div class='tag season'>#{@scope.src.season}<b class='close'>&times;</b></div>"
    if @scope.src.teacher
      @$el.append "<div class='tag teacher'>#{@scope.src.teacher}<b class='close'>&times;</b></div>"
    if @scope.src.danceClasses?
      for danceClass in @scope.src.danceClasses
        @$el.append "<div class='tag #{danceClass.color}' data-id='#{danceClass.id}'>#{danceClass.level or '&nbsp;'}<b class='close'>&times;</b></div>"
    