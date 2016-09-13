_ = require 'lodash'
{currentSeason, makeInvoice} = require '../util/common'
SearchList = require './tools/search_list'

# Service responsible for searching for lessons, and keep the list between states.
# Triggers search.
module.exports = class LessonList extends SearchList

  # **static**
  # Model class used
  @ModelClass: require '../model/lesson'

  # **static**
  # Default sort
  @sort: 'teacher'

  # List of lessons that can be used for an invoice
  invoicable = []

  # Initialise criteria
  constructor: (args...) ->
    @criteria =
      string: null
    @invoicable = []
    super args...

  # **private**
  # Parse criteria to search options
  # @returns [Object] option for findWhere method.
  _parseCriteria: =>
    conditions = {}
    # depending on criterias
    seed = @criteria.string or ''
    # find by month
    match = seed.match /^(\d{2})/
    conditions.date = new RegExp "^\\d{4}-#{match[1]}" if match?
    # or find by year
    match = seed.match /^(\d{4})/
    conditions.date = new RegExp "^#{match[1]}" if match?
    # or find by month and year
    match = seed.match /^(\d{4})[/\-\.](\d{2})/
    conditions.date = new RegExp "^#{match[1]}-#{match[2]}" if match?
    # or find by dancer
    conditions['dancer.name'] = new RegExp seed, 'i' unless conditions.date? or seed.length <= 3
    conditions

  # Invoked when an invoice should be generated for the selected invoicable lessons, and a particular school
  #
  # @params schoolIdx [Number] index of the select school for which the invoice will be generated
  # @param done [Function] completion callback, invoked with arguments:
  # @param done.err [Error] an error object, if the creation failed
  # @param done.invoice [Invoice] the generated invoice, or the existing one
  makeInvoice: (schoolIdx, done) =>
    return unless @invoicable.length
    console.log "make new invoice for #{schoolIdx} and lessons #{@invoicable.map (l) -> l.id}"
    # get latest lesson, and use it to get the season
    @invoicable.sort (a, b) -> b.date.valueOf() - a.date.valueOf()
    season = currentSeason @invoicable[0].date
    # search for concerned dancer's card
    @invoicable[0].getDancer (err, dancer) =>
      return new Error "failed to get lesson's concerned dancer: #{err.message}" if err?
      makeInvoice dancer, season, schoolIdx, (err, invoice) =>
        return done err, invoice if err?
        # TODO add lessons
        # TODO mark lessons as invoiced
        done null, invoice

  # Invoked when some lessons are selected, to evaluate if invoice coupld be generated
  #
  # @params lessons [Array<Lessons>] selected lessons
  select: (lessons) =>
    @invoicable = []
    return unless lessons.length > 0
    dancerId = lessons[0].dancerId
    # store lessons that can be invoiced if they all belongs to the same dancer
    @invoicable = lessons.concat() unless lessons.find (lesson) -> lesson.dancerId isnt dancerId