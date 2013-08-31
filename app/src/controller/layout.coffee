_ = require 'underscore'
async = require  'async'
i18n = require  '../labels/common'
Dancer = require  '../model/dancer/dancer'
  
module.exports = class LayoutController
              
  # Controller dependencies
  # Inject storage to ensure that models are properly initialized
  @$inject: ['$scope', 'export', 'import', '$dialog']
  
  # Controller scope, injected within constructor
  scope: null

  # Link to export service
  export: null

  # Link to import service
  import: null
      
  # Link to Angular dialog service
  dialog: null

  # **private**
  # Disable concurrent search. Only first search is taken in account
  _searchPending: false

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param export [Export] Export service
  # @param import [import] Import service
  # @param dialog [Object] Angular dialog service
  constructor: (@scope, @export, @import, @dialog) -> 
    @_searchPending = false
    # displayed dancer's list
    @scope.list = []
    # search criteria
    @scope.search = 
      danceClasses: null
      season: null
      string: null
      teacher: null
    # displayed dancer.
    @scope.displayed = null
    # injects public methods into scope
    @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'
    # dump data immediately
    @scope.$on 'model-initialized', => 
      @_loadDumpEntry (err) =>
        @dialog.messageBox(i18n.ttl.dump, _.sprintf(i18n.err.dumpFailed, err.message), [label: i18n.btn.ok]).open() if err?

  # Trigger the search based on `scope.search` descriptor.
  # `scope.list` will be updated at the search end.
  triggerSearch: =>
    return if @_searchPending
    conditions = {}
    # depending on criterias
    if @scope.search.name?.length >= 3 
      # find all dancers by first name/last name
      searched = @scope.search.name.toLowerCase()
      conditions.id = (id, dancer) -> 
        0 is dancer.firstname?.toLowerCase().indexOf(searched) or 0 is dancer.lastname?.toLowerCase().indexOf searched

    # find all dancers by season and optionnaly by teacher for this season
    conditions['registrations.planning.season'] = @scope.search.season if @scope.search.season?
    
    if @scope.search.danceClasses?.length > 0
      ids = _.pluck @scope.search.danceClasses, 'id'
      # select class students: can be combined with season and name
      conditions['registrations.danceClassIds'] = (id) -> id in ids
    else if @scope.search.teacher?
      # add teacher if needed: can be combined with season and name
      conditions['registrations.danceClasses.teacher'] = @scope.search.teacher if @scope.search.teacher?
    
    # clear list content
    return @scope.list = [] if _.isEmpty conditions
    @_searchPending = true
    Dancer.findWhere conditions, (err, dancers) =>
      @_searchPending = false
      return @dialog.messageBox(i18n.ttl.search, _.sprintf(i18n.err.search, err.message), [label: i18n.btn.nok]).open() if err?
      @scope.$apply =>
        @scope.list = dancers


  # Read a given xlsx file to import dancers.
  # Existing dancers (same firstname/lastname) are not modified
  importDancers: =>
    dialog = $('<input style="display:none;" type="file" accept="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>')
    dialog.change (evt) =>
      filePath = dialog.val()
      dialog.remove()
      # dialog cancellation
      return unless filePath
      @import.fromFile filePath, (err, dancers) =>
        err = new Error "No dancers found" if !err? and dancers?.length is 0
        if err?
          console.error "Import failed: #{err}"
          # displays an error dialog
          return @scope.$apply =>
            @dialog.messageBox(i18n.ttl.import, _.sprintf(i18n.err.importFailed, err.message), [label: i18n.btn.ok]).open()

        # get all existing dancers
        Dancer.findAll (err, existing) =>
          return console.error err if err?
          imported = 0
          # get existing names
          names = _.map existing, (existing) -> existing?.lastname?.toLowerCase()+existing?.firstname.toLowerCase()
          async.forEach dancers, (dancer, next) =>
            # save each dancers unless it already exists
            return next() if _.find(names, (name) -> dancer?.lastname?.toLowerCase()+dancer?.firstname.toLowerCase() is name)?
            imported++
            dancer.save next
          , (err) =>
            console.info "#{imported}/#{dancers.length} dancers imported"
            @scope.$apply =>
              @dialog.messageBox(i18n.ttl.import, _.sprintf(i18n.msg.importSuccess, imported, dancers.length), [label: i18n.btn.ok]).open()

    dialog.trigger 'click'

  # **private**
  # Load from localStorage the saved dump fileEntry, and reloads it.
  # @param callback [Function] invoked when dump is finished, with arguments.
  # @option callback error [Error] an error object or null if no error occurred.
  _loadDumpEntry: (callback) =>
    # nothing in localStorage
    dumpPath = localStorage.getItem 'dumpPath'
    return @_chooseDumpLocation callback unless dumpPath
    console.info 'resuse file location from local storage...', dumpPath
    @export.dump dumpPath, callback  

  # **private**
  # Ask user to choose a dump location, and immediately dump data inside.
  # @param callback [Function] invoked when dump is finished, with arguments.
  # @option callback error [Error] an error object or null if no error occurred.
  _chooseDumpLocation: (callback) =>
    # first, explain what we're asking
    @dialog.messageBox(i18n.ttl.dump, i18n.msg.dumpData, [label: i18n.btn.ok]).open().then =>
      dialog = $('<input style="display:none;" type="file" nwsaveas value="dump_dancerm.json" accept="application/json"/>')
      dialog.change (evt) =>
        dumpPath = dialog.val()
        dialog.remove()
        # dialog cancellation
        return @_chooseDumpLocation() unless dumpPath
        # retain entry for next loading
        localStorage.setItem 'dumpPath', dumpPath
        return callback err if err?
        # immediately dump data
        @export.dump dumpPath, callback

      dialog.trigger 'click'
