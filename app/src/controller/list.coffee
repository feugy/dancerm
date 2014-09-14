_ = require 'underscore'
Dancer = require  '../model/dancer'
LayoutController = require './layout'
  
module.exports = class ListController extends LayoutController
  
  @$inject: ['$list', '$search'].concat LayoutController.$inject

  @declaration:
    controller: ListController
    controllerAs: 'ctrl'
    templateUrl: 'list.html'

  # allow to search for empty conditions (within all database)
  allowEmpty: false

  # displayed dancer's list
  list: []

  # Stores current search criteria
  search: {}

  # Displayed columns
  columns: [
    {name: 'firstname', title: 'lbl.firstname'}
    {name: 'lastname', title: 'lbl.lastname'}
    {name: 'certified', title: 'lbl.certified', attr: (dancer) -> 
      dancer.lastRegistration().then (registration) -> registration?.certified(dancer) or false
    }
    {name: 'due', title: 'lbl.due', attr: (dancer) -> 
      dancer.lastRegistration().then (registration) -> registration?.due() or 0
    }
  ]

  # **private**
  # Disable concurrent search. Only first search is taken in account
  _searchPending: false

  # Controller constructor: bind methods and attributes to current scope
  constructor: (@list, @search, parentArgs...) ->
    super parentArgs...
    @_searchPending = false
    @allowEmpty = false

    # refresh search when asked
    @rootScope.$on 'search', @makeSearch
    @makeSearch()

  # Displays a given dancer on the main part
  #
  # @param dancer [Dancer] choosen dancer
  displayDancer: (dancer) =>
    console.log "ask to display #{dancer.id}"
    @state.go 'list-and-card', id:dancer.cardId

  # Trigger the search based on search global descriptor.
  # Global list will be updated at the search end.
  makeSearch: =>
    return if @_searchPending
    console.log "search for", @search
    # store into local storage for reload
    localStorage.search = JSON.stringify @search
    conditions = {}
    # depending on criterias
    if @search.string?.length >= 3 
      # find all dancers by first name/last name
      searched = @search.string.toLowerCase()
      conditions.$where = -> 
        0 is @firstname?.toLowerCase().indexOf(searched) or 
        0 is @lastname?.toLowerCase().indexOf(searched)

    # find all dancers by season and optionnaly by teacher for this season
    if @search.seasons?.length > 0
      conditions['danceClasses.season'] = $in: @search.seasons
    
    if @search.danceClasses?.length > 0
      # select class students: can be combined with season and name
      conditions['danceClassIds'] = $in: _.pluck @search.danceClasses, 'id'
    else if @search.teachers?.length > 0
      # add teacher if needed: can be combined with season and name
      conditions['danceClasses.teacher'] = $in: @search.teachers
    
    # clear list content, without reaffecting it
    return @_displayResults [] if _.isEmpty(conditions) and not @allowEmpty
    @_searchPending = true
    Dancer.findWhere(conditions).then((dancers) =>
      @_searchPending = false
      # sort and update list content, without reaffecting the list
      @_displayResults _.sortBy dancers, 'lastname'
      @rootScope.$apply()
    ).catch (err) =>
      @_searchPending = false
      @dialog.messageBox i18n.ttl.search, _.sprintf(i18n.err.search, err.message), [label: i18n.btn.nok]
      @rootScope.$apply()

  # @return true if the current list concerned a dance class
  canPrintCallList: =>
    @search.string is null and @search.danceClasses.length is 1

  # Print call list from the current day
  # 
  # @param danceClass [DanceClass] danceClass concerned
  printCallList: =>
    try
      preview = window.open 'calllistprint.html'
      preview.danceClass = @search.danceClasses[0]
      preview.list = @list
    catch err
      console.error err
    # a bug obviously
    global.console = window.console

  # **private**
  # Replace classe's list with new results
  #
  # @param results [Array<Dancer>] new list of dancers
  _displayResults: (results) =>
    console.log "got #{results.length} dancers"
    # do not update list variable because of bindings, and update content
    @list.splice.apply @list, [0, @list.length].concat results