_ = require 'lodash'
i18n = require '../labels/common'
ConflictsController = require './conflicts'
{buildStyles, getColorsFromTheme} = require '../util/common'

# Edit application settings
module.exports = class SettingsController

  # Controller dependencies
  @$inject: ['$scope', '$rootScope', 'dialog', 'import', '$filter', '$location']

  # Route declaration
  @declaration:
    controller: SettingsController
    controllerAs: 'ctrl'
    templateUrl: 'settings.html'

  # Controller's own scope, for event listening
  scope: null

  # Angular's root scope for event broadcast
  rootScope: null

  # Link to Angular dialog service
  dialog: null

  # Link to dancer import service
  import: null

  # Angular filters factory
  filter: null

  # link to edited properties stored inside localStorage
  localStorage: null

  # True to display message regarding dump location
  askDumpLocation: false

  # list of available theme
  themes: []

  # **private**
  # flag to temporary disable button while theme are building
  _building: false

  # On loading, search for current season
  #
  # @param scope [Object] controller's own scope, for event listening
  # @param rootScope [Object] Angular global scope, for digest triggering
  # @param dialog [Object] Angular dialog service
  # @param import [import] Import service
  # @param filter [Function] Angular's filter factory
  # @param stateParams [Object] invokation route parameters
  constructor: (@scope, @rootScope, @dialog, @import, @filter, location) ->
    @localStorage = localStorage
    @themes = (label: i18n.themes[name], value: name for name of i18n.themes)
    @askDumpLocation = location.search()?.firstRun is true
    @_building = false
    @about = [
      {title: 'DanceRM', image: 'dancerm.png', specs: [
        @filter('i18n') 'lbl.author', args: author: 'Feugy'
        @filter('i18n') 'lbl.version', args: version: require('../../../package.json').version
      ]}
      {title: 'NW.js', image: 'nwjs.png', specs: [
        @filter('i18n') 'lbl.author', args: author: 'Roger Wang'
        @filter('i18n') 'lbl.version', args: version: process.versions['node-webkit']
      ]}
      {title: 'AngularJS', image: 'angular.png', specs: [
        @filter('i18n') 'lbl.author', args: author: 'Google'
        @filter('i18n') 'lbl.version', args: version: angular.version.full
      ]}
      {title: 'Bootstrap', image: 'bootstrap.png', specs: [
        @filter('i18n') 'lbl.author', args: author: 'Twitter'
        @filter('i18n') 'lbl.version', args: version: '3.3.5'
      ]}
    ]

    # cancel navigation if asking for location
    if @askDumpLocation
      @rootScope.$on '$stateChangeStart', (event, toState, toParams) =>
        # stop state change until user choose what to do with pending changes
        event.preventDefault() if @askDumpLocation

  # According to the selected theme, rebuild styles and apply them.
  # New theme is saved into local storage, and button is temporary disabled while compiling
  #
  # @param theme [Object] theme object, containing 'value' and 'label' attribues
  applyTheme: (theme) =>
    return if @_building
    @localStorage.theme = theme.value
    @_building = true
    buildStyles ['dancerm', 'print'], @localStorage.theme or 'none', (err, styles) =>
      @_building = false
      return console.error err if err?
      global.styles = styles
      $('style[data-theme]').remove()
      $('head').append "<style type='text/css' data-theme>#{styles['dancerm']}</style>"
      # now that stylesheet isincluded, get colors
      _.delay getColorsFromTheme, 200

  # Opens a file dialog to select a file used for dumps.
  # File may not exists yet.
  #
  # Dialog won't close unless a path is choosen
  chooseDumpLocation: =>
    dumpDialog = $("<input style='display:none;' type='file' nwsaveas value='#{@localStorage.dumpPath} accept='application/json'/>")
    dumpDialog.change (evt) =>
      dumpPath = dumpDialog.val()
      dumpDialog.remove()
      # dialog cancellation
      return chooseDumpLocation() unless dumpPath
      # retain entry for next loading, and refresh UI
      localStorage.dumpPath = dumpPath
      @askDumpLocation = false
      @scope.$apply()
    dumpDialog.trigger 'click'
    # to avoid issecdom error when directly bound with ngClick
    null

  # Display a file selection dialog to pick a dump file, that may be an xlsx or a 'json' file
  # Try to import contents (use dialog for progression) and resolve potential conflicts afterwise
  importDancers: =>
    dialog = $('<input style="display:none;" type="file" accept=".dump,.json,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>')
    dialog.change (evt) =>
      filePath = dialog.val()
      dialog.remove()
      # dialog cancellation
      return unless filePath
      dialog = @dialog.messageBox @filter('i18n')('ttl.import'), @filter('i18n') 'msg.importing'

      msg = null
      displayEnd = (err) =>
        if err?
          console.error "got error", err
          msg = @filter('i18n') 'err.importFailed', args: err
        _.delay =>
          @rootScope.$apply =>
            dialog.close()
            @dialog.messageBox(@filter('i18n')('ttl.import'), msg, [label: @filter('i18n') 'btn.ok']).result.then =>
              # refresh all
              @rootScope.$broadcast 'model-imported'
        , 100

      @import.fromFile filePath, (err, models, report) =>
        return displayEnd err if err?
        console.info "importation report:", report
        msg = @filter('i18n') 'msg.importSuccess', args: report.byClass

        # get all existing dancers
        @import.merge models, (err, byClass, conflicts) =>
          return displayEnd err if err
          console.info "merge report:", byClass, conflicts
          # resolve conflicts one by one
          return displayEnd() if conflicts.length is 0
          @dialog.modal(_.extend {
              size: 'lg'
              backdrop: 'static'
              keyboard: false
              resolve: conflicts: => conflicts
            }, ConflictsController.declaration
          ).result.then displayEnd

    dialog.trigger 'click'
    null