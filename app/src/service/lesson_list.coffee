_ = require 'lodash'
{each} = require 'async'
i18n = require '../labels/common'
{currentSeason, makeInvoice} = require '../util/common'
SearchList = require './tools/search_list'
InvoiceItem = require '../model/invoice_item'

# Service responsible for searching for lessons, and keep the list between states.
# Triggers search.
module.exports = class LessonList extends SearchList

  # **static**
  # model class used
  @ModelClass: require '../model/lesson'

  # **static**
  # default sort
  @sort: 'date'

  # list of lessons that can be used for an invoice
  invoicable: []

  # teacher (in conf.teachers) used for invoicable lessons
  invoiceTeacher: null

  # initialise criteria
  constructor: (args...) ->
    @criteria =
      string: null
    @invoicable = []
    @invoiceTeacher = null
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
    unless conditions.date? or seed.length < 3
      conditions.$or = [
        {'dancer.firstname': new RegExp "^#{seed}", 'i'},
        {'dancer.lastname': new RegExp "^#{seed}", 'i'}
      ]
    conditions

  # Invoked when an invoice should be generated for the selected invoicable lessons
  # @param done [Function] completion callback, invoked with arguments:
  # @param done.err [Error] an error object, if the creation failed
  # @param done.invoice [Invoice] the generated invoice, or the existing one
  makeInvoice: (done) =>
    return unless @invoicable.length and @invoiceTeacher

    # get latest lesson, and use it to get the season
    @invoicable.sort (a, b) -> b.date.valueOf() - a.date.valueOf()
    season = currentSeason @invoicable[0].date
    # search for concerned dancer's card
    @invoicable[0].getDancer (err, dancer) =>
      err = new Error "lesson #{@invoicable[0].id} dancer can't be found" unless dancer? or err?
      return done new Error "failed to get lesson's concerned dancer: #{err.message}" if err?
      makeInvoice dancer, season, @conf.teachers.indexOf(@invoiceTeacher), (err, invoice) =>
        return done err, invoice if err?
        console.log "make new invoice for #{@invoiceTeacher.owner} and lessons #{@invoicable.map (l) -> l.id}"
        # group lessons by price
        prices = {}
        for lesson in @invoicable
          prices[lesson.price] = 0 unless lesson.price of prices
          prices[lesson.price]++
        # add one invoice item per different prices
        for price of prices
          invoice.items.push new InvoiceItem price: price, quantity: prices[price], name: i18n.lbl.invoiceItemLesson
        # mark lessons as invoiced
        each @invoicable, (lesson, next) ->
          lesson.invoiceId = invoice.id
          lesson.save next
        , (err) =>
          return done new Error "failed to update lessons: #{err}" if err
          console.log "lessons #{@invoicable.map (l) -> l.id} associated to invoice #{invoice.id}"
          @invoicable = []
          @invoiceTeacher = null
          invoice.save done

  # Invoked when some lessons are selected, to evaluate if invoice could be generated
  #
  # @params lessons [Array<Lessons>] selected lessons
  select: (lessons) =>
    @invoicable = []
    @invoiceTeacher = null
    return unless lessons.length > 0
    firstDancerId = lessons[0].dancerId
    firstTeacher = lessons[0].teacher
    # store lessons that can be invoiced if they all belongs to the same dancer from the same teacher
    unless lessons.find(({teacher}) => teacher isnt firstTeacher) or lessons.find(({dancerId}) -> dancerId isnt firstDancerId)
      @invoicable = lessons.concat()
      @invoiceTeacher = @conf.teachers.find ({owner}) => firstTeacher is owner