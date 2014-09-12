_ = require 'underscore'
i18n = require '../labels/common'
{map} = require 'async'
LayoutController = require './layout'

# Displays statistics on a given list
module.exports = class StatsController extends LayoutController
      
  @$inject: ['$scope', '$list'].concat LayoutController.$inject

  # Route declaration
  @declaration:
    controller: StatsController
    controllerAs: 'ctrl'
    templateUrl: 'stats.html'

  # Current ancer list
  list: []

  # Current known by repartition
  knownBy: []

  # Options for known by statistics
  knownByOpt: 
    chart:
      type: 'pieChart'
      donut: true
      donutRatio: .35
      x: (d) -> d.label
      y: (d) -> d.value
      transitionDuration: 500
      labelType: 'percent'
      showLegend: false
      noData: i18n.lbl.loadingData

  # Controller constructor: bind methods and attributes to current scope
  constructor: (@scope, @list, @parentArgs...) -> 
    super parentArgs...

    @_computeKnowBy = _.debounce @_computeKnowBy, 100

    # use list results to compute stats
    @scope.$watch 'ctrl.list', @_computeKnowBy
    @_computeKnowBy()

  # **private**
  # Compute known by repartition
  _computeKnowBy: =>
    start = Date.now()
    values = {}
    total = 0
    ###map @list, (dancer, next) -> 
      dancer.getCard next
    , (err, cards) => ###
    Promise.all((dancer.card for dancer in @list)).then (cards) =>
      for card in cards
        for knownBy in card.knownBy
          if knownBy of values
            values[knownBy]++
          else
            values[knownBy] = 1
          total++
      console.log "total known by/dancers: #{total}/#{@list.length}"
      @knownBy = _.sortBy((for name, count of values
        if name of i18n.knownByMeanings
          name = i18n.knownByMeanings[name]
        label: name, value: count 
      ), 'value').reverse()

      console.log ">> compute knownBy in", Date.now() - start, "ms"
      @rootScope.$apply()