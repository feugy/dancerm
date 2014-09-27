_ = require 'underscore'
moment = require 'moment'
{each} = require 'async'
{readFile, stat} = require 'fs'
path = require 'path'
xlsx = require 'xlsx.js'
mime = require 'mime'
Export = require './export'
Dancer = require '../model/dancer'
DanceClass = require '../model/danceclass'
Address = require '../model/address'
Card = require '../model/card'
Registration = require '../model/registration'
{generateId} = require '../util/common'

# mandatory columns to proceed with extraction
mandatory = ['title', 'lastname']

# used to get real constructor from class name
classes = 
  DanceClass: DanceClass
  Address: Address
  Dancer: Dancer
  Card: Card

# Import utility class.
# Allow importation of dancers from XLSX files 
module.exports = class Import

  # Merges new dancers into existing ones
  # 
  # @param added [Array<Base>] array of imported models
  # @return promise with object as parameter containing
  # @option return byClass [Object] number of modified or added models by class (name as key)
  # @option return conflicts [Array<Object>] conflicted models, in an object containing `existing` and `imported` keys
  merge: (imported) =>
    report =
      byClass: {}
      conflicts: []
    Promise.all((
      for model in imported
        # use a closure to avoid model erasure
        ((model) -> 
          new Promise (resolve, reject) ->
            # try to find existing model for each imported model, and return an object with both
            model.constructor.find(model.id).then((existing) ->
              resolve existing: existing, imported: model
            ).catch (err) ->
              unless -1 is err.message.indexOf 'not found'
                resolve existing: null, imported: model
              else
                reject err
        ) model
    )).then (processed) =>
      Promise.all((
        for {existing, imported} in processed
          if not(existing?) or existing._v < imported._v
            # no existing model: save imported model
            # imported version is above existing one: save imported model
            className = imported.constructor.name
            report.byClass[className] = 0 unless className of report.byClass
            report.byClass[className]++
            imported.save()
          else 
            if existing?._v > imported?._v
              console.log existing?._v, imported?._v
              # existing and imported have same version: conflict detected
              report.conflicts.push existing: existing, imported: imported
            # else
            # existing version is above imported version: no importation
            new Promise (resolve) -> resolve()
      )).then => report

  # Read the content of an XlsX file, and extract dancers from it
  #
  # @param filePath [String] absolute or relative path to the read file
  # @return promise with an object as resolve parameter, containing:
  # @option return models [Array<Base>] an array of extracted models
  # @option return report [Object] an extraction report with encountered errors
  fromFile: (filePath) =>
    new Promise (resolve, reject) =>
      return reject new Error "no file selected" unless filePath?
      filePath = path.resolve path.normalize filePath
      extension = mime.lookup filePath

      # check file size
      console.log "tries to open #{filePath}..."
      stat filePath, (err, stats) =>
        return reject err if err?
        return reject new Error 'file is empty' if stats.size is 0

        # Xlsx content
        if extension is 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          console.log "try to extract from xlsx..."
          readFile filePath, (err, data) =>
            return reject err if err?
            try 
              # jszip only accept base64 url encoded content
              content = xlsx data.toString 'base64'

              # read at least one worksheet
              return reject new Error "no worksheet found in file" unless content?.worksheets?.length > 0
              
              # extracted models
              models = 
                Address: []
                Card: []
                Dancer: []
              # extractionreport
              report =
                readTime: content.processTime
                modifiedBy: content.lastModifiedBy 
                modifiedOn: moment content.modified
                worksheets: []
              start = Date.now()
              # read all worksheets
              for worksheet in content.worksheets
                @_extractWorksheet models, worksheet, report

              # and returns results
              report.extractTime = Date.now()-start-report.readTime
              resolve models: models.Address.concat(models.Card).concat(models.Dancer), report: report
            catch exc
              return reject exc

        # Json content
        else if extension is 'application/json'
          console.log "try to extract from a v2 dump..."
          return reject new Error "to be refined"
          start =  Date.now()
          readFile filePath, 'utf8', (err, data) =>
            return reject err if err?
            try 
              report =
                readTime: Date.now()-start
              # parse content
              content = JSON.parse data
              return reject new Error "no dancers found in file" unless content?.dancers?.length > 0
              dancers = ({dancer: new Dancer dancer} for dancer in content.dancers)
              # and returns results
              report.extractTime = Date.now()-start-report.readTime
              resolve models: dancers, report: report
            catch exc
              return reject exc

        else 
          console.log "try to extract from a v3 dump..."
          # try to read dump v3
          start = Date.now()
          readFile filePath, 'utf8', (err, data) =>
            return reject err if err?
            report = 
              readTime: Date.now()-start,
            if -1 is data.indexOf Export.separator
              return reject new Error "unsupported format #{extension}"
            @_dumpV3(data, report).then((models) =>
              report.extractTime = Date.now()-start-report.readTime
              resolve models: models, report: report
            ).catch (err) => reject err

  # Extract from version 3 dump
  #
  # @param data [String] imported content, as string
  # @param report [Object] extraction report, that will be filled with encountered errors
  # @return promise with array of object as resolve parameter. Contains the list (that may be empty) of extracted models, that may be dance classes, dancers, card or addresses.
  _dumpV3: (data, report) =>
    start = Date.now()
    report.errors = []
    report.byClass = {}
    models = []
    new Promise (resolve, reject) =>
      # identifies model class
      currentClass = null
      className = ''
      for line, i in data.split '\n'
        if 0 is line.indexOf Export.separator
          # get the current class
          className = line.replace(Export.separator, '').trim()
          currentClass = classes[className]
          unless currentClass?
            report.errors.push "line #{i}: unsupported model class #{className}"
          else
            report.byClass[className] = 0
        else if currentClass?
          # rehydrate model
          try
            models.push new currentClass JSON.parse line
            report.byClass[className]++
          catch err
            report.errors.push "line #{i}: failed to parse model #{className}: #{err}"
      # TODO check relationnal constraints
      resolve models
    
  # **private**
  # Extract dancers from a given worksheet data matrix
  # First find column names, then creates dancers
  #
  # @param models [Object] Per class storage. Contains for each class (name as key) an array of added models
  # @param worksheet [Object] worksheet content with the `data` matrix analyzed
  # @param report [Object] extraction report: add inside the worksheet array a report
  _extractWorksheet: (models, worksheet, report) =>
    result =
      extracted: 0
      details: null
      name: worksheet?.name
    report.worksheets.push result

    # extracted columns
    colInitialized = false
    colRow = 0
    columns = 
      title: -1
      firstname: -1
      lastname: -1
      email: -1
      phone: -1
      cellphone: -1
      street: -1
      zipcode: -1
      city: -1
      birth: -1
      knownBy: -1
      id: -1
      created: -1

    # do not handle empty worksheets
    return result.details = 'Empty worksheet' unless worksheet.data?.length > 0
      
    
    # first, search for column names
    for line, row in worksheet.data when line?.length > 0
      colRow = row
      for cell, col in line when cell?
        value = @_convertCol cell.value
        columns[value] = col if value?

      # check that we have all mandatory columns
      if _.every(mandatory, (col) -> columns[col] isnt -1)
        colInitialized = true
        break 
      # stop after 20 tries
      break if row > 20

    # do not process if a mandatory column is missing
    return result.details = "Missing #{_.toSentenceSerial mandatory} column" unless colInitialized

    # then extract dancers
    for line, row in worksheet.data when line?.length > 0 and row > colRow
      # check multiple dancers on same line
      titles = @_convertValue 'title', line[columns.title]?.value
      # only one ? let's put it in an array
      titles = [titles] unless _.isArray titles
      # process this lines as many times as titles found.
      for title, index in titles
        result.extracted += @_processLine title, index, line, columns, models 
        
  # **private**
  # Convert a given line into a dancer. 
  # Dancer will be created only if the mandatory fields are found.
  #
  # @param title [String] dancer's title
  # @param index [Integer] extracted values index, (firstname, lastname, phone, email), when values are multiple
  # @param line [Array] orignal line data
  # @param columns [Object] hashmap of dancer's attribute and their corresponding column
  # @param models [Object] Per class storage. Contains for each class (name as key) an array of added models
  # @return how many dancers have been extracted from this lie
  _processLine: (title, index, line, columns, models) =>
    raw = title: title
    # extract and convert each values
    for attr, col of columns when attr isnt 'title'
      raw[attr] = @_convertValue attr, line[col]?.value, index
      # console.log "#{attr} convert '#{line[col]?.value}' -> '#{raw[attr]}'", line[col]

    # check that we have all mandatory columns
    return 0 unless _.every(mandatory, (attr) -> raw[attr]?)
    # created an address
    addressFields = ['street', 'city', 'zipcode', 'phone']
    for field in addressFields when field of raw
      if index is 0
        # on first dancer, creates new address
        address = new Address id: generateId(), street: raw.street, city: raw.city, zipcode: raw.zipcode, phone: raw.phone
        models.Address.push address
        raw.addressId = address.id
      else
        # reuse same line address id
        raw.addressId = models.Address[-1..].pop().id
      delete raw[field] for field of addressFields
      break

    if index is 0
      # creates a card for first dancer
      card = new Card id: generateId(), knownBy: raw.knownBy
      models.Card.push card
      raw.cardId = card.id

      # get last registration
      if raw.lastRegistration
        card.registrations.push new Registration season: "#{raw.lastRegistration}/#{raw.lastRegistration+1}"
    else
      # reuse same line card id
      raw.cardId = models.Card[-1..].pop().id
    delete raw.knownBy

    # and at last builds dancer
    raw.id = generateId()
    dancer = new Dancer raw
    models.Dancer.push dancer
    1

  # **private**
  # Convert incoming column name into a supported dancer attribute
  #
  # @param value [Object] converted value. May by null
  # @return the matching dancer attribute, or null
  _convertCol: (value) =>
    return null unless _.isString value
    switch value.toLowerCase().trim()
      when 'prenom', 'prénom' then return 'firstname'
      when 'nom' then return 'lastname'
      when 'titre', 'civilité', 'civilite' then return 'title'
      when 'email', 'mail', 'e-mail', 'adresse mail' then return 'email'
      when 'telephone', 'téléphone', 'tel', 'tel.', 'tel domicile', 'téléphone  domicile' then return 'phone'
      when 'portable', 'tel bureau', 'téléphone  bureau' then return 'cellphone'
      when 'adresse', 'addr.', 'rue', 'adresse1' then return 'street'
      when 'ville' then return 'city' 
      when 'code postal', 'code_postal' then return 'zipcode'
      when 'publicité', 'connu par' then return 'knownBy'
      when 'id', '#' then return 'id'
      when 'créé', 'cree', 'creation', 'création' then return 'created'
      when 'année naissance', 'anniversaire', 'né le', 'né(e) le' then return 'birth'
      when 'année de cours', 'année cours' then return 'lastRegistration'

  # **private**
  # Convert incoming attribute value into a supported dancer attribute value
  # 'firstname', 'lastname', 'birth', 'phone', 'cellphone' and 'email' fields may have multiple values (separated with a comma).
  # In that case, index decide which one to return.
  # For 'title' field, if comma is found, an array of possible values are returned.
  #
  # @param attr [String] attribute name
  # @param value [Object] converted value. May by null
  # @param index [Integer] if multiple values are found, the extracted value index, default to 0.
  # @return the matching dancer attribute value, or null
  _convertValue: (attr, value, index = 0) =>
    if _.isNumber value
      return undefined if isNaN value
      value = "#{value}" 
    return undefined unless _.isString value

    # handles first multiple value fields
    if attr in ['firstname', 'lastname', 'email', 'phone', 'cellphone', 'birth'] and 0 <= value.indexOf ','
      values = value.split ','
      return @_convertValue attr, values[if index >= values.length then values.length-1 else index]

    lValue = value.toLowerCase().trim()
    switch attr
      when 'firstname', 'lastname', 'street', 'city' then return _.capitalize lValue
      when 'title'
        if 0 <= lValue.indexOf ','
          # multiple dancers on the same raw
          return (@_convertValue 'title', val for val in lValue.split ',')
        else
          if lValue in ['melle', 'mlle', 'melle.', 'mlle.'] 
            return 'Mlle' 
          else if lValue in ['mme', 'madame', 'mme.', 'me'] 
            return 'Mme' 
          else
            return 'M.'
      when 'email' then return lValue
      when 'phone', 'cellphone', 'zipcode'
        value = lValue.replace('+33', '0').replace(/\D/g, '').trim()
        return if value is '' then null else value
      when 'knownBy'
        return _.compact _.uniq (
          for val in lValue.split ','
            val = val.trim()
            switch val
              when 'bao', 'biennale asso.', 'biennale des asso.', 'biennale des associations', 'forum des associations' then 'associationsBiennal'
              when 'google', 'yahoo', 'internet', 'moteur de recherche', 'web' then 'searchEngine'
              when 'tract', 'tracts' then 'leaflets'
              when 'site', 'notre site web', 'ecolededanceribas', 'ecolededanceribas.com', 'www.ecolededanceribas.com' then 'website'
              when 'pagejaunes.fr', 'www.pagesjaunes.fr', 'pagesjaunes.fr', 'www.pagejaunes.fr' then 'pagesjaunesFr'
              when 'annuaire', 'annuaire papier' then 'directory'
              when 'bouche à oreille' then 'mouth'
              when 'ancien', 'anciens', 'maman ancien élève', 'soeur', 'soeurs', 'frère', 'frères' then 'elders'
              when 'groupon' then 'groupon'
              else _.capitalize val
          )
      when 'birth'
        for format in ['DD/MM/YYYY', 'DD-MM-YYYY', 'YYYY']
          # use strict mode to avoid parsing 2-digit years
          value = moment lValue, format, true
          return value if value?.isValid()
        return null
      when 'created'
        for format in ['DD/MM/YYYY HH:mm:ss', 'DD/MM/YYYY', 'DD-MM-YYYY HH:mm:ss', 'DD-MM-YYYY', undefined]
          value = moment lValue, format
          return value if value?.isValid()
        return undefined
      when 'lastRegistration'
        return parseInt lValue