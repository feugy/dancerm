_ = require 'underscore'
i18n = require '../labels/common'
Planning = require '../model/planning/planning'
Dancer = require '../model/dancer/dancer'

module.exports = class PlanningController
              
  # Controller dependencies
  @$inject: ['$scope', '$location']
  
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
    # injects public methods into scope
    @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'
    # redraw all on initialization
    @scope.$on 'model-initialized', refreshNow = => 
      @_planningDelay = 0
      Planning.findAll @_onPlanningsRetrieved
    @scope.$on 'model-imported', =>
      @scope.triggerSearch()
      refreshNow()
    @scope.$on '$stateChangeSuccess', =>
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
    # removes teachers because multiple classes may be held by different teachers
    @scope.search.teachers = []
    # reset season to match corresponding
    @scope.search.seasons = [@scope.selected.season]
    @scope.triggerSearch()

  # Invoked when clicking on a given teacher name.
  # displays dancers registered for this teatcher on current year
  #
  # @param event [Event] click event, to check pressed keys
  # @param chosen [String] the clicked teacher, may be empty
  onSelectByTeacher: (event, chosen = null) =>
    season = @scope.selected.season
    if event?.ctrlKey
      if chosen?
        # add or remove teacher
        i = _.indexOf @scope.search.teachers, chosen
        if i isnt -1
          @scope.search.teachers.splice i, 1
        else
          @scope.search.teachers.push chosen
      else 
        # add or remove season
        i = _.indexOf @scope.search.seasons, season
        if i isnt -1
          @scope.search.seasons.splice i, 1
        else
          @scope.search.seasons.push season
    else
      # changes all teachers or seasons
      if chosen?
        @scope.search.teachers = [chosen]
      else
        @scope.search.seasons = [season]
    # removes danceClasses because they cannot belong to multiple plannings/teachers
    @scope.search.danceClasses = []
    @scope.triggerSearch()

  # Invoked to display an empty dancer's screen
  onNewDancer: =>
    console.log "ask to display new dancer"
    @location.path "/home/dancer/"

  # When a planning is selected, updates the teacher list
  #
  # @param planning [Planning] new selected planning
  onSelectPlanning: (planning) =>
    @scope.selected = planning
    @scope.teachers = []
    return unless planning?
    @scope.teachers = _.chain(planning.danceClasses).pluck('teacher').uniq().compact().value().sort()

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
        @scope.plannings = _.sortBy(plannings, 'season').reverse()
        @onSelectPlanning(@scope.plannings?[0])
    , @_planningDelay