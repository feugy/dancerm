_ = require 'lodash'
SearchList = require './tools/search_list'

# Service responsible for keeping the card list between states
# Triggers search.
module.exports = class CardList extends SearchList

  # **static**
  # Model class used
  @ModelClass: require '../model/dancer'

  # **static**
  # Default sort
  @sort: 'lastname'

  # Initialise criteria
  constructor: (args...) ->
    @criteria =
      string: null
      teachers: []
      seasons: []
      danceClasses: []
    super args...

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