_ = require 'lodash'
{each} = require 'async'
Dancer = require '../model/dancer'

class LessonListDirective

  # Controller dependencies
  @$inject: ['$scope']

  # directive scope, for asynchronous applies
  scope: null

  # list of displayed columns, containing an object with title and attr.
  # title is an i18n path and attr, either a model's attribute or a function (that take rendered model as parameter)
  columns: []

  # Displayed list
  list: []

  # Groups of lesson, on group per dancer.
  # Contains object with attributes:
  # - dancer [Dancer]: the concerned dancer
  # - lessons [Array<Lesson>]: list of lesson for that dancer
  groups: []

  # **private**
  # Array of currently selected lesson across all groups
  _selected: []

  # **private**
  # Flag to avoid concurrent renderings
  _inProgress: false

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  constructor: (@scope) ->
    unwatch = @scope.$watchCollection 'ctrl.list', @_onMakeGroups
    @_inProgress = false
    @_selected = []
    @groups = []

    # free listeners
    @scope.$on '$destroy', => unwatch?()
    setTimeout @_onMakeGroups, 0

  # When a given model is selected or unselected, update the global selected array
  #
  # @param model [Lesson] (de)selected model
  # @param selected [Boolean] new (de)selection state
  toggleLesson: ({model, selected}) =>
    if selected
      @_selected.push model unless @_selected.includes model
    else
      idx = @_selected.indexOf model
      @_selected.splice idx, 1 unless idx is -1
    @onSelect?(lessons: @_selected)

  # **private**
  # From the list of lessons, create one group per dancer.
  # Sort groups from dancer's lastname.
  _onMakeGroups: =>
    return if @_inProgress
    @_inProgress = true
    @groups = []
    groupsById = {}

    for lesson in @list
      groupsById[lesson.dancerId] = [] unless lesson.dancerId of groupsById
      groupsById[lesson.dancerId].push lesson

    # asynchrnously get all concerned dancers
    each Object.keys(groupsById), (dancerId, next) =>
      Dancer.find dancerId, (err, dancer) =>
        return next err if err?
        @groups.push {
          dancer: dancer,
          # make sure that dancer is loaded in cache for each lesson
          lessons: (for lesson in groupsById[dancerId]
            lesson.setDancer dancer
            lesson
          )
        }
        next()
    , (err) =>
      @_inProgress = false
      return console.error err if err?
      @groups.sort ({dancer: dancerA}, {dancer: dancerB}) ->
        if dancerA.lastname.toLowerCase() < dancerB.lastname.toLowerCase() then -1 else 1
      @scope.$apply() unless @scope.$$phase

# The tags directive displays tags relative at search criteria
module.exports = (app) ->
  app.directive 'lessonList', ->
    # directive template
    templateUrl: 'lesson_list.html'
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: LessonListDirective
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope:
      # displayed model list
      list: '=src'
      # displayed columns (same for all groups)
      columns: '='
      # current sort column name (same for all groups)
      currentSort: '='
      # click handler, invoked with concerned model as 'model' parameter, and column as 'column' parameter
      onClick: '&?'
      # selection handler, invoked with a list of lesson as 'lessons'
      onSelect: '&?'