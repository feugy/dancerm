_ = require 'underscore'
i18n = require  '../labels/common'
Dancer = require  '../model/dancer'
  
module.exports = class LayoutController
              
  # Controller dependencies
  @$inject: ['$rootScope', 'import', 'dialog', '$state']
  
  # Global scope, for digest triggering
  rootScope: null

  # Link to import service
  import: null
      
  # Link to Angular's dialog service
  dialog: null

  # Link to Angular's state provider
  state: null

  # indicates whether a main view is visible or not
  hasMain: true

  # dancer displayed list
  list: []

  # search criteria
  search:
    danceClasses: []
    seasons: []
    string: null
    teachers: []

  # flag indicating wether the edited main part has changed or not
  hasChanged: false

  # i18n values, for rendering
  i18n: i18n

  # **private**
  # Disable concurrent search. Only first search is taken in account
  _searchPending: false

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular global scope, for digest triggering
  # @param import [import] Import service
  # @param dialog [Object] Angular dialog service
  # @param state [Object] Angular state provider
  constructor: (@rootScope, @import, @dialog, @state) -> 
    @_searchPending = false
    @_isExpand = false
    # updates main existance when state is loaded
    @rootScope.$on '$stateChangeSuccess', checkMain = =>
      @hasMain = @state?.current?.views?.main?
    @hasMain = checkMain()

    # displayed dancer's list
    @list = []
    # search criteria
    @search = 
      danceClasses: []
      seasons: []
      string: null
      teachers: []
    @hasChanged = false
    # Ask immediately dump entry if missing
    @_loadDumpEntry()

  # Trigger the search based on `search` descriptor.
  # `list` will be updated at the search end.
  triggerSearch: =>
    console.log "search for", @search
    return if @_searchPending
    conditions = {}
    # depending on criterias
    if @search.name?.length >= 3 
      # find all dancers by first name/last name
      searched = @search.name.toLowerCase()
      conditions.$where = () -> 
        0 is @firstname?.toLowerCase().indexOf(searched) or 
        0 is @lastname?.toLowerCase().indexOf(searched) or
        0 is @address?.city?.toLowerCase().indexOf(searched)

    # find all dancers by season and optionnaly by teacher for this season
    if @search.seasons?.length > 0
      conditions['danceClasses.season'] = $in: @search.seasons
    
    if @search.danceClasses?.length > 0
      # select class students: can be combined with season and name
      conditions['danceClassIds'] = $in: _.pluck @search.danceClasses, 'id'
    else if @search.teachers?.length > 0
      # add teacher if needed: can be combined with season and name
      conditions['danceClasses.teacher'] = $in: @search.teachers
    
    # clear list content
    return @list = [] if _.isEmpty conditions
    @_searchPending = true
    Dancer.findWhere(conditions).then((dancers) =>
      @_searchPending = false
      @list = _.sortBy dancers, 'lastname'
      @rootScope.$apply()
    ).catch (err) =>
      @_searchPending = false
      @dialog.messageBox i18n.ttl.search, _.sprintf(i18n.err.search, err.message), [label: i18n.btn.nok]
      @rootScope.$apply()

  # Read a given xlsx file to import dancers.
  # Existing dancers (same firstname/lastname) are not modified
  importDancers: =>
    dialog = $('<input style="display:none;" type="file" accept="application/json,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>')
    dialog.change (evt) =>
      filePath = dialog.val()
      dialog.remove()
      # dialog cancellation
      return unless filePath
      @rootScope.$apply => 
        dialog = @dialog.messageBox i18n.ttl.import, i18n.msg.importing
      @import.fromFile filePath, (err, dancers) =>
        err = new Error "No dancers found" if !err? and dancers?.length is 0
        if err?
          console.error "Import failed: #{err}"
          # displays an error dialog
          return @rootScope.$apply =>
            dialog.close()
            @dialog.messageBox i18n.ttl.import, _.sprintf(i18n.err.importFailed, err.message), [label: i18n.btn.ok]

        # get all existing dancers
        Dancer.findAll().then((existing) =>
          @import.merge existing, dancers, (err, imported) =>
            console.info "#{imported}/#{dancers.length} dancers imported"
            @rootScope.$apply =>
              dialog.close()
              msg = if err? then  _.sprintf(i18n.err.importFailed, err.message) else _.sprintf i18n.msg.importSuccess, imported, dancers.length
              @dialog.messageBox(i18n.ttl.import, msg, [label: i18n.btn.ok]).result.then =>
                # refresh all
                @rootScope.$broadcast 'model-imported'
        ).catch (err) =>
          @rootScope.$apply =>
            dialog.close()
          console.error err 
    dialog.trigger 'click'
    null

  # **private**
  # Load from localStorage the saved dump fileEntry, and reloads it.
  # @param callback [Function] invoked when dump is finished, with arguments.
  # @option callback error [Error] an error object or null if no error occurred.
  _loadDumpEntry: (callback) =>
    # nothing in localStorage
    dumpPath = localStorage.getItem 'dumpPath'
    @_chooseDumpLocation callback unless dumpPath
    null

  # **private**
  # Ask user to choose a dump location, and immediately dump data inside.
  # @param callback [Function] invoked when dump is finished, with arguments.
  # @option callback error [Error] an error object or null if no error occurred.
  _chooseDumpLocation: (callback) =>
    # first, explain what we're asking
    @dialog.messageBox(i18n.ttl.dump, i18n.msg.dumpData, [label: i18n.btn.ok]).result.then =>
      dialog = $('<input style="display:none;" type="file" nwsaveas value="dump_dancerm.json" accept="application/json"/>')
      dialog.change (evt) =>
        dumpPath = dialog.val()
        dialog.remove()
        # dialog cancellation
        return @_chooseDumpLocation() unless dumpPath
        # retain entry for next loading
        localStorage.setItem 'dumpPath', dumpPath
        return callback err if err?

      dialog.trigger 'click'