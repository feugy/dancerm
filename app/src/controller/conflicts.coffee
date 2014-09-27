_ = require 'underscore'

# Display conflict resolution, pair by pair
module.exports = class ConflictsController

  # Controller dependencies
  @$inject: ['conflicts', '$modalInstance']

  # Popup declaration
  @declaration:
    controller: ConflictsController
    controllerAs: 'ctrl'
    templateUrl: 'conflicts.html'

  #list of conflicts, with `existing` and `imported` properties
  conflicts: []

  # currently displayed conflict rank
  rank: 0

  # currently resolved existing model
  existing: null

  # currently resolved imported model
  imported: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param conflicts [Object] list of conflicts, with `existing` and `imported` properties
  # @param dialog [Object] current dialog instance
  constructor: (@conflicts, @_dialog) ->
    @rank = 1
    @existing = @conflicts[@rank-1].existing
    @imported = @conflicts[@rank-1].imported

  # Return currently resolved model class name
  #
  # @return name of the currently resolve model class
  modelClass: => @existing.constructor.name

  # Compute conflicted fields list
  # For each field that is different between imported and existing models, return field name 
  #
  # @return List of conflicted field names
  modelFields: =>
    (field for field of @existing._raw when not _.isEqual @existing[field], @imported[field]) 

  # Dialog closure method: will transfer to the dialog parent the searched dancer if confirmed
  #
  # @param confirmed [Boolean] true if the creation is confirmed
  close: (confirmed) =>
    @_dialog.close