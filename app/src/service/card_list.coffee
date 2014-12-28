_ = require 'lodash'
{EventEmitter} = require 'events'
i18n = require  '../labels/common'
Dancer = require  '../model/dancer'

# Service responsible for keeping the card list between states
# Triggers search.
module.exports = class CardList extends EventEmitter

  # **static**
  # Service's dependencies
  @$inject: ['$rootScope', 'dialog']

  # Current list of cards. 
  # Change search and invoke performSearch to change
  list: []

  # Search criteria
  criteria: 
    string: null
    teachers: []
    seasons: []
    danceClasses: []

  # **private**
  # Flag to inhibit concurrent searchs
  _searchPending: false

  # Build service singleton
  # @param rootScope [Scope] angular rootscope, to apply digest at search end
  # @param dialog [Object] Dialog service to display search errors
  constructor: (@rootScope, @dialog) ->
    super()
    @setMaxListeners 100
    @list = []
    @criteria = 
      string: null
      teachers: []
      seasons: []
      danceClasses: []

    # reload from locale storage previous execution's search.
    if localStorage?
      try 
        @criteria = JSON.parse localStorage.search if localStorage.search?
      catch err
        # silent error

    # initialize list
    @performSearch()

  # Trigger the search based on search global descriptor.
  # Global list will be updated at the search end.
  performSearch: =>
    return if @_searchPending
    console.log "search for", @criteria
    @emit 'search-start'
    # store into local storage for reload
    localStorage.search = JSON.stringify @criteria if localStorage?
    conditions = {}
    # depending on criterias
    if @criteria.string?.length >= 3 
      # find all dancers by first name/last name
      conditions.$or = [
        {firstname: new RegExp "^#{@criteria.string}", 'i'},
        {lastname: new RegExp "^#{@criteria.string}", 'i'}
      ]
      
    # find all dancers by season and optionnaly by teacher for this season
    if @criteria.seasons?.length > 0
      conditions['danceClasses.season'] = $in: @criteria.seasons
    
    if @criteria.danceClasses?.length > 0
      # select class students: can be combined with season and name
      conditions['danceClassIds'] = $in: _.pluck @criteria.danceClasses, 'id'
    else if @criteria.teachers?.length > 0
      # add teacher if needed: can be combined with season and name
      conditions['danceClasses.teacher'] = $in: @criteria.teachers
    
    # clear list content, without reaffecting it
    return @_displayResults [] if _.isEmpty(conditions) and not @allowEmpty
    @_searchPending = true

    console.log conditions
    # now search for dancers
    Dancer.findWhere conditions, (err, dancers) =>
      @_searchPending = false
      if err?
        @dialog.messageBox i18n.ttl.search, _.sprintf(i18n.err.search, err.message), [label: i18n.btn.nok]
      else
        # sort and update list content, without reaffecting the list
        @_displayResults _.sortBy dancers, 'lastname'
      @rootScope.$apply()

  # **private**
  # Replace classe's list with new results
  #
  # @param results [Array<Dancer>] new list of dancers
  _displayResults: (results) =>
    console.log "got #{results.length} dancers"
    # do not update list variable because of bindings, and update content
    @list.splice.apply @list, [0, @list.length].concat results
    @emit 'search-end'