_ = require 'lodash'
i18n = require '../labels/common'
DanceClass = require '../model/dance_class'
Registration = require '../model/registration'
  
# Allow to choose a given dance class (season selection) and creates the corresponding registration.
# Intended to be used inside a popup: will returned the created Registration object, or null.
# Must be initianlized with an existing registration
module.exports = class RegisterController

  # Controller dependencies
  @$inject: ['danceClasses', 'isEdit', '$scope', '$modalInstance']

  # Popup declaration
  @declaration:
    controller: RegisterController
    controllerAs: 'ctrl'
    templateUrl: 'register.html'

  # Current scope for digest triggering
  scope: null

  # Currently modified registration
  src: null

  # differentiate new registration and edition
  isEdit: false

  # Concerned dancer
  dancer: null

  # Current card available registrations
  registrations: null

  # Currently displayed planning
  planning: null

  # Currently selected season
  currSeason: null

  # List of available seasons
  seasons: []

  # Current dialog instance
  _dialog: null

  # previously selected dance classes
  _previous: []

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param danceClassIds [Array<String>] list of existing dance class ids
  # @param scope [Object] Angular current scope
  # @param dialog [Object] current dialog instance
  constructor: (@danceClasses, @isEdit, @scope, @_dialog) ->
    @src = @scope.src
    @_previous = (@danceClasses or []).concat()

    DanceClass.listSeasons (err, seasons) =>
      return console.error err if err?
      @seasons = seasons
      unless @seasons.length is 0
        @chooseSeason @seasons[0]
      else
        @scope.$apply()

  # Invoked by view to update the selected season.
  # Refresh the available dance class list
  #
  # @param season [String] the new selected season 
  chooseSeason: (season) =>
    DanceClass.getPlanning season, (err, planning) =>
      return console.error err if err?
      @planning = planning
      @currSeason = season
      @scope.$apply()

  # Dialog closure method: will transfer to the dialog parent the created registration if confirmed
  #
  # @param confirmed [Boolean] true if the creation is confirmed
  close: (confirmed) =>
    # do not accept confirmed closure if no registration was selected.
    return if confirmed and @src is null
    # retore previous dance classes if not confirmed
    @danceClasses.splice.apply @danceClasses, [0, @danceClasses.length].concat @_previous unless confirmed
    # remove possible duplicates
    uniq = []
    uniq.push danceClass for danceClass in @danceClasses when not (danceClass in uniq)
    @danceClasses = uniq
    # closes dialog
    @_dialog.close 
      confirmed: confirmed
      season: @currSeason
      danceClasses: @danceClasses