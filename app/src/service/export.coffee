_ = require 'underscore'
moment = require 'moment'
{each, eachSeries} = require 'async'
{writeFile, writeFileSync, readFileSync, appendFileSync, ensureFileSync} = require 'fs-extra'
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
      try 
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

        # sincd node-webkit 0.10.5 and nedb, using sync fs API is less error-prone than classical async API
        ensureFileSync filePath
        writeFileSync filePath, ""
        console.log "reinit file..."
        for clazz in classes
          file = join dbPath, clazz.name
          content = readFileSync file, encoding: 'utf8'
          console.log "#{clazz.name} model read..."
          appendFileSync filePath, "#{@constructor.separator}#{clazz.name}\n#{content}", encoding: 'utf8'
          console.log "#{clazz.name} model written..."
        console.info "dump finished in #{moment().diff start}ms !"
        accept()
      catch err
        reject err

  # Exports a dancer list to an XlsX file
  #
  # @param filePath [String] absolute or relative path to the written file
  # @param dancers [Array<Dancer>] the list of exported dancers: 
  # @param callback [Function] extraction end callback, invoked with arguments:
  # @return a promise without any resolve arguments
  toFile: (filePath, dancers) =>
    new Promise (accept, reject) =>
      return reject new Error "no file selected" unless filePath?
      filePath = resolve normalize filePath

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
        'address.phone': i18n.lbl.phone
        cellphone: i18n.lbl.cellphone
        birth: i18n.lbl.birth
        email: i18n.lbl.email
        'card.knownBy': i18n.lbl.knownBy

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
      Promise.all((dancer.card for dancer in dancers)).then (cards) =>
        Promise.all((dancer.address for dancer in dancers)).then (addresses) =>
          for dancer, i in dancers
            data.push (
              first = true
              for attr of columns
                if 'address.' is attr[...8]
                  value = addresses[i][attr[8..]]
                else if 'card.' is attr[...5]
                  value = cards[i][attr[5..]]
                else
                  value = dancer[attr]

                cell = 
                  value: value
                  autoWidth: true
                  hAlign: 'left'
                  borders:
                    top: borderH
                if cell.value?
                  switch attr
                    # format dates
                    when 'birth' then cell.value = cell.value.format 'DD/MM/YYYY'
                    # format phones
                    when 'address.phone', 'cellphone' then cell.value = _.chop(cell.value, 2).join ' '
                    # format known by
                    when 'card.knownBy' then cell.value = (i18n.knownByMeanings[key] or key for key in cell.value).join ','
                if first
                  first = false
                else
                  cell.borders.left = borderV
                cell
            )
          # write file in base64
          writeFile filePath, xlsx(content).base64, 'base64', (err) =>
            return reject err if err?
            accept()
