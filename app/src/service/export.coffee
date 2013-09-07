_ = require 'underscore'
moment = require 'moment'
fs = require 'fs'
path = require 'path'
xlsx = require 'xlsx.js'
Dancer = require '../model/dancer/dancer'
Planning = require '../model/planning/planning'
i18n = require '../labels/common'
{getAttr} = require '../util/common'
   
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

  # Exports a dancer list to an XlsX file
  #
  # @param filePath [String] absolute or relative path to the written file
  # @param dancers [Array<Dancer>] the list of exported dancers: 
  # @param callback [Function] extraction end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no problem occurred
  toFile: (filePath, dancers, callback) =>
    return callback new Error "no file selected" unless filePath?
    filePath = path.resolve path.normalize filePath

    data = []
    content =
      creator: i18n.ttl.application,
      lastModifiedBy: i18n.ttl.application,
      worksheets : [
        data: data
        name: i18n.ttl.application
      ]

    columns = 
      title: i18n.lbl.title
      firstname: i18n.lbl.firstname
      lastname: i18n.lbl.lastname
      'address.street': i18n.lbl.address
      'address.city': i18n.lbl.city
      'address.zipcode': i18n.lbl.zipcode
      phone: i18n.lbl.phone
      cellphone: i18n.lbl.cellphone
      birth: i18n.lbl.birth
      email: i18n.lbl.email
      knownBy: i18n.lbl.knownBy

    borderV = 'e7d8b1'
    borderH = '403b3f'

    # header line
    data.push (
      first = true
      for attr, column of columns
        cell = 
          value: column
          bold: true
          hAlign: 'center'
        if first
          first = false
        else
          cell.borders = left: borderV
        cell
    )

    # dancers
    for dancer in dancers
      data.push (
        first = true
        for attr of columns
          cell = 
            value: getAttr dancer, attr
            autoWidth: true
            hAlign: 'left'
            borders:
              top: borderH
          if cell.value?
            switch attr
              # format dates
              when 'birth' then cell.value = cell.value.format 'DD/MM/YYYY'
              # format phones
              when 'phone', 'cellphone' then cell.value = _.chop(cell.value, 2).join ' '
              # format known by
              when 'knownBy' then cell.value = (i18n.knownByMeanings[key] or key for key in cell.value).join ','
          if first
            first = false
          else
            cell.borders.left = borderV
          cell
      )

    # write file in base64
    fs.writeFile filePath, xlsx(content).base64, 'base64', callback