_ = require 'underscore'
i18n = require '../labels/common'
DanceClass = require '../model/danceclass'
Registration = require '../model/registration'
  
# Allow to choose a given dance class (season selection) and creates the corresponding registration.
# Intended to be used inside a popup: will returned the created Registration object, or null.
# Must be initianlized with an existing registration
#
# Associated with the `template/register.html` view, inside a dialog popup
module.exports = class RegisterController

  # Controller dependencies
  @$inject: ['danceClasses', 'isEdit', '$scope', '$modalInstance']

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

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param danceClassIds [Array<String>] list of existing dance class ids
  # @param scope [Object] Angular current scope
  # @param dialog [Object] current dialog instance
  constructor: (@danceClasses, @isEdit, @scope, @_dialog) ->
    @scope.isEdit = isEdit
    @scope.chooseSeason = @chooseSeason
    @scope.close = @close
    @scope.danceClasses = @danceClasses

    DanceClass.listSeasons().then((seasons) =>
      @scope.seasons = seasons
      unless @scope.seasons.length is 0
        @scope.chooseSeason @scope.seasons[0]
      else
        @scope.$apply()
    ).catch (err) => console.error err

  # Invoked by view to update the selected season.
  # Refresh the available dance class list
  #
  # @param season [String] the new selected season 
  chooseSeason: (season) =>
    DanceClass.getPlanning(season).then((planning) =>
      @scope.planning = planning
      @scope.currSeason = season
      @scope.$apply()
    ).catch (err) => console.error err

  # Dialog closure method: will transfer to the dialog parent the created registration if confirmed
  #
  # @param confirmed [Boolean] true if the creation is confirmed
  close: (confirmed) =>
    # do not accept confirmed closure if no registration was selected.
    return if confirmed and @scope.src is null
    @_dialog.close 
      confirmed: confirmed
      season: @scope.currSeason
      danceClasses: @scope.danceClasses