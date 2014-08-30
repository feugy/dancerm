_ = require 'underscore'
moment = require 'moment'
{Promise} = require 'es6-promise'
{each, eachSeries} = require 'async'
{writeFile, truncate, readFile, appendFile, ensureFile} = require 'fs-extra'
{join, resolve, normalize} = require 'path'
xlsx = require 'xlsx.js'
Dancer = require '../model/dancer'
DanceClass = require '../model/danceclass'
Card = require '../model/card'
Address = require '../model/address'
i18n = require '../labels/common'
{getAttr, getDbPath} = require '../util/common'
   
# Export utility class.
# Allow exportation of dancers and planning into JSON plain files 
module.exports = class Export

  # Separator used into dump files
  @separator: '------MODELS------'

  # Dump storage content into a plain JSON file, for further restore
  #
  # @param filePath [String] absolute or relative to the dump file
  # @return a promise without any resolve parameter
  dump: (filePath) =>
    new Promise (accept, reject) =>
      return reject new Error "no file selected" unless filePath?
      start = moment()
      filePath = resolve normalize filePath
      console.info "dump data in #{filePath}..."
      start = moment()

      classes = [Address, Card, Dancer, DanceClass]
      ### TODO buggy on windows
      # compact each single database
      Promise.all((clazz._collection() for clazz in classes)).then((collections) =>
        each collections, (collection, next) =>
          collection.persistence.persistCachedDatabase (err) =>
            return next new Error "failed to compact data for collection #{collection.filename}: #{err}" if err?
            console.log "#{collection.filename} compacted..."
            next()
        , (err) =>
          return reject err if err###
      # into a temporary file
      dbPath = getDbPath()
      ensureFile filePath, (err) =>
        return reject err if err?
        # read each file and writes it into
        writeFile filePath, "", (err) =>
          return reject err if err?
          console.log "reinit file..."
          eachSeries ([clazz, join dbPath, clazz.name] for clazz in classes), ([clazz, file], next) =>
            readFile file, {encoding: "utf8"}, (err, content) =>
              return next new Error "failed to read #{clazz.name} file: #{err}" if err?
              console.log "#{clazz.name} model read..."
              appendFile filePath, "#{@constructor.separator}#{clazz.name}\n#{content}", {encoding: 'utf8'}, (err) =>
                return next new Error "failed to write #{clazz.name} data: #{err}" if err?
                console.log "#{clazz.name} model written..."
                next()
          , (err) =>
            return reject err if err?
            # rename dump to destination file
            console.info "dump finished in #{moment().diff start}ms !"
            accept()
      #).catch reject

  # Exports a dancer list to an XlsX file
  #
  # @param filePath [String] absolute or relative path to the written file
  # @param dancers [Array<Dancer>] the list of exported dancers: 
  # @param callback [Function] extraction end callback, invoked with arguments:
  # @option callback err [Error] an Error object, or null if no problem occurred
  toFile: (filePath, dancers, callback) =>
    return callback new Error "to be refined"
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