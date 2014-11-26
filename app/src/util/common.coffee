moment = require 'moment'
{join, resolve} = require 'path'
{appendFileSync} = require 'fs-extra'
_ = require 'lodash'
_str = require 'underscore.string'
_.mixin _str.exports()
_hexa = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

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

  ###fixConsole: ->
    # Log file
    originals = {}
    logFile = join gui.App.dataPath, 'log.txt'
    ['info', 'debug', 'error', 'log'].forEach (method) ->
      originals[method] = global.console[method]
      global.console[method] = (args...) ->
        appendFileSync logFile, "#{moment().format 'HH:mm:ss'} - #{method} - #{args.join ' '}\n"
        #(originals[method] or originals.debug)?.invoke console, args###

  # Used to dump errors into error file located in app data folder
  #
  # @param err [Error] the error to dump
  dumpError: (err) ->
    now = new Date()
    appendFileSync join(gui.App.dataPath, 'errors.txt'), """
------------
Received at #{now.getFullYear()}-#{now.getMonth()+1}-#{now.getDate()} #{now.getHours()}:#{now.getMinutes()}:#{now.getSeconds()}
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
    if process.env.NODE_ENV?.toLowerCase()?.trim() is 'test' or not gui?
      'dancerm-test'
    else
      'dancerm'

  # Return current season from date
  # Season changes at August, 1st.
  # @return current season string
  currentSeason: ->
    year = module.exports.currentSeasonYear()
    "#{year}/#{year+1}"

  # Return current season's first year from date
  # @return current season first year
  currentSeasonYear: ->
    now = moment()
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