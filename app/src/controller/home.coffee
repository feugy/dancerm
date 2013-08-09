define ['underscore'], (_) ->
  
  class HomeController
              
    # Controller dependencies
    @$inject: ['$scope']
    
    # Controller scope, injected within constructor
    scope: null
    
    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] Angular current scope
    constructor: (@scope) -> 
      # bind methods
      @scope.error = "Hello world !"
      @scope.closeError = @closeError
       
    # Remove the current error, which hides the alert
    closeError: =>
      @scope.error = null