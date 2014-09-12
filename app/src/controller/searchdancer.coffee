Dancer = require '../model/dancer'
  
# Allow to choose a given dancer with autocompletion field
# Intended to be used inside a popup: will returned the selected dancer, or null in case of cancellation
# You must give an existing dancer to this controller for labels
module.exports = class SearchController

  # Controller dependencies
  @$inject: ['existing', '$modalInstance']

  # Popup declaration
  @declaration:
    controller: SearchController
    controllerAs: 'ctrl'
    templateUrl: 'searchdancer.html'

  # selected dancer
  dancer: null

  # existing dancer, that will be merged with selected dancer
  existing: null

  # avoid tirggering multiple search simultaneously
  _reqInProgress: false

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param dialog [Object] current dialog instance
  constructor: (@existing, @_dialog) ->
    @dancer = null
    @_reqInProgress = false

  # Displays firstname and lastname of a given dancer
  #
  # @return formated name
  formatDancer: =>
    return "" unless @dancer?
    "#{@dancer.firstname} #{@dancer.lastname}"

  # Search within existing dancers a match on lastname
  #
  # @param typed [String] typed string
  # @return a promise of matching dancers
  search: (typed) =>
    # disable if request in progress
    return [] if @_reqInProgress
    @_reqInProgress = true
    # prepare search conditions
    typed = typed.toLowerCase()
    new Promise (resolve, reject) =>
      # find matching dancers
      Dancer.findWhere(lastname: new RegExp "^#{typed}", 'i').then((models) => 
        @_reqInProgress = false
        # removes models that belongs to the existing's card
        resolve (model for model in models when model.cardId isnt @existing.cardId)
      ).catch (err) ->
        @_reqInProgress = false
        console.error err
        reject err

  # Dialog closure method: will transfer to the dialog parent the searched dancer if confirmed
  #
  # @param confirmed [Boolean] true if the creation is confirmed
  close: (confirmed) =>
    # do not accept confirmed closure if no registration was selected.
    return if confirmed and not @dancer?
    # closes dialog
    @_dialog.close if confirmed then @dancer else null