_ = require 'lodash'
moment = require 'moment'
{each, eachSeries, map} = require 'async'
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
  # @param done [Function] a completion callback, invoked with parameters:
  # @option done err [Error] an error object or null if no error occured
  dump: (filePath, done = ->) =>
    try
      return done new Error "no file selected" unless filePath?
      start = moment()
      filePath = resolve normalize filePath
      console.info "dump data in #{filePath}..."
      start = moment()
      classes = [Address, Card, Dancer, DanceClass]
      dbPath = getDbPath()
      # since node-webkit 0.10.5 and nedb, using sync fs API is less error-prone than classical async API
      ensureFileSync filePath
      writeFileSync filePath, ""
      console.log "reinit file..."
      eachSeries classes, (clazz, next) =>
        start2 = moment()
        clazz.findAllRaw (err, instances) =>
          return next err if err?
          console.log "#{clazz.name} model read..."
          newContent = ["#{@constructor.separator}#{clazz.name}"]
          newContent.push JSON.stringify instance for instance in instances
          console.log "#{clazz.name} model written in #{moment().diff start2}ms"
          appendFileSync filePath, newContent.join('\n'), encoding: 'utf8'
          next()
      , (err) =>
        console.info "dump in #{filePath} finished in #{moment().diff start}ms !"
        done err
    catch err
      done err

  # Exports a dancer list to an XlsX file
  #
  # @param filePath [String] absolute or relative path to the written file
  # @param dancers [Array<Dancer>] the list of exported dancers
  # @param done [Function] a completion callback, invoked with parameters:
  # @option done err [Error] an error object or null if no error occured
  toFile: (filePath, dancers, done) =>
    return done new Error "no file selected" unless filePath?
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
    map dancers, (dancer, next) -> 
      dancer.getCard next
    , (err, cards) =>
      return done err if err?
      map dancers, (dancer, next) ->
        dancer.getAddress next
      , (err, addresses) =>
        return done err if err?
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
        writeFile filePath, xlsx(content).base64, 'base64', (err) => done err