define [
  'i18n!nls/common'
  '../app'
], (i18n, app) ->
  
  # i18n filter replace a given expression by its i18n value.
  # the 'sep' option can be added to suffix with the fieldSeparator label 
  app.filter 'i18n', ['$parse', (parse) -> (input, options) -> 
    sep = ''
    if options?.sep is true
      sep = parse('lbl.fieldSeparator') i18n
    value = parse(input) i18n
    "#{if value? then value else input}#{sep}"
  ]
    
  # classDate filter displays with friendly names start or end of a dance class
  app.filter 'classDate', [ -> (input, length) ->
    return unless input?.length is 9
    day = i18n.lbl[input[0..2]]
    "#{day} #{input[4..8]}"
  ]