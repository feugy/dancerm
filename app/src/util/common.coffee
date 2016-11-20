_ = require 'lodash'
moment = require 'moment'
{join, resolve} = require 'path'
{appendFile, appendFileSync, readFile, existsSync} = require 'fs-extra'
{inspect} = require 'util'
{map} = require 'async'
{render} = require 'stylus'
# to avoid circular dependencies
Invoice = null
i18n = require '../labels/common'

_hexa = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

# Format a given value as a string.
# @param value [Any] - the value formated
# @returns [String] the formated equivalent
format = (value) ->
  if _.isArray value then value.map(format).join ', '
  else if _.isError value then value.stack
  else if _.isObject value then inspect value
  else value

# used to declare getter/setter within classes
# @see https://gist.github.com/reversepanda/5814547
Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

# Extract first step of path to a given sub-object, supporting array notation
#
# @param obj [Object] the root object
# @param path [String] attribute pas, '.' are allowed.
# @return an object containing obj (the immediate parent) and prop (the property accessed), and the splited path array
# obj may be null, indicating a missing step
getFirstStep = (obj, path) ->
  path = path.split '.'
  # do we used array notation ?
  rank = path[0].match /(.*)\[(\d+)\]$/
  if rank?
    # prefix used
    obj = obj[rank[1]] if rank[1]
    # get with array notation
    obj: obj, prop: rank[2], path: path
  else
    # get with object notation
    obj: obj, prop: path[0], path: path

module.exports =

  # Regexp used to validate invoice references
  invoiceRefFormat: /^\D*(\d{4})\D*(\d{2})\D*(\d+).*$/
  invoiceRefExtract: /^\D*(\d{4})\D*(\d{2})?\D*(\d+)?$/

  # Replace global console functions to ouput in a file.
  #
  # @param path [String] path to log file
  fixConsole: (path = 'log.txt') ->
    # Log file
    logFile = resolve path
    console.log "log to file #{logFile}"
    ['info', 'debug', 'warn', 'error', 'log'].forEach (method) ->
      global.console[method] = (args...) ->
        appendFile logFile, "#{moment().format 'DD/MM/YYYY HH:mm:ss'} - #{method} - #{args.map(format).join ' '}\n"

  # Working instanceof operator. No inheritance, no custom types
  #
  # @param obj [Object] the tested object
  # @param type [String] the expected type
  # @return true if obj is an instance of the expected type
  isA: (obj, type) ->
    clazz = Object::toString.call(obj).slice 8, -1
    obj isnt undefined and obj isnt null and clazz.toLowerCase() is type.toLowerCase()

  # Used to dump errors into error file located in app data folder
  # Generates an event handler that expect a single error parameter
  #
  # @param path [String] path to log file
  dumpError: (path = 'log.txt') -> (err) ->
    now = new Date()
    appendFileSync resolve(path), """
------------
Received at #{moment().format 'DD/MM/YYYY HH:mm:ss'}
#{err.message}
#{err.stack}\n\n"""
    process.exit 0

  # Generate a random id containing 12 characters
  # @return a generated id
  generateId: ->
    (_hexa[Math.floor Math.random()*_hexa.length] for i in [0...12]).join ''

  # Return folder path that will stores database files
  #
  # @return absolute path to store database files
  getDbPath: ->
    if process.env.NODE_ENV?.toLowerCase()?.trim() is 'test' or not nw?
      'dancerm-test'
    else
      'dancerm'

  # Return current season from date
  # Season changes at August, 1st.
  # @params now [Moment] date of which season year is computed. Default to today.
  # @return current season string
  currentSeason: (now = moment()) ->
    year = module.exports.currentSeasonYear now
    "#{year}/#{year+1}"

  # Return current season's first year from date
  # @params now [Moment] date of which season year is computed. Default to today.
  # @return current season first year
  currentSeasonYear: (now = moment()) ->
    if now.month() >= 7 then now.year() else now.year()-1

  # Get the attribute value of an object along a given path
  #
  # @param obj [Object] the root object
  # @param path [String] attribute pas, '.' are allowed.
  # @return the corresponding value, if available
  getAttr: (obj, path) ->
    {obj, prop, path} = getFirstStep obj, path
    # avoid NPE
    return obj unless obj?[prop]?
    obj = obj[prop]
    # recurse or quit
    if path.length > 1
      module.exports.getAttr obj, path[1..].join '.'
    else
      obj

  # Set the attribute value of an object along a given path.
  # Does not creates the missing sub object and throws exception
  #
  # @param obj [Object] the root object
  # @param path [String] attribute pas, '.' are allowed.
  # @param value [Any] the new value
  setAttr: (obj, path, value) ->
    {obj, prop, path} = getFirstStep obj, path
    # avoid NPE
    throw new Error "No element at #{prop} in #{path.join '.'}" if not(obj?) or not(obj[prop]?) and path.length > 1
    # recurse or quit
    if path.length > 1
      module.exports.setAttr obj[prop], path[1..].join('.'), value
    else
      obj[prop] = value

  # Dynamically builds stylus style sheets, using a given theme
  #
  # @param files [Array<String> files names (without extentions), relative to src/style folder, to compile
  # @param theme [String] optionnal name of the theme file (in src/style/themes/ folder) used for compilation
  # @param done [Function] completion callback, invoked with parameters:
  # @option done err [Error] an error object, or null if no compilation error occured
  # @option done results [Object] an associative array containing for each file (as key) the corresponding css
  buildStyles: (files, theme, done) ->
    map files, (sheet, next) ->
      folder = join '.', 'app', 'src', 'style'
      readFile join(folder, "#{sheet}.styl"), 'utf8', (err, content) ->
        return next err if err?
        # adds themes variable if it exists
        content = "@require 'themes/#{theme}_variable'\n#{content}" if existsSync join folder, 'themes', "#{theme}_variable.styl"
        # adds theme override if it exists
        content += "\n@require 'themes/#{theme}'" if existsSync join folder, 'themes', "#{theme}.styl"
        # now add variables and compiles
        render "@require 'variable'\n#{content}",
          filename: "#{sheet}.css"
          paths: ['./app/src/style']
        , next
    , (err, sheets) ->
      return done err if err?
      result = {}
      result[name] = sheets[i] for name, i in files
      done null, result

  # Get 50 colors from css classes color1, color2... defined by theme.
  # Css must be fully loaded
  # Directly updates the i18n.colors array.
  getColorsFromTheme: ->
    # get also theme colors for JS usage in directives
    container = angular.element('<div style="display:none;"/>').appendTo 'body'
    i18n.colors = _.filter (for i in [1..50]
      pipette = angular.element("<div class='pipette color#{i}'/>").appendTo container
      pipette.css('backgroundColor')
    ), (color) => color isnt 'rgba(255, 0, 255, 0)'
    container.remove()

  # Make an invoice for a given dancer (cardId is used for retrieval), season and teacher.
  # Only one unsent invoice is allowed for a given combination of those elements: if it
  # already exists, an error is raised, but the existing invoice is also returned
  #
  # @param dancers [Array<Dancer>] the concerned dancers
  # @param date [Moment] invoice's date
  # @param season [Number] first year of the concerned season
  # @param teacher [Number] index of the concerned teacher in conf.teachers array.
  # @param done [Function] completion callback, invoked with arguments:
  # @param done.err [Error] an error object, if the creation failed
  # @param done.invoice [Invoice] the generated invoice, or the existing one
  makeInvoice: (dancers, date, season, teacher, done) ->
    Invoice = require '../model/invoice' unless Invoice?
    # search for unsent invoices related to that card
    Invoice.findWhere {cardId: dancers[0].cardId, season: season, selectedTeacher: teacher, sent: null}, (err, existing) =>
      return done new Error "failed to search for invoices: #{err.message}" if err?
      # if an unsent invoice already exist, raise an error, but also return the first (and only) invoice
      return done new Error("unsent invoice already exist for card #{dancers[0].cardId}, season #{season} and teacher #{teacher}"), existing[0] if existing.length
      # or create a new one with the first dancer as customer
      firstYear = parseInt season
      invoice = new Invoice
        cardId: dancers[0].cardId
        season: season
        selectedTeacher: teacher
      invoice.changeDate date
      # generate reference
      Invoice.getNextRef date.year(), date.month() + 1, teacher, (err, ref) =>
        return done new Error "failed to get next ref for new invoice #{err.message}" if err?
        invoice.ref = ref
        invoice.setCustomers dancers, =>
          invoice.save (err) =>
            return done new Error "failed to save new invoice #{invoice.toJSON()}: #{err.message}" if err?
            done null, invoice

  # Round a number to the upper half euro:
  # 5.0 -> 5.0
  # 5.15 -> 5.5
  # 5.5 -> 5.5
  # 5.51 -> 6.0
  # 5.6 -> 6.0
  #
  # @param num [Number] number to round
  # @returns [Number] rounded value
  roundEuro: (num) ->
    floor = Math.floor num
    cents = Math.floor(100 * num) % 100
    if cents is 0 then floor else if cents <= 50 then floor + .5 else floor + 1