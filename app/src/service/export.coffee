_ = require 'underscore'
moment = require 'moment'
Dancer = require '../model/dancer/dancer'
Planning = require '../model/planning/planning'
fs = require 'fs'
path = require 'path'
xlsx = require 'xlsx.js'
   
# Export utility class.
# Allow exportation of dancers and planning into JSON plain files 
module.exports = class Export

  # Dump storage content into a plain JSON file, for further restore
  #
  # @param filePath [String] absolute or relative to the dump file
  # @param callback [Function] dump end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no problem occurred
  dump: (filePath, callback) =>
    return callback new Error "no file selected" unless filePath?
    filePath = path.resolve path.normalize filePath
    console.info "dump data in #{filePath}..."
    start = moment()
    stored =
      plannings: []
      dancers: []
    # gets plannings
    Planning.findAll (err, plannings) =>
      return callback new Error "Failed to dump plannings: #{err.toString()}" if err?
      stored.plannings = plannings
      # gets dancers
      Dancer.findAll (err, dancers) =>
        return callback new Error "Failed to dump dancers: #{err.toString()}" if err?
        stored.dancers = dancers
        # eventually, write into the file
        fs.writeFile filePath, JSON.stringify(stored), {encoding: 'utf8'}, (err) =>
          return callback err if err?
          duration = moment().diff start, 'seconds'
          console.info "data dumped in #{duration}s"
          callback null