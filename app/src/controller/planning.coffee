_ = require 'lodash'
DanceClass = require '../model/dance_class'

module.exports = class PlanningController
              
  # Controller dependencies
  @$inject: ['$scope', '$rootScope', 'cardList']

  @declaration:
    controller: PlanningController
    controllerAs: 'ctrl'
    templateUrl: 'planning.html'

  # Link to Angular location provider
  location: null

  # Link to card list service
  cardList: null

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
  # @param scope [Object] Angular scope for this controller
  # @param rootScope [Object] Angular global scope, for digest triggering
  # @param cardList [CardListService] service responsible for card list
  constructor: (scope, @rootScope, @cardList) -> 
    @seasons = []
    @teachers = []

    scope.listCtrl.actions = []

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
