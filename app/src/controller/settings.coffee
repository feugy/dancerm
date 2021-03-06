_ = require 'lodash'
{dialog} = require('electron').remote
i18n = require '../labels/common'
DanceClass = require '../model/dance_class'
ConflictsController = require './conflicts'
{buildStyles, getColorsFromTheme, extractDateDetails} = require '../util/common'
{version} = require '../../../package.json'

# Edit application settings
module.exports = class SettingsController

  # controller dependencies
  @$inject: ['$scope', '$rootScope', 'dialog', 'import', '$filter', 'conf', '$location']

  # route declaration
  @declaration:
    controller: SettingsController
    controllerAs: 'ctrl'
    templateUrl: 'settings.html'

  # controller's own scope, for event listening
  scope: null

  # Angular's root scope for event broadcast
  rootScope: null

  # Link to Angular dialog service
  dialog: null

  # link to dancer import service
  import: null

  # Angular filters factory
  filter: null

  # Configuration service
  conf: null

  # edited VAT configuration (percent)
  vat: null

  # edited payer prefix
  payerPrefix: null

  # list of available theme
  themes: []

  # List of available seasons
  seasons: []

  # currently edited season
  currentSeason: null

  # planning for currently edited season
  planning: null

  # currently edited (or added) dance slass in current planning
  editedCourse: null

  # **private**
  # flag to temporary disable button while theme are building
  _building: false

  # **private**
  # Flag to avoid calling multiple dialog
  _dumpDialogDisplayed: false

  # On loading, search for current season
  #
  # @param scope [Object] controller's own scope, for event listening
  # @param rootScope [Object] Angular global scope, for digest triggering
  # @param dialog [Object] Angular dialog service
  # @param import [import] Import service
  # @param filter [Function] Angular's filter factory
  # @param stateParams [Object] invokation route parameters
  constructor: (@scope, @rootScope, @dialog, @import, @filter, @conf, location) ->
    @conf.load () =>
      @vat = @conf.vat * 100
      @scope.$apply()
    @planningDays = i18n.planning.days[...6]
    @themes = (label: i18n.themes[name], value: name for name of i18n.themes)
    @_building = false
    @_dumpDialogDisplayed = false
    imgRoot = '../style/img'
    @about = [
      {title: 'DanceRM', image: "#{imgRoot}/dancerm.png", specs: [
        @filter('i18n') 'lbl.author', args: author: 'Feugy'
        @filter('i18n') 'lbl.version', args: {version}
      ]}
      {title: 'Electron', image: "#{imgRoot}/electron.png", specs: [
        @filter('i18n') 'lbl.author', args: author: 'Github'
        @filter('i18n') 'lbl.version', args: version: process.versions.electron
      ]}
      {title: 'AngularJS', image: "#{imgRoot}/angular.png", specs: [
        @filter('i18n') 'lbl.author', args: author: 'Google'
        @filter('i18n') 'lbl.version', args: version: angular.version.full
      ]}
      {title: 'Bootstrap', image: "#{imgRoot}/bootstrap.png", specs: [
        @filter('i18n') 'lbl.author', args: author: 'Twitter'
        @filter('i18n') 'lbl.version', args: version: '3.3.7'
      ]}
    ]
    @seasons = []
    @editedCourse = null
    @halls = ['Gratte-ciel 1', 'Gratte-ciel 2', 'Croix-Luizet']

    @rootScope.$on 'model-initialized', initPlannings = =>
      DanceClass.listSeasons (err, seasons) =>
        return console.error err if err?
        @seasons = seasons
        @onSelectSeason @seasons[0] unless @seasons.length is 0
        @rootScope.$apply()
    @rootScope.$on 'model-imported', initPlannings
    initPlannings()

    # cancel navigation if asking for location
    if location.search()?.firstRun
      @rootScope.$on '$stateChangeStart', (event, toState, toParams) =>
        # stop state change until user choose what to do with pending changes
        event.preventDefault() unless @conf.dumpPath? && @conf.teachers.length > 0

  # Check that VAT rate is a valid number, and save it if it's the case
  onChangeVat: () =>
    return if isNaN +@vat
    @conf.vat = +@vat / 100
    @conf.save()

  # Check that payer prefix is a non empty word, and save it
  onChangePayerPrefix: () =>
    return unless @payerPrefix?.trim()?.length >= 1
    @conf.payerPrefix = @conf.payerPrefix.trim()
    @conf.save()

  # Updates validates required fields and if valid, save teachers configuration
  onChangeTeachers: () =>
    # TODO chech that owner name is unique
    @conf.teachers = @conf.teachers.map (teacher) ->
      copy = Object.assign {}, teacher
      delete copy.$$hashKey
      copy
    @conf.save()

  # Add a new teacher
  onAddTeacher: () =>
    @conf.teachers.push {}
    @onChangeTeachers()

  # Remove a particular teacher, after confirmation
  #
  # @param teacher [Object] removed teacher
  onRemoveTeacher: (teacher) =>
    idx = @conf.teachers.indexOf teacher
    return if idx is -1
    @dialog.messageBox(i18n.ttl.confirm, @filter('i18n')('msg.removeTeacher', args: teacher), [
        {label: i18n.btn.no}
        {label: i18n.btn.yes, cssClass: 'btn-warning', result: true}
      ]
    ).result.then (confirmed) =>
      return unless confirmed
      # TODO remove plannings, priceList, lessons, registrations, invoices
      @conf.teachers.splice idx, 1
      @onChangeTeachers()

  # When a season is selected, shows its planning
  #
  # @param season [String] selected season
  onSelectSeason: (season) =>
    @currentSeason = season
    DanceClass.getPlanning season, (err, planning) =>
      return console.error err if err?
      @planning = planning
      @onSelectCourse null

  # Add a new season to the season list, and loads it
  onNewSeason: =>
    # compute next season
    [year] = @seasons[0].split '/'
    @seasons.unshift "#{+year+1}/#{+year+2}"
    @onSelectSeason @seasons[0]

  # When a dance class is selected in the planning, update edition form.
  # Discard pending changes on the previsouly edited course.
  #
  # @param course [Object] selected dance class
  onSelectCourse: (course) =>
    # Restore initial values. Will be a noop if saved
    @onRestoreCourse @editedCourse
    @editedCourse = course
    @rootScope.$apply()

  # Detect changes on currently edited course
  #
  # @param field [String] modified field
  # @param value [*] for some field, the new selected value
  onCourseChanged: (field, value) =>
    return unless @editedCourse
    if 'hall' is field
      @editedCourse.hall = value
    else if 'kind' is field
      # search for similar kind
      similar = @planning.find ({kind, id}) => kind is @editedCourse.kind && id isnt @editedCourse.id
      @editedCourse.color = (
        if similar?
          similar.color
        else
          # compute first unused color
          usedColors = @planning.reduce (colors, {color}) =>
            num = +color.replace 'color', ''
            colors.push num unless colors.includes num
            colors
          , []
          last = _.sortBy(usedColors).pop()
          "color#{if last? then last + 1 else 1}"
      )

  # When a given course is moved on planning, change its hour and date
  #
  # @param course [Object] moved course
  # @param day [String] new day for this course
  # @param hour [String] new hour for this course
  # @param minutes [String] new minutes for this course
  # @returns [Boolean] to complete the move in planning directive
  onDanceClassMoved: (course, day, hour, minutes) =>
    duration = course.duration
    # change start date, and updates the end by setting duration
    course.start = "#{day} #{hour}:#{minutes}#{if minutes is 0 then '0' else ''}"
    course.duration = duration
    console.log "Moved course", course, "to #{day} #{hour}:#{minutes}"
    @onSaveCourse course
    true

  # Create a new (unsaved) course for that season
  #
  # @param day [String] selected day, ie. Tue
  # @param hour [String] selected hour and minutes, ie. 15:30
  onCreateCourse: (day, hour) =>
    created = new DanceClass
      season: @currentSeason
      start: "#{day} #{hour}"
      hall: @halls[0]
    created.duration = 60
    @onSelectCourse created

  # Save a given course to persist changes
  #
  # @param course [Object] saved course
  onSaveCourse: (course) =>
    return unless course?
    course.save () =>
      return console.error err if err?
      console.log "Course saved", course
      # reload the full season for newly created courses
      @onSelectSeason @currentSeason

  # Restore the given course to its previous values
  #
  # @param course [Object] selected dance class
  onRestoreCourse: (course) =>
    course.restore() if course?

  # Show modal confirmation, then remove that course.
  # Refresh planning after deletion, and reset edited course if applicable
  #
  # @param course [Object] removed course
  onRemoveCourse: (course) =>
    return unless course?
    doRemove = =>
      # remove that course
      course.remove (err) =>
        return console.error err if err?
        @editedCourse = null if course is @editedCourse
        # reset planning
        @onSelectSeason @currentSeason

    # get the number of registrations
    course.getDancers (err, dancers = []) =>
      if 0 is dancers.length
        # removes immediately if there's no dancers
        doRemove()
      else
        @dialog.messageBox(i18n.ttl.confirm, @filter('i18n')('msg.removeDanceClass', args: {
            course...
            dancers: dancers.length
            start: @formatCourseStart course
          }) , [
            {label: i18n.btn.no, cssClass: 'btn-warning'}
            {label: i18n.btn.yes, result: true}
          ]
        ).result.then (confirmed) => doRemove() if confirmed

  # Detect changes on the edited course
  #
  # @returns [Boolean] true if there's an edited course, and it has pending changes
  hasEditedCourseChanged: =>
    return false unless @editedCourse
    not _.isEqual @editedCourse.toJSON(), @editedCourse._raw

  # Format course start hour for friendly users :)
  #
  # @param course [Object] the formated course
  # @return [String] the formated start day and time
  formatCourseStart: (course) =>
    return unless course
    {day, hour, minutes} = extractDateDetails course.start
    "#{i18n.lbl[day]} #{hour}h#{if minutes > 0 then minutes else '00'}"

  # According to the selected theme, rebuild styles and apply them.
  # New theme is saved into configuration, and button is temporary disabled while compiling
  #
  # @param theme [Object] theme object, containing 'value' and 'label' attribues
  applyTheme: (theme) =>
    return if @_building
    @conf.theme = theme.value
    @conf.save()
    @_building = true
    buildStyles ['dancerm', 'print'], theme.value or 'none', (err, styles) =>
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
    return if @_dumpDialogDisplayed
    @_dumpDialogDisplayed = true
    dumpPath = dialog.showSaveDialog
      defaultPath: @conf.dumpPath
      title: @filter('i18n') 'ttl.chooseDumpLocation'
      filters: [name: @filter('i18n')('lbl.json'), extensions: ['json']]
    _.defer => @_dumpDialogDisplayed = false
    # dialog cancellation
    return @chooseDumpLocation() unless dumpPath?
    # retain entry for next loading, and refresh UI
    @conf.dumpPath = dumpPath
    @conf.save()

  # Display a file selection dialog to pick a dump file, that may be an xlsx or a 'json' file
  # Try to import contents (use dialog for progression) and resolve potential conflicts afterwise
  importDancers: =>
    filePath = dialog.showOpenDialog
      defaultPath: @conf.dumpPath
      title: @filter('i18n') 'ttl.chooseImportedFile'
      filters: [
        {name: @filter('i18n')('lbl.json'), extensions: ['json', 'dump']}
        {name: @filter('i18n')('lbl.xlsx'), extensions: ['xlsx']}
      ]
      properties: ['openFile']
    filePath = filePath and filePath[0]
    # dialog cancellation
    return unless filePath
    message = @dialog.messageBox @filter('i18n')('ttl.import'), @filter('i18n') 'msg.importing'

    msg = null
    displayEnd = (err) =>
      if err?
        console.error "got error", err
        msg = @filter('i18n') 'err.importFailed', args: err
      _.delay =>
        @rootScope.$apply =>
          message.close()
          @dialog.messageBox(@filter('i18n')('ttl.import'), msg, [label: @filter('i18n') 'btn.ok']).result.then =>
            # refresh all
            @rootScope.$broadcast 'model-imported'
      , 100

    @import.fromFile filePath, (err, models, report) =>
      return displayEnd err if err?
      console.info "importation report:", report
      msg = @filter('i18n') 'msg.importSuccess', args: report

      # get all existing dancers
      @import.merge models, (err, report, conflicts) =>
        return displayEnd err if err
        console.info "merge report:", report #, conflicts.map ({existing, imported}) =>
        #  "\n#{existing.constructor.name} (1. existing, 2. imported)\n#{JSON.stringify existing.toJSON()}\n#{JSON.stringify imported.toJSON()}"
        # resolve conflicts one by one
        return displayEnd() if conflicts.length is 0
        @dialog.modal(_.extend {
            size: 'lg'
            backdrop: 'static'
            keyboard: false
            resolve:
              conflicts: => conflicts
              byClass: => report.byClass
          }, ConflictsController.declaration
        ).result.then displayEnd