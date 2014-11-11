_ = require 'lodash'
i18n = require '../labels/common'
{currentSeasonYear} = require '../util/common'
{map} = require 'async'
ListController = require './list'
DanceClass = require '../model/danceclass'
tinycolor = window.tinycolor

# Displays statistics on a given list
module.exports = class StatsController extends ListController
  
  # Route declaration
  @declaration:
    controller: StatsController
    controllerAs: 'ctrl'
    templateUrl: 'stats.html'

  # missing certificates
  missingCertificates: null

  # total due amount
  due: null

  # Current known by repartition
  knownBy: []

  # options for known by statistics
  knownByOpt: 
    percentageInnerCutout : 25
    animateScale: true
    animateRotate: true

  # classes distributions
  danceClasses: []

  # options for dance classes distribution
  danceClassesOpt: {}

  # available seasons
  seasons: []

  # available teachers for this season
  teachers: []

  # search and computation in progress
  workInProgress: false

  # On loading, search for current season 
  constructor:(parentArgs...) ->
    super parentArgs...
    @seasons = ("#{year}/#{year+1}" for year in [currentSeasonYear()..2006])
    @selectSeason null, @seasons[0]
    # reset text search and dance classes selection
    @search.string = null
    @search.danceClasses = []
    @allowEmpty = true

  # On season selection, updates teacher list (with all possible teachers of selected seasons)
  # and trigger search.
  # Use ctrl key to toggle season in the current searched list
  #
  # @param event [Event] click optionnal event, to check ctrl key
  # @param season [String] selected season, null to select all possible seasons
  selectSeason: (event, season = null) =>
    if season is null
      # select all seasons
      @search.seasons = []
    else
      # with ctrl, toggle selected in list
      if event?.ctrlKey
        idx = @search.seasons.indexOf season
        if idx isnt -1
          @search.seasons.splice idx, 1
        else
          @search.seasons.push season
      else
        # on search this season
        @search.seasons = [season]

    # refresh teacher list with all possible teachers
    possibleSeasons = if @search.seasons.length is 0 then @seasons else @search.seasons
    Promise.all((DanceClass.getTeachers season for season in possibleSeasons)).then (teachersBySeason) =>
      @search.teachers = []
      @teachers = _.chain(teachersBySeason).flatten().uniq().value().sort()
      # and at least trigger search
      @rootScope.$emit 'search'


  # On teacher selection, triggers search.
  # Use ctrl key to toggle teacher in the current searched list
  #
  # @param event [Event] click optionnal event, to check ctrl key
  # @param teacher [String] selected teacher, null to select all possible teachers
  selectTeacher: (event, teacher = null) =>
    if teacher is null
      # select all teachers
      @search.teachers = []
    else
      # with ctrl, toggle selected in list
      if event?.ctrlKey
        idx = @search.teachers.indexOf teacher
        if idx isnt -1
          @search.teachers.splice idx, 1
        else
          @search.teachers.push teacher
      else
        # on search this teacher
        @search.teachers = [teacher]

    # and at least trigger search
    @rootScope.$emit 'search'

  # Extends to init the work in progress flag
  makeSearch: (args...) =>
    @workInProgress = true
    super args...

  # **private**
  # Computes known by stats right after displaying the new list
  _displayResults: (args...) =>
    super args...
    @_computeStats()

  # **private**
  # Compute stats in a single pass
  _computeStats: =>
    start = Date.now()
    knownBy =
      values: {}
      total: 0
    classes = {}
    @missingCertificates = 0
    @due = 0

    dismiss = =>
      @knownBy = []
      @danceClasses = []
      @workInProgress = false
      @rootScope.$apply()

    console.log "compute statistics..."
    Promise.all((dancer.card for dancer in @list)).then((cards) =>
      Promise.all((dancer.danceClasses for dancer in @list)).then (danceClasses) =>
        dueCards = []
        for card, i in cards
          # cast down known by
          for value in card.knownBy
            if value of knownBy.values
              knownBy.values[value]++
            else
              knownBy.values[value] = 1
            knownBy.total++
          # get missing certificates and due for selected seasons
          for reg in card.registrations when @search.seasons.length is 0 or reg?.season in @search.seasons
            # only for selected dancer
            @missingCertificates++ unless reg.certificates[@list[i].id]
            # add due if card was not already processed
            unless card.id in dueCards
              @due += reg.due()
              dueCards.push card.id 

          # cast down dance classes
          for {kind, level, season} in danceClasses[i] when @search.seasons.length is 0 or season in @search.seasons
            classes[kind] = {} unless kind of classes
            classes[kind][level] = 0 unless level of classes[kind]
            classes[kind][level]++

        kinds = _.keys classes 
        num = 0
        @danceClasses = 
          labels: kinds
          datasets: _.flatten (for kind, details of classes
            idx = kinds.indexOf kind
            (for level, count of details
              previous = (0 for i in [0...idx])
              next = (0 for i in [idx+1...kinds.length])
              color = i18n.colors[(num++)%i18n.colors.length]
              {
                label: level
                data: previous.concat [count], next
                fillColor: "#{color}"
                highlightFill: tinycolor(color).darken(25).toString()
              }
            ) 
          )

        @knownBy = _.sortBy((for name, count of knownBy.values
          if name of i18n.knownByMeanings
            name = i18n.knownByMeanings[name]
          label: name, value: count
        ), 'value').reverse()

        # add colors
        @knownBy = (for knownBy, i in @knownBy
          knownBy.color = i18n.colors[i%i18n.colors.length]
          knownBy.highlight = tinycolor(knownBy.color).darken(25).toString()
          knownBy
        )
        
        console.log "statistics computed in #{Date.now()-start} ms"
        @workInProgress = false
        @rootScope.$apply()
    ).catch (err) =>
      console.error err
      @dismiss()