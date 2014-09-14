_ = require 'underscore'
{readFile, writeFile} = require 'fs-extra'
{generateId} = require './common'
Address = require '../model/address'
Dancer = require '../model/dancer'
DanceClass = require '../model/danceclass'
Card = require '../model/card'
Registration = require '../model/registration'
Payment = require '../model/payment'
{separator} = require '../service/export'

module.exports = 

  # Make every first letter of the sentence upper case, and everything else lower case
  # Words less than 3 letters are not capitalize
  #
  # @param sentence [String] input sentence
  # @return its caputalize version
  capitalize: (sentence) ->
    return sentence unless _.isString(sentence) and sentence.length > 0
    words = sentence.split /([\s\-_'\/])/
    (for word, i in words
      if i is 0 or word.length > 3
        word[0].toUpperCase() + word.toLowerCase()[1..]
      else
        word.toLowerCase()
    ).join ''
  
  # Read a v2 dump file and migrate it into a v3 dump file
  #
  # @param input [String] v2 dump input file path
  # @param output [String] v3 dump output file path
  # @return a promise without resolve argument
  migrate: (input, output) ->
    new Promise (resolve, reject) ->
      # Read file
      readFile input, 'utf8', (err, content) -> 
        return reject err if err?
        try 
          origin = JSON.parse content
          addresses = []
          cards = []
          dancers = []
          danceClasses = []

          # first, dance classes
          for planning in origin.plannings
            for raw in planning.danceClasses
              raw.season = planning.season
              raw._v = 0
              danceClasses.push JSON.stringify new DanceClass(raw).toJSON() 

          # second, dancers
          for dancer in origin.dancers
            dancer.id = generateId()
            dancer._v = 0
            dancer.danceClassIds = []

            # sanitize names
            dancer.lastname = module.exports.capitalize dancer.lastname
            dancer.firstname = module.exports.capitalize dancer.firstname

            # get address, default to empty one
            address = new Address id: generateId()
            if dancer.address?
              raw = dancer.address
              raw.city = module.exports.capitalize raw.city
              raw.id = generateId()
              raw._v = 0
              raw.phone = if dancer.phone? then dancer.phone else null
              address = new Address raw
            # make relation and keep json for save
            dancer.addressId = address.id
            addresses.push JSON.stringify address.toJSON()

            # get registrations into new card
            card = new Card id: generateId(), _v:0, knownBy: (
              for mean in dancer.knownBy
                switch mean.toLowerCase()
                  when 'ancien', 'anciens' then 'elders'
                  when 'groupon' then 'groupon'
                  else mean
              )
            if dancer.registrations
              for reg in dancer.registrations
                # build a registration for each old planning
                registration = new Registration
                  season: _.findWhere(origin.plannings, id:reg.planningId).season
                  charged: reg.charged
                  period: reg.period
                # move certification from old dancer to new registration 
                registration.certificates[dancer.id] = dancer.certified
                # move dance classes from old registration to new dancer 
                dancer.danceClassIds = dancer.danceClassIds.concat reg.danceClassIds
                # move payments and add payer on checks
                registration.payments = (
                  for raw in reg.payments
                    raw.payer = dancer.lastname if raw.type is 'check'
                    new Payment raw
                )
                card.registrations.push registration
            # make relation and keep json for save
            dancer.cardId = card.id
            cards.push JSON.stringify card.toJSON()

            # keep dancer
            delete dancer.address
            delete dancer.phone
            delete dancer.registrations
            delete dancer.certified
            delete dancer.knownBy
            dancers.push JSON.stringify new Dancer(dancer).toJSON()

          # write contents
          content = separator + 'DanceClass\n' + danceClasses.join('\n') +
            '\n' + separator + 'Dancer\n' + dancers.join('\n') +
            '\n' + separator + 'Address\n' + addresses.join('\n') +
            '\n' + separator + 'Card\n' + cards.join('\n')

          writeFile output, content.replace(/"id":/g, '"_id":'), 'utf8', (err) ->
            return reject err if err?
            console.log "migration finished: #{danceClasses.length} dance classes, #{dancers.length} dancers, addresses and cards processed"
            resolve()
        catch err
          reject err