define [
  '../model/dancer'
], (Dancer) ->
  
  class HomeController
              
    # Controller dependencies
    @$inject: ['$scope', '$location']
    
    # Controller scope, injected within constructor
    scope: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] Angular current scope
    # @param location [Object] Angular location service
    constructor: (@scope, @location) -> 
      # bind methods
      @scope.error = "Hello world !"
      @scope.closeError = @closeError
      @scope.navigateTo = @navigateTo

      d1 = new Dancer firstname: 'damien', lastname: 'feugas'
      console.log d1
       
    # Remove the current error, which hides the alert
    closeError: =>
      @scope.error = null

    # Navigate to another controller
    #
    # @param dest [String] destination route
    navigateTo: (dest) =>
      @location.path dest