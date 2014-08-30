moment = require 'moment'
{join, resolve} = require 'path'
_ = require 'underscore'
_str = require 'underscore.string'
_.mixin _str.exports()
_hexa = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']

# used to declare getter/setter within classes
# @see https://gist.github.com/reversepanda/5814547
Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

module.exports = 

  # Generate a random id containing 12 characters
  # @return a generated id
  generateId: ->
    (_hexa[Math.floor Math.random()*_hexa.length] for i in [0...12]).join ''

  # Return folder path that will stores database files
  #
  # @return absolute path to store database files
  getDbPath: ->
    isTest = process.env.NODE_ENV?.toLowerCase()?.trim() is 'test'
    resolve join __dirname, '..', '..', '..', 'data', "dancerm#{if isTest then '-test' else ''}"

  # Return current season from date
  # Searshon changes at August, 1st.
  # @return current season string
  currentSeason: ->
    now = moment()
    year = if now.month() >= 7 then now.year() else now.year()-1
    "#{year}/#{year+1}"

  # Get the attribute value of an object along a given path
  #
  # @param obj [Object] the root object
  # @param path [String] attribute pas, '.' are allowed.
  # @return the corresponding value, if available
  getAttr: (obj, path) ->
    path = path.split '.'
    obj = obj[path[0]]
    # avoid NPE
    return obj unless obj?
    # recurse or quit
    if path.length > 1
      module.exports.getAttr obj, path[1..].join '.'
    else
      obj