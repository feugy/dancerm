define [
  'underscore'
  '../model/dancer/dancer'
], (_, Dancer) ->
  
  class LayoutController
              
    # Controller dependencies
    # Inject storage to ensure that models are properly initialized
    @$inject: ['$scope']
    
    # Controller scope, injected within constructor
    scope: null

    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] Angular current scope
    constructor: (@scope, @location) -> 
      # displayed dancer's list
      @scope.list = []
      # search criteria
      @scope.search = 
        classId: null
      # displayed dancer.
      @scope.displayed = null
      # injects public methods into scope
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # Trigger the search based on `scope.search` descriptor.
    # `scope.list` will be updated at the search end.
    triggerSearch: =>
      console.log "search with criteria", @scope.search
      if @scope.search.classId?
        # find all dancers in this dance class
        return Dancer.findWhere {'registrations.danceClassIds': @scope.search.classId}, (err, dancers) =>
          throw err if err?
          @scope.$apply =>
            @scope.list = dancers
