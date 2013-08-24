define [
  'underscore'
  'moment'
  'xlsx'
  '../model/dancer/dancer'
], (_, moment, xlsx, Dancer) ->

  # mandatory columns to proceed with extraction
  mandatory = ['firstname', 'lastname']

  # Import utility class.
  # Allow importation of dancers from XLSX files 
  class Import

    constructor: (done) ->
      done()

    # Read the content of an XlsX file, and extract dancers from it
    #
    # @param path [FileEntry] path to the read file
    # @param callback [Function] extraction end callback, invoked with arguments:
    # @option callback err [Error] an Error object, or null if no problem occurred
    # @option callback dancers [Array<Dancer>] the list (that may be empty) of extracted dancers
    fromFile: (fileEntry, callback) =>
      return callback new Error "no file selected" unless fileEntry?
      fileEntry.file (file) =>
        reader = new FileReader()
        reader.onload = (event) =>
          try 
            # read xlsx file, and remove data-URL preprend
            content = xlsx event.target.result.replace /^data:[^;]*;base64,/, ''

            # read at least one worksheet
            return callback new Error "no worksheet found in file" unless content?.worksheets?.length > 0
            
            dancers = []
            report =
              readTime: content.processTime
              modifiedBy: content.lastModifiedBy 
              modifiedOn: moment content.modified
              worksheets: []
            start = Date.now()
            # read all worksheets
            for worksheet in content.worksheets
              @_extractWorksheet dancers, worksheet, report

            # and returns results
            report.extractTime = Date.now() - start
            callback null, dancers, report
          catch exc
            return callback exc

        # jszip only accept base64 url encoded content
        reader.readAsDataURL file

    # **private**
    # Extract dancers from a given worksheet data matrix
    # First find column names, then creates dancers
    #
    # @param dancers [Array<Dancer>] array in which dancers are added
    # @param worksheet [Object] worksheet content with the `data` matrix analyzed
    # @param report [Object] extraction report: add inside the worksheet array a report
    _extractWorksheet: (dancers, worksheet, report) =>
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
        # registrations

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
        raw = {}
        # extract and convert each values
        for attr, col of columns 
          raw[attr] = @_convertValue attr, line[col]?.value
          #console.log "#{attr} convert '#{line[col]?.value}' -> '#{raw[attr]}'"
      
        # check that we have all mandatory columns
        if _.every(mandatory, (attr) -> raw[attr]?)
          # expand address
          if 'street' of raw or 'city' of raw or 'zipcode' of raw
            raw.address = street: raw.street, city: raw.city, zipcode: raw.zipcode
            delete raw.city
            delete raw.street
            delete raw.zipcode
          dancers.push new Dancer raw
          result.extracted++

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
        when 'telephone', 'téléphone', 'tel', 'tel.', 'tel domicile' then return 'phone'
        when 'portable', 'tel bureau' then return 'cellphone'
        when 'adresse', 'addr.', 'rue' then return 'street'
        when 'ville' then return 'city' 
        when 'code postal' then return 'zipcode'
        when 'publicité' then return 'knownBy'
        when 'id', '#' then return 'id'
        when 'créé', 'cree', 'creation', 'création' then return 'created'
        when 'année naissance', 'anniversaire', 'né le' then return 'birth'

    # **private**
    # Convert incoming attribute value into a supported dancer attribute value
    #
    # @param attr [String] attribute name
    # @param value [Object] converted value. May by null
    # @return the matching dancer attribute value, or null
    _convertValue: (attr, value) =>
      value = "#{value}" if _.isNumber value
      return undefined unless _.isString value
      lValue = value.toLowerCase().trim()
      switch attr
        when 'firstname', 'lastname', 'street', 'city' then return _.capitalize lValue
        when 'title'
          if lValue in ['melle', 'mlle', 'melle.', 'mlle.'] 
            return 'Mlle' 
          else if lValue in ['mme', 'madame', 'mme.'] 
            return 'Mme' 
          else 
            return 'M.'
        when 'email' then return lValue
        when 'phone', 'cellphone', 'zipcode'
          value = lValue.replace('+33', '0').replace(/\D/g, '').trim()
          return if value is '' then null else value
        when 'knownBy'
          return (
            for val in lValue.split ','
              val = val.trim()
              switch val
                when 'bao', 'biennale des asso.', 'biennale des associations' then 'associationsBiennal'
                when 'google', 'yahoo', 'internet', 'moteur de recherche' then 'searchEngine'
                when 'tract', 'tracts' then 'leaflets'
                when 'notre site web', 'ecolededanceribas', 'ecolededanceribas.com', 'www.ecolededanceribas.com' then 'website'
                when 'pagejaunes.fr' then 'pagejaunesFr'
                when 'annuaire' then 'directory'
                when 'bouche à oreille' then 'mouth'
                else _.capitalize val
            )
        when 'birth'
          for format in ['DD/MM/YYYY', 'DD-MM-YYYY', 'YYYY']
            value = moment lValue, format
            return value if value.isValid()
          return null
        when 'created'
          for format in ['DD/MM/YYYY HH:mm:ss', 'DD/MM/YYYY', 'DD-MM-YYYY HH:mm:ss', 'DD-MM-YYYY', undefined]
            value = moment lValue, format
            return value if value.isValid()
          return undefined


          

          