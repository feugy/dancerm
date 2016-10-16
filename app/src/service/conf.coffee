{kebabCase, isEqual, cloneDeep, omit} = require 'lodash'

# This service manage all configuration element that are saved in localStorage
module.exports = class Conf

  # Path that stores DB save
  dumpPath: null

  # UI theme
  theme: 'none'

  # Currently selected search service ('invoice', 'card', 'lesson')
  searchService: null

  # Search criteria for dancers, invoices and lessons
  dancerSearch: null
  lessonSearch: null
  invoiceSearch: null

  # Mention displayed on invoice when VAT isn't applied
  noVatMention: 'Non Soumis à T.V.A. Article C.G.I. 261, 4-4°b'

  # Vat settings
  vat: 0.20

  # Available teachers
  teachers: []

  # Search prefix for payer
  payerPrefix: 'p'

  # Load configuratin
  constructor: () ->
    @_keys = [
      {name: 'dumpPath'}
      {name: 'theme'}
      {name: 'vat', type: 'number'}
      {name: 'noVatMention'}
      {name: 'payerPrefix'}
      {name: 'teachers', type: 'json', clean: (teachers) => teachers.map (teacher) => omit teacher, '$$hashKey'}
      {name: 'searchService'},
      {name: 'dancerSearch', type: 'json'},
      {name: 'lessonSearch', type: 'json'},
      {name: 'invoiceSearch', type: 'json'}
    ]
    @load()

  # Saves the modified values into localStorage
  #
  # @param done [Function] a completion callback, invoked with parameters:
  # @option done err [Error] an error object or null if no error occured
  save: (done = () ->) =>
    for {name, type, clean} in @_keys when not isEqual @_previous[name], (if clean? then clean @[name] else @[name])
      value = @[name]
      switch type
        when 'json'
          clean value if clean?
          value = JSON.stringify value
      console.log "save conf key #{name} with new value", value
      localStorage?.setItem kebabCase(name), value
      @_previous[name] = cloneDeep value

    setTimeout () ->
      done null
    , 0

  # Loads configuration from localStorage
  #
  # @param done [Function] a completion callback, invoked with parameters:
  # @option done err [Error] an error object or null if no error occured
  load: (done = () ->) =>
    @_previous = {}
    for {name, type} in @_keys
      try
        value = localStorage?.getItem kebabCase name
        if value?
          switch type
            when 'number'
              value = parseFloat value
            when 'json'
              value = JSON.parse value
          @[name] = value
        @_previous[name] = cloneDeep @[name]
      catch err
        console.error "failed to read configuration value #{name}: #{err}"

    setTimeout () =>
      console.log 'configuration loaded'
      done null
    , 0
