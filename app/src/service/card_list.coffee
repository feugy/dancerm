_ = require 'lodash'
windowManager = require('electron').remote.require 'electron-window-manager'
SearchList = require './tools/search_list'

# Service responsible for searching for cards, and keep the list between states.
# Triggers search.
module.exports = class CardList extends SearchList

  # **static**
  # Model class used
  @ModelClass: require '../model/dancer'

  # **static**
  # Default sort
  @sort: 'lastname'

  # **private**
  # Call list print preview window
  _preview: null

  # Initialise criteria
  constructor: (args...) ->
    @_preview = null
    @criteria =
      string: null
      teachers: []
      seasons: []
      danceClasses: []
    super args...

  # @return true if the current list concerned a dance class
  canPrintCallList: =>
    not @criteria.string and @criteria.danceClasses.length is 1

  # Print call list from the current day
  #
  # @param danceClass [DanceClass] danceClass concerned
  printCallList: =>
    return @_preview.focus() if @_preview?

    windowManager.sharedData.set 'styles', global.styles.print
    windowManager.sharedData.set 'list', @list
    windowManager.sharedData.set 'danceClass', @criteria.danceClasses[0]

    # open hidden print window
    @_preview = windowManager.createNew 'call_list', window.document.title, null, 'print'
    @_preview.open '/call_list_print.html', true
    @_preview.focus()

    @_preview.object.on 'closed', =>
      # dereference the window object, to destroy it
      @_preview = null

  # Displays addresses printing window
  printAddresses: =>
    return @_preview.focus() if @_preview?
    return unless @list?.length > 0

    windowManager.sharedData.set 'styles', global.styles.print
    windowManager.sharedData.set 'list', @list

    # open hidden print window
    @_preview = windowManager.createNew 'addresses', window.document.title, null, 'print'
    @_preview.open '/addresses_print.html', true
    @_preview.focus()

    @_preview.object.on 'closed', =>
      # dereference the window object, to destroy it
      @_preview = null

  # **private**
  # Parse criteria to search options
  # @returns [Object] option for findWhere method.
  _parseCriteria: =>
    # always get newest value of payer prefix
    @_payerPrefix = new RegExp "^\s*#{@conf.payerPrefix}\s*:", 'i'

    conditions = {}
    # depending on criterias
    seed = @criteria.string
    if seed?.length >= 3
      if seed.match @_payerPrefix
        # find by payer
        conditions['card.registrations.payments.payer'] = new RegExp seed.replace(@_payerPrefix, '').trim(), 'i'
      else
        # find all dancers by first name/last name
        conditions.$or = [
          {firstname: new RegExp "^#{seed}", 'i'},
          {lastname: new RegExp "^#{seed}", 'i'}
        ]

    # find all dancers by season and optionnaly by teacher for this season
    if @criteria.seasons?.length > 0
      conditions['danceClasses.season'] = $in: @criteria.seasons

    if @criteria.danceClasses?.length > 0
      # select class students: can be combined with season and name
      conditions['danceClassIds'] = $in: _.map @criteria.danceClasses, 'id'
    else if @criteria.teachers?.length > 0
      # add teacher if needed: can be combined with season and name
      conditions['danceClasses.teacher'] = $in: @criteria.teachers
    conditions