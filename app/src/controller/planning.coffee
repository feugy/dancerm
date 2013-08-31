_ = require 'underscore'
i18n = require '../labels/common'
Planning = require '../model/planning/planning'
Dancer = require '../model/dancer/dancer'

module.exports = class PlanningController
              
  # Controller dependencies
  # Inject storage to ensure that models are properly initialized
  @$inject: ['$scope', '$location', 'storage']
  
  # Controller scope, injected within constructor
  scope: null
  
  # Link to Angular location provider
  location: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param location [Object] Angular location service
  constructor: (@scope, @location) -> 
    # first fetch
    Planning.findAll @_onPlanningsRetrieved
    @scope.teachers = []
    @scope.i18n = i18n
    @scope.$watch 'selected', @_onSelectPlanning
    # injects public methods into scope
    @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'
    # redraw all on initialization
    @scope.$on 'model-initialized', => Planning.findAll @_onPlanningsRetrieved

  # Invoked when clicking on a given dance class.
  # displays dancers registered into this class
  #
  # @param chosen [DanceClass] the clicked dance class
  onSelectByClass: (chosen) =>
    # update layout controller values
    @scope.search.string = null
    @scope.search.classId = chosen.id
    @scope.search.season = null
    @scope.search.teacher = null
    @scope.triggerSearch()

  # Invoked when clicking on a given teacher name.
  # displays dancers registered for this teatcher on current year
  #
  # @param chosen [String] the clicked teacher. May be null to select no dancers
  onSelectByTeacher: (chosen) =>
    # update layout controller values
    @scope.search.string = null
    @scope.search.classId = null
    @scope.search.season = @scope.selected.season
    @scope.search.teacher = chosen or null
    @scope.triggerSearch()

  # Invoked to display an empty dancer's screen
  onNewDancer: =>
    console.log "ask to display new dancer"
    @location.path "/home/dancer/"

  # **private**
  # Invoked when all plannings were retrieved.
  # Update rendering and select most recent planning.
  #
  # @param err [Error] an error object, or null if no problem occured
  # @param plannings [Array<Planning>] list of available plannings
  _onPlanningsRetrieved: (err, plannings) =>
    throw err if err?
    @scope.$apply =>
      @scope.plannings = plannings
      @scope.selected = plannings?[0]

  # **private**
  # When a planning is selected, updates the teacher list
  #
  # @param value [Planning] new selected planning
  # @param old [Planning] previous value
  _onSelectPlanning: (value, old) =>
    return unless value? and value isnt old
    @scope.teachers = _.chain(value.danceClasses).pluck('teacher').uniq().compact().value().sort()