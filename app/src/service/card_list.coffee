_ = require 'lodash'
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
    nw.Window.open 'app/template/call_list_print.html',
      frame: true
      title: window.document.title
      icon: require('../../../package.json')?.window?.icon
      focus: true
      # size to A4 format, landscape
      width: 1000
      height: 800
      , (created) =>
        @_preview = created
        # set displayed list and wait for closure
        @_preview.list = @list
        @_preview.danceClass = @criteria.danceClasses[0]
        @_preview.on 'closed', => @_preview = null

  # Displays addresses printing window
  printAddresses: =>
    return @_preview.focus() if @_preview?
    return unless @list?.length > 0
    nw.Window.open 'app/template/addresses_print.html',
      frame: true
      title: window.document.title
      icon: require('../../../package.json')?.window?.icon
      focus: true
      # size to A4 format, 3/4 height
      width: 1000
      height: 800
      , (created) =>
        @_preview = created
        # set displayed list and wait for closure
        @_preview.list = @list
        @_preview.on 'closed', => @_preview = null

  # **private**
  # Parse criteria to search options
  # @returns [Object] option for findWhere method.
  _parseCriteria: =>
    conditions = {}
    # depending on criterias
    if @criteria.string?.length >= 3
      # find all dancers by first name/last name
      conditions.$or = [
        {firstname: new RegExp "^#{@criteria.string}", 'i'},
        {lastname: new RegExp "^#{@criteria.string}", 'i'}
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