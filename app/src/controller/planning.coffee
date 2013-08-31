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

  # **private**
  # delay before displaying planning to avoid UI glitches
  _planningDelay: 0

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param location [Object] Angular location service
  constructor: (@scope, @location) -> 
    @scope.teachers = []
    @scope.i18n = i18n
    @scope.$watch 'selected', @_onSelectPlanning
    # injects public methods into scope
    @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'
    # redraw all on initialization
    @scope.$on 'model-initialized', => 
      return if @scope.plannings?
      @_planningDelay = 0
      Planning.findAll @_onPlanningsRetrieved
    @scope.$on '$stateChangeSuccess', =>
      return if @scope.plannings?
      @_planningDelay = 190
      Planning.findAll @_onPlanningsRetrieved

  # Invoked when clicking on a given dance class.
  # displays dancers registered into this class
  #
  # @param event [Event] click event, to check pressed keys
  # @param chosen [Array<DanceClass>] the clicked dance(s) class
  onSelectByClass: (event, chosen) =>
    if event?.ctrlKey
      for danceClass in chosen
        # add or remove
        i = _.indexOf @scope.search.danceClasses, danceClass
        if i isnt -1
          @scope.search.danceClasses.splice i, 1
        else
          @scope.search.danceClasses.push danceClass
    else
      # changes all dance classes
      @scope.search.danceClasses = chosen
    @scope.search.season = @scope.selected.season
    @scope.triggerSearch()

  # Invoked when clicking on a given teacher name.
  # displays dancers registered for this teatcher on current year
  #
  # @param chosen [String] the clicked teacher
  onSelectByTeacher: (chosen) =>
    # update layout controller values
    @scope.search.teacher = chosen
    @scope.search.season = @scope.selected.season
    @scope.search.danceClasses = []
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
    _.delay =>
      @scope.$apply =>
        @scope.plannings = plannings
        @scope.selected = plannings?[0]
    , @_planningDelay

  # **private**
  # When a planning is selected, updates the teacher list
  #
  # @param value [Planning] new selected planning
  # @param old [Planning] previous value
  _onSelectPlanning: (value, old) =>
    return unless value? and value isnt old
    @scope.teachers = _.chain(value.danceClasses).pluck('teacher').uniq().compact().value().sort()