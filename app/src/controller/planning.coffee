define [
  'underscore'
  '../model/planning/planning'
  '../model/dancer/dancer'
], (_, Planning, Dancer) ->
  
  class PlanningController
              
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
      # Retrieve all plannings
      Planning.findAll @_onPlanningsRetrieved
      # injects public methods into scope
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'
      # redraw all on initialization
      @scope.$on 'model-initialized', => Planning.findAll @_onPlanningsRetrieved

    # Invoked when clicking on a given dance class.
    # displays dancers registered into this class
    #
    # @param chosen [DanceClass] the clicked dance class
    onDisplayClass: (chosen) =>
      # update layout controller values
      @scope.search.classId = chosen.id
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