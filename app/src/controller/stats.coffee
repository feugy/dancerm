_ = require 'lodash'
i18n = require '../labels/common'
{currentSeasonYear} = require '../util/common'
{map} = require 'async'
DanceClass = require '../model/dance_class'
tinycolor = window.tinycolor

animDuration = 500

# Displays statistics on a given list
module.exports = class StatsController

  # Controller dependencies
  @$inject: ['$scope', 'cardList', '$state']

  # Route declaration
  @declaration:
    controller: StatsController
    controllerAs: 'ctrl'
    templateUrl: 'stats.html'

  # Controller's own scope, for event listening
  scope: null

  # Link to card list service
  cardList: null

  # missing certificates
  missingCertificates: null

  # total due amount
  due: null

  # Current known by repartition
  knownBy: []

  # options for known by statistics
  knownByOpt:
    chart:
      type: 'pieChart'
      donut: true
      x: (d) -> d.label
      y: (d) -> d.count
      color: (d) -> "##{d.color}"
      showLabels: false
      showLegend: false
      tooltip:
        enabled: true
        contentGenerator: (d) ->
          return unless d?
          """<div class='tooltip-inner'>
            <span class='highlight' style='background-color: #{d.color}'></span>
            #{d.data.label}: <strong>#{d.data.count}</strong>
          </div>"""
      pie:
        startAngle: (d) -> d.startAngle/2 -Math.PI/2
        endAngle: (d) -> d.endAngle/2 -Math.PI/2
      transitionDuration: animDuration
      height: 250
      noData: i18n.lbl.noResults
      margin:
        top: 0
        bottom: -225
        left: 0
        right: 0

  # classes distributions
  danceClasses: []

  # options for dance classes distribution
  danceClassesOpt:
    chart:
      type: 'multiBarHorizontalChart'
      stacked: true
      x: (d) -> d.label
      y: (d) -> d.count
      showControls: false
      showLegend: false
      showYAxis: false
      tooltip:
        enabled: true
        contentGenerator: (d) ->
          return unless d?
          """<div class='tooltip-inner'>
            <span class='highlight' style='background-color: #{d.color}'></span>
            #{d.data.label}<br/>#{d.series[0].key}: <strong>#{d.data.count}</strong>
          </div>"""
      transitionDuration: animDuration
      height: 300
      noData: i18n.lbl.noResults
      margin:
        top: 0
        bottom: 0
        left: 100
        right: 0

  # available seasons
  seasons: []

  # available teachers for this season
  teachers: []

  # contextual actions, an array of objects containing properties:
  # - label [String] displayed label with i18n filter
  # - action [Function] function invoked (without argument) when clicked
  # modified by main view's controller
  contextActions: []

  # search and computation in progress
  workInProgress: false

  # On loading, search for current season
  #
  # @param scope [Object] controller's own scope, for event listening
  # @param cardList [Object] card list service
  # @param state [Object] Angular state provider
  constructor: (@scope, @cardList, state) ->
    @seasons = ("#{year}/#{year+1}" for year in [currentSeasonYear()..2006])
    # reset text search and dance classes selection
    @cardList.criteria.seasons = [@seasons[0]]
    @cardList.criteria.string = null
    @cardList.criteria.danceClasses = []
    # bind listeners on search events
    @cardList.on 'search-start', @_onSearch
    @cardList.on 'search-end', @_onSearchResults

    # trigger search, now if not already pending
    if @cardList.isSearching()
      @cardList.once 'search-end', => @cardList.performSearch true
    else
      @cardList.performSearch true

    @scope.$on 'destroy', =>
      @cardList.removeListener 'search-start', @_onSearch
      @cardList.removeListener 'search-end', @_onSearchResults

    @contextActions = [
      {label: 'btn.backToPlanning', icon: 'arrow-left', action: -> state.go 'list.planning'}
    ]

  # On season selection, updates teacher list (with all possible teachers of selected seasons)
  # and trigger search.
  # Use ctrl key to toggle season in the current searched list
  #
  # @param event [Event] click optionnal event, to check ctrl key
  # @param season [String] selected season, null to select all possible seasons
  selectSeason: (event, season = null) =>
    if season is null
      # select all seasons
      @cardList.criteria.seasons = []
    else
      # with ctrl, toggle selected in list
      if event?.ctrlKey
        idx = @cardList.criteria.seasons.indexOf season
        if idx isnt -1
          @cardList.criteria.seasons.splice idx, 1
        else
          @cardList.criteria.seasons.push season
      else
        # on search this season
        @cardList.criteria.seasons = [season]

    # refresh teacher list with all possible teachers
    possibleSeasons = if @cardList.criteria.seasons.length is 0 then @seasons else @cardList.criteria.seasons
    map possibleSeasons, (season, next) ->
      DanceClass.getTeachers season, next
    , (err, teachersBySeason) =>
      return console.error err if err?
      @cardList.criteria.teachers = []
      @teachers = _.chain(teachersBySeason).flatten().uniq().value().sort()
      # and at least trigger search
      @cardList.performSearch true

  # On teacher selection, triggers search.
  # Use ctrl key to toggle teacher in the current searched list
  #
  # @param event [Event] click optionnal event, to check ctrl key
  # @param teacher [String] selected teacher, null to select all possible teachers
  selectTeacher: (event, teacher = null) =>
    if teacher is null
      # select all teachers
      @cardList.criteria.teachers = []
    else
      # with ctrl, toggle selected in list
      if event?.ctrlKey
        idx = @cardList.criteria.teachers.indexOf teacher
        if idx isnt -1
          @cardList.criteria.teachers.splice idx, 1
        else
          @cardList.criteria.teachers.push teacher
      else
        # on search this teacher
        @cardList.criteria.teachers = [teacher]

    # and at least trigger search
    @cardList.performSearch true

  # **private**
  # Extends to init the work in progress flag
  _onSearch: =>
    @workInProgress = true
    # because sometime tooltip remains...
    $('.nvtooltip').remove()

  # **private**
  # Computes known by stats right after displaying the new list
  _onSearchResults: (args...) =>
    start = Date.now()
    knownBy =
      values: {}
      total: 0
    classes = {}
    kinds = []
    @missingCertificates = 0
    @due = 0

    dismiss = =>
      @knownBy = []
      @danceClasses = []
      @workInProgress = false
      @scope.$apply()

    console.log "compute statistics..."
    map @cardList.list, (dancer, next) ->
      dancer.getCard next
    , (err, cards) =>
      if err?
        dismiss()
        return console.error err
      map @cardList.list, (dancer, next) ->
        dancer.getClasses next
      , (err, danceClasses) =>
        if err?
          dismiss()
          return console.error err
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
          for reg in card.registrations when @cardList.criteria.seasons.length is 0 or reg?.season in @cardList.criteria.seasons
            # only for selected dancer
            @missingCertificates++ unless reg.certificates[@cardList.list[i].id]
            # add due if card was not already processed
            unless card.id in dueCards
              @due += reg.due()
              dueCards.push card.id

          # cast down dance classes
          for {kind, level, season} in danceClasses[i] when @cardList.criteria.seasons.length is 0 or season in @cardList.criteria.seasons
            classes[level] = {} unless level of classes
            kinds.push kind unless kind in kinds
            classes[level][kind] = 0 unless kind of classes[level]
            classes[level][kind]++

        num = 0
        @danceClasses = (for level, details of classes
          {
            key: level
            color: i18n.colors[(num++)%i18n.colors.length]
            values: (label: kind, count: details[kind] or 0 for kind in kinds)
          }
        )

        @knownBy = _.sortBy((for name, count of knownBy.values
          if name of i18n.knownByMeanings
            name = i18n.knownByMeanings[name]
          label: name, count: count
        ), 'count').reverse()

        # add colors
        @knownBy = (for knownBy, i in @knownBy
          knownBy.color = tinycolor(i18n.colors[i%i18n.colors.length]).toHex()
          knownBy.highlight = tinycolor(knownBy.color).darken(10).toString()
          knownBy
        )

        console.log "statistics computed in #{Date.now()-start} ms"
        @workInProgress = false
        setTimeout () =>
          @scope.$apply()
        , 0