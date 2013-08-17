define [
  'underscore'
  '../model/planning/planning'
  '../model/dancer/dancer'
], (_, Planning, Dancer) ->
  
  class HomeController
              
    # Controller dependencies
    # Inject storage to ensure that models are properly initialized
    @$inject: ['$scope', '$location', 'storage']
    
    # Controller scope, injected within constructor
    scope: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] Angular current scope
    # @param location [Object] Angular location service
    constructor: (@scope, @location) -> 
      @scope.list = []
      # Retrieve all plannings
      Planning.findAll @_onPlanningsRetrieved
      # injects public methods into scope
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # Navigate to another controller
    #
    # @param dest [String] destination route
    navigateTo: (dest) =>
      @location.path dest

    # Invoked when clicking on a given dance class.
    # displays dancers registered into this class
    #
    # @param chosen [DanceClass] the clicked dance class
    onDisplayClass: (chosen) =>
      # find all dancers in this dance class
      Dancer.findByClass chosen.id, (err, dancers) =>
        throw err if err?
        @scope.$apply =>
          @scope.list = dancers

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