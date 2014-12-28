_ = require 'lodash'
DanceClass = require '../model/dance_class'
ConflictsController = require './conflicts'

module.exports = class PlanningController
              
  # Controller dependencies
  @$inject: ['$rootScope', 'cardList', 'dialog', 'import', '$location', '$state', '$filter']

  @declaration:
    controller: PlanningController
    controllerAs: 'ctrl'
    templateUrl: 'planning.html'
  
  # Global scope, for digest triggering
  rootScope: null

  # Link to Angular location provider
  location: null

  # Link to card list service
  cardList: null

  # Link to Angular state provider
  state: null

  # Link to Angular dialog service
  dialog: null

  # Link to dancer import service
  import: null

  # Angular filters factory
  filter: null
  
  # List of known teachers
  teachers: []

  # List of available seasons
  seasons: []

  # currently displayed season
  currentSeason: null

  # List of dance classes currently displayed
  planning: []

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param rootScope [Object] Angular global scope, for digest triggering
  # @param cardList [CardListService] service responsible for card list
  # @param dialog [Object] Angular dialog service
  # @param import [import] Import service
  # @param location [Object] Angular location service
  # @param state [Object] Angular state provider
  # @param filter [Function] Angular's filter factory
  constructor: (@rootScope, @cardList, @dialog, @import, @location, @state, @filter) -> 
    @seasons = []
    @teachers = []

    currentSeason = null
    @planning = []
    @rootScope.$on 'model-initialized', init = =>
      DanceClass.listSeasons (err, seasons) =>
        return console.error err if err?
        @seasons = seasons
        unless @seasons.length is 0
          @currentSeason = @seasons[0]
          @loadPlanning @currentSeason
        @rootScope.$apply()
    @rootScope.$on 'model-imported', init
    init()

  # Invoked when clicking on a given dance class.
  # displays dancers registered into this class
  #
  # @param event [Event] click event, to check pressed keys
  # @param chosen [Array<DanceClass>] the clicked dance(s) class
  searchByClass: (event, chosen) =>
    console.log "search by class #{chosen}, #{@currentSeason}"
    if event?.ctrlKey
      for danceClass in chosen
        # add or remove
        i = _.indexOf @cardList.criteria.danceClasses, danceClass
        if i isnt -1
          @cardList.criteria.danceClasses.splice i, 1
        else
          @cardList.criteria.danceClasses.push danceClass
    else
      # changes all dance classes
      @cardList.criteria.danceClasses = chosen
    # removes teachers because multiple classes may be held by different teachers
    @cardList.criteria.teachers = []
    # reset season to match corresponding
    @cardList.criteria.seasons = [@currentSeason]
    @cardList.performSearch()

  # Invoked when clicking on a given teacher name.
  # displays dancers registered for this teatcher on current year
  #
  # @param event [Event] click event, to check pressed keys
  # @param chosen [String] the clicked teacher, may be empty
  searchByTeacher: (event, chosen = null) =>
    console.log "search by teacher #{chosen}, #{@currentSeason}"
    if event?.ctrlKey
      if chosen?
        # add or remove teacher
        i = _.indexOf @cardList.criteria.teachers, chosen
        if i isnt -1
          @cardList.criteria.teachers.splice i, 1
        else
          @cardList.criteria.teachers.push chosen
      else 
        # add or remove season
        i = _.indexOf @cardList.criteria.seasons, @currentSeason
        if i isnt -1
          @cardList.criteria.seasons.splice i, 1
        else
          @cardList.criteria.seasons.push @currentSeason
    else
      # changes all teachers or seasons
      if chosen?
        @cardList.criteria.teachers = [chosen]
      else
        @cardList.criteria.seasons = [@currentSeason]
        @cardList.criteria.teachers = []
    # removes danceClasses because they cannot belong to multiple plannings/teachers
    @cardList.criteria.danceClasses = []
    @cardList.performSearch()

  # Invoked to display an empty dancer's screen
  createCard: =>
    console.log "ask to display new dancer"
    @state.go 'list.card'

  # When a season is selected, shows its planning and updates the teacher list
  #
  # @param season [String] selected season
  loadPlanning: (season) =>
    @currentSeason = season
    DanceClass.getPlanning season, (err, planning) =>
      return console.error err if err?
      @planning = planning
      DanceClass.getTeachers season, (err, teachers) =>
        return console.error err if err?
        @teachers = teachers
        @rootScope.$apply()

  # Read a given xlsx file to import dancers.
  # Existing dancers (same firstname/lastname) are not modified
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
          @_resolveConflicts conflicts.then displayEnd

    dialog.trigger 'click'
    null

  # **private**
  # Resolve one conflict
  #
  # @param conflicts [Object] list of conflicts, with `existing` and `imported` properties
  # @return a promise with no resolve arguments
  _resolveConflicts: (conflicts) =>
    @dialog.modal(_.extend {
        size: 'lg'
        backdrop: 'static'
        keyboard: false
        resolve: conflicts: => conflicts
      }, ConflictsController.declaration
    ).result
