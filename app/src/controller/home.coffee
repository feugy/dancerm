define [
  '../model/planning/planning'
], (Planning) ->
  
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
      # Display first planning TODO
      Planning.findAll (err, models) =>
        throw err if err?
        @scope.$apply =>
          @scope.planning = models[0]

      # injects public methods into scope
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # Navigate to another controller
    #
    # @param dest [String] destination route
    navigateTo: (dest) =>
      @location.path dest