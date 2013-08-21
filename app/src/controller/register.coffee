define [
  'underscore'
  'i18n!nls/common'
  '../model/planning/planning'
  '../model/dancer/registration'
], (_, i18n, Planning, Registration) ->
  
  # Allow to choose a given dance class (season selection) and creates the corresponding registration.
  # Intended to be used inside a popup: will returned the created Registration object, or null.
  # Must be initianlized with an existing registration
  #
  # Associated with the `template/register.html` view, inside a dialog popup
  class RegisterController

    # Controller dependencies
    @$inject: ['registration', '$scope', 'dialog']

    # Currently edited registration
    registration: null

    # Controller scope
    scope: null

    # Current dialog instance
    _dialog: null

    # existing plannings
    _plannings: []

    # Controller constructor: bind methods and attributes to current scope
    #
    # @param registration [Registration] currently edited registration
    # @param scope [Object] Angular current scope
    # @param dialog [Object] current dialog instance
    constructor: (@registration, @scope, @_dialog) ->
      # creates a temporary registration for work, and initialized it if necessary
      @scope.handled = new Registration()
      throw new Error "Register controller needs to be passed a registration" unless @registration?
      @scope.handled.planningId = @registration.planningId
      if @scope.handled.planningId?
        @scope.disabledClass =  null
        @scope.title = i18n.ttl.editRegistration
        @scope.isNew = false
      else
        @scope.disabledClass = 'disabled'
        @scope.title = i18n.ttl.newRegistration
        @scope.isNew = true

      @scope.handled.danceClassIds = @registration.danceClassIds.concat()
      # gets all existing plannings
      Planning.findAll @_onPlanningsFetched
      # injects public methods into scope
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # Invoked by view to update the selected season.
    # Refresh the available dance class list
    #
    # @param season [String] the new selected season 
    onUpdateSeason: (season) =>
      # gets the corresponding planning
      @scope.planning = _.findWhere @_plannings, season: season
      # updates id and classes if needed
      if @scope.planning.id isnt @scope.handled.planningId
        @scope.handled.planningId = @scope.planning.id
        @scope.handled.danceClassIds.length = 0
      # allow closure from now
      @scope.disabledClass = null
    
    # Dialog closure method: will transfer to the dialog parent the created registration if confirmed
    #
    # @param confirmed [Boolean] true if the creation is confirmed
    close: (confirmed) =>
      # do not accept confirmed closure if no season was selected.
      return if confirmed and @scope.disabledClass isnt null
      # if confirmed, updates the initial registration and returns result
      if confirmed 
        @registration.planningId = @scope.handled.planningId
        # replace array content without creating another array
        @registration.danceClassIds = @scope.handled.danceClassIds.concat()
      @_dialog.close confirmed

    # **private**
    # Invoked when the planning were retrieved.
    # Updates the rendering with existing plannings
    #
    # @param err [Error] an error object, or null if no problem occured
    # @param plannings [Array<Planning>] list of available plannings 
    _onPlanningsFetched: (err, plannings) =>
      throw err if err?
      # keeps plannings for further use
      @_plannings = plannings
      @scope.$apply =>
        # extracts existing seasons and select first
        @scope.seasons = _.pluck @_plannings, 'season'
        if @registration.planningId?
          @onUpdateSeason _.findWhere(@_plannings, id: @registration.planningId)?.season
        else
          @onUpdateSeason @scope.seasons[0]