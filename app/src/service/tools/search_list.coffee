_ = require 'lodash'
{EventEmitter} = require 'events'
i18n = require  '../../labels/common'

# Abstract service responsible for keeping model list between states
# Triggers search.
# Subclass must:
# - define static property `ModelClass`
# - implement funciton `_parseCriteria`
# - define static property `sort`
# - define criteria prior to invoke super constructor
module.exports = class SearchList extends EventEmitter

  # **static**
  # Service's dependencies
  @$inject: ['$rootScope', 'dialog', 'conf']

  # Current list of models.
  # Change search and invoke performSearch to change
  list: []

  # Search criteria: depends on the model
  criteria: {}

  # **private**
  # Flag to inhibit concurrent searchs
  _searchPending: false

  # Build service singleton
  # @param rootScope [Scope] angular rootscope, to apply digest at search end
  # @param dialog [Object] Dialog service to display search errors
  # @param conf [Object] Configuration service
  constructor: (@rootScope, @dialog, @conf) ->
    throw new Error "#{@constructor.name} must provide static property ModelClass" unless @constructor.ModelClass?
    throw new Error "#{@constructor.name} must provide static property sort" unless @constructor.sort?
    throw new Error "#{@constructor.name} must provide function _parseCriteria" unless @_parseCriteria?

    super()
    @setMaxListeners 100
    @list = []
    @_queued = null

    # reload from locale storage previous execution's search.
    @criteria = @conf[@_getStorageKey()] if @conf[@_getStorageKey()]?

  # **private**
  # @returns [String] lowercased string usable as configuration key
  _getStorageKey: => "#{@constructor.ModelClass.name.toLowerCase()}Search"

  # Getter to check if service is currently searching
  #
  # @return [Boolean] true is searching, false otherwiser
  isSearching: => @_searchPending

  # Trigger the search based on search global descriptor.
  # Global list will be updated at the search end.
  #
  # @param allowEmpty [Boolean] true to search for all if no condition given.
  performSearch: (allowEmpty = false) =>
    search = =>
      # TODO: deydrate models (danceclass)
      @criteria = @_queued.criteria
      allowEmpty = @_queued.allowEmpty
      @_queued = null

      console.log "search for", @criteria
      @emit 'search-start'
      # store into local storage for reload
      @conf[@_getStorageKey()] = @criteria
      @conf.save()
      # depending on criterias
      conditions = @_parseCriteria()
      console.log "criteria are", conditions
      # clear list content, without reaffecting it
      return @_displayResults [] if _.isEmpty(conditions) and not allowEmpty
      @_searchPending = true

      # now search for models
      @constructor.ModelClass.findWhere conditions, (err, models) =>
        @_searchPending = false

        # immediatly run next search if needed
        return search() if @_queued?
        if err?
          @dialog.messageBox i18n.ttl.search, _.template(i18n.err.search)(err), [label: i18n.btn.nok]
          @emit 'search-end'
        else
          # sort and update list content, without reaffecting the list
          @_displayResults _.sortBy models, @constructor.sort
        @rootScope.$digest()

    @_queued =
      criteria: _.merge {}, @criteria
      allowEmpty: allowEmpty

    # use evalAsync to ensure search to be called after a possible
    # digest (which would shadow the execution)
    @rootScope.$evalAsync =>
      search() unless @_searchPending




  # **private**
  # Replace classe's list with new results
  #
  # @param results [Array<Model>] new list of models
  _displayResults: (results) =>
    # do not update list variable because of bindings, and update content
    @list.splice.apply @list, [0, @list.length].concat results
    console.log "got #{@list.length} models"
    @emit 'search-end'