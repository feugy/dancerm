_ = require 'underscore'
i18n = require  '../labels/common'
Dancer = require  '../model/dancer'

# stores current list and search criteria globaly to avoid re-searching between two states
list = []
search = 
  string: null
  teachers: []
  seasons: []
  danceClasses: []
try 
  search = JSON.parse localStorage.search if localStorage.search?
catch err
  # silent error

_dumpInProgress = false

module.exports = class LayoutController
              
  # Controller dependencies
  @$inject: ['$rootScope', 'import', 'dialog', '$state', '$filter']

  @declaration:
    abstract: true
    controller: LayoutController
    controllerAs: 'ctrl'
    templateUrl: 'columnandmain.html'
    resolve: 
      $list: => list
      $search: => search
  
  # Global scope, for digest triggering
  rootScope: null

  # Link to import service
  import: null
      
  # Link to Angular's dialog service
  dialog: null

  # Link to Angular's state provider
  state: null

  # indicates which parts are visible
  visible:
    main: true
    column: true

  # i18n values, for rendering
  i18n: i18n

  # Application version
  version: version

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular global scope, for digest triggering
  # @param import [import] Import service
  # @param dialog [Object] Angular dialog service
  # @param state [Object] Angular state provider
  # @param filter [Function] Angular's filter factory
  constructor: (@rootScope, @import, @dialog, @state, @filter) -> 
    # updates main existance when state is loaded
    @rootScope.$on '$stateChangeSuccess', checkVisible = =>
      @visible.main = @state?.current?.views?.main?
      @visible.column = @state?.current?.views?.column?
    checkVisible()
    # Ask immediately dump entry if missing
    @_loadDumpEntry()


  # Extract and dasherize name of a controller used
  #
  # @param kind [String] column or main, depending on what is required
  # @return the css class corresponding to current column/main controller
  getClass: (kind) => 
    name = @state?.current?.views?[kind]?.controller?.name
    return '' unless name?
    _.dasherize name[0].toLowerCase() + name[1..]

  # Indicates which part is empty and which is expanded by consulting all part visibility
  #
  # @param kind [String] name of the tested part
  # @return 'empty' if part isn't visible, 'expanded' if it's the only visible, an empty string otherwise
  getVisibility: (kind) =>
    result = 'empty'
    for part, visible of @visible
      result = '' if part is kind and visible and result is 'empty'
      result = 'expanded' if part isnt kind and @visible[kind] and not visible
    result

  # Read a given xlsx file to import dancers.
  # Existing dancers (same firstname/lastname) are not modified
  importDancers: =>
    dialog = $('<input style="display:none;" type="file" accept=".dump,.json,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>')
    dialog.change (evt) =>
      filePath = dialog.val()
      dialog.remove()
      # dialog cancellation
      return unless filePath
      dialog = @dialog.messageBox i18n.ttl.import, i18n.msg.importing
    
      msg = null
      displayEnd = =>
        _.delay => 
          @rootScope.$apply =>
            dialog.dismiss()
            @dialog.messageBox(i18n.ttl.import, msg, [label: i18n.btn.ok]).result.then =>
              # refresh all
              @rootScope.$broadcast 'model-imported'
        , 100

      @import.fromFile(filePath).then(({models, report}) =>
        throw new Error "No dancers found" if models?.length is 0
        console.info "importation report:", report

        # get all existing dancers
        @import.merge(models).then (report) =>
          console.info "merge report:", report
          msg = @filter('i18n') 'msg.importSuccess', args: report.byClass
      ).then( =>
        displayEnd()
      ).catch (err) => 
        console.error "got error", err
        msg = _.sprintf i18n.err.importFailed, err.message
        displayEnd()

    dialog.trigger 'click'
    null

  # **private**
  # Load from localStorage the saved dump fileEntry, and reloads it.
  # @param callback [Function] invoked when dump is finished, with arguments.
  # @option callback error [Error] an error object or null if no error occurred.
  _loadDumpEntry: (callback) =>
    return if _dumpInProgress
    # nothing in localStorage
    dumpPath = localStorage.getItem 'dumpPath'
    @_chooseDumpLocation callback unless dumpPath
    null

  # **private**
  # Ask user to choose a dump location, and immediately dump data inside.
  # @param callback [Function] invoked when dump is finished, with arguments.
  # @option callback error [Error] an error object or null if no error occurred.
  _chooseDumpLocation: (callback) =>
    _dumpInProgress = true
    # first, explain what we're asking
    @dialog.messageBox(i18n.ttl.dump, i18n.msg.dumpData, [label: i18n.btn.ok]).result.then =>
      dialog = $('<input style="display:none;" type="file" nwsaveas value="dump_dancerm.json" accept="application/json"/>')
      dialog.change (evt) =>
        dumpPath = dialog.val()
        dialog.remove()
        # dialog cancellation
        return @_chooseDumpLocation() unless dumpPath
        _dumpInProgress = false
        # retain entry for next loading
        localStorage.setItem 'dumpPath', dumpPath
        return callback err if err?

      dialog.trigger 'click'