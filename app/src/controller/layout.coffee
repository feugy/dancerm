define [
  'underscore'
  'async'
  'i18n!nls/common'
  '../model/dancer/dancer'
], (_, async, i18n, Dancer) ->
  
  class LayoutController
              
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

    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] Angular current scope
    # @param export [Export] Export service
    # @param import [import] Import service
    # @param dialog [Object] Angular dialog service
    constructor: (@scope, @export, @import, @dialog) -> 
      # displayed dancer's list
      @scope.list = []
      # search criteria
      @scope.search = 
        classId: null
      # displayed dancer.
      @scope.displayed = null
      # injects public methods into scope
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'
      # dump data immediately
      #@_loadDumpEntry (err) =>
      #  console.error err if err?

    # Trigger the search based on `scope.search` descriptor.
    # `scope.list` will be updated at the search end.
    triggerSearch: =>
      console.log "search with criteria", @scope.search
      if @scope.search.classId?
        # find all dancers in this dance class
        return Dancer.findWhere {'registrations.danceClassIds': @scope.search.classId}, (err, dancers) =>
          throw err if err?
          @scope.$apply =>
            @scope.list = dancers

    # Read a given xlsx file to import dancers.
    # Existing dancers (same firstname/lastname) are not modified
    importDancers: =>
      chrome.fileSystem.chooseEntry {
        acceptsAllTypes: false
        accepts: [
          extensions: ['xlsx'] 
          mimeTypes: ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
        ]}, (fileEntry) =>
          # dialog cancellation
          return unless fileEntry?
          @import.fromFile fileEntry, (err, dancers) =>
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

    # **private**
    # Load from localStorage the saved dump fileEntry, and reloads it.
    # @param callback [Function] invoked when dump is finished, with arguments.
    # @option callback error [Error] an error object or null if no error occurred.
    _loadDumpEntry: (callback) =>
      ### nothing in localStorage
      chrome.storage.local.get 'dumpEntry', (fileEntry) =>
        return @_chooseDumpLocation callback unless fileEntry?
        #chrome.fileSystem.restoreEntry chrome.storage.local.dumpEntry, (fileEntry) =>
        console.info 'resuse file location from local storage...', fileEntry
        @_dump fileEntry, callback###

    # **private**
    # Dump data into selected file
    #
    # @param fileEntry [FileEntry] the selected file entry
    # @param callback [Function] invoked when dump is finished, with arguments.
    # @option callback error [Error] an error object or null if no error occurred.
    _dump: (fileEntry, callback) => 
      ###@export.dump fileEntry, (err) =>
        return callback err if err?
        callback null###

    # **private**
    # Ask user to choose a dump location, and immediately dump data inside.
    # @param callback [Function] invoked when dump is finished, with arguments.
    # @option callback error [Error] an error object or null if no error occurred.
    _chooseDumpLocation: (callback) =>
      ###chrome.fileSystem.chooseEntry {
        type: 'saveFile'
        acceptsAllTypes: false
        suggestedName: 'dancerm-dump.json'
        accepts: [
          extensions: ['json'] 
          mimeTypes: ['application/json']
        ]}, (fileEntry) =>
          return @_chooseDumpLocation() unless fileEntry?
          # retain entry for next loading
          #retainId = chrome.fileSystem.retainEntry fileEntry
          chrome.storage.local.set dumpEntry: fileEntry, (err) =>
            return callback err if err?
            # immediately dump data
            @_dump fileEntry, callback###
