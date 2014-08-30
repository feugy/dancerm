_ = require 'underscore'
LayoutController = require './layout'
DanceClass = require '../model/danceclass'
Dancer = require '../model/dancer'

module.exports = class PlanningController extends LayoutController
              
  # Controller dependencies
  @$inject: ['$location', '$search'].concat LayoutController.$inject

  @declaration:
    controller: PlanningController
    controllerAs: 'ctrl'
    templateUrl: 'planning.html'
  
  # Link to Angular location provider
  location: null
  
  # List of known teachers
  teachers: []

  # List of available seasons
  seasons: []

  # currently displayed season
  currentSeason: null

  # List of dance classes currently displayed
  planning: []

  # Stores current search criteria
  search: {}

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param location [Object] Angular location service
  constructor: (@location, @search, parentArgs...) -> 
    super parentArgs...
    @seasons = []
    @teachers = []

    currentSeason = null
    planning = []
    @rootScope.$on 'model-initialized', init = =>
      DanceClass.listSeasons().then (seasons) =>
        @seasons = seasons
        unless @seasons.length is 0
          @currentSeason = @seasons[0]
          @showPlanning @currentSeason
        @rootScope.$digest()
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
        i = _.indexOf @search.danceClasses, danceClass
        if i isnt -1
          @search.danceClasses.splice i, 1
        else
          @search.danceClasses.push danceClass
    else
      # changes all dance classes
      @search.danceClasses = chosen
    # removes teachers because multiple classes may be held by different teachers
    @search.teachers = []
    # reset season to match corresponding
    @search.seasons = [@currentSeason]
    @rootScope.$emit 'search'

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
        i = _.indexOf @search.teachers, chosen
        if i isnt -1
          @search.teachers.splice i, 1
        else
          @search.teachers.push chosen
      else 
        # add or remove season
        i = _.indexOf @search.seasons, @currentSeason
        if i isnt -1
          @search.seasons.splice i, 1
        else
          @search.seasons.push @currentSeason
    else
      # changes all teachers or seasons
      if chosen?
        @search.teachers = [chosen]
      else
        @search.seasons = [@currentSeason]
        @search.teachers = []
    # removes danceClasses because they cannot belong to multiple plannings/teachers
    @search.danceClasses = []
    @rootScope.$emit 'search'

  # Invoked to display an empty dancer's screen
  createDancer: =>
    console.log "ask to display new dancer"
    @state.go 'list-and-card'

  # When a season is selected, shows its planning and updates the teacher list
  #
  # @param season [String] selected season
  showPlanning: (season) =>
    @currentSeason = season
    DanceClass.getPlanning(season).then (planning) =>
      @planning = planning
      @teachers = _.chain(planning).pluck('teacher').uniq().compact().value().sort()
      @rootScope.$digest()