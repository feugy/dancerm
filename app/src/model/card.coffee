_ = require 'lodash'
async = require 'async'
Persisted = require './tools/persisted'
Registration = require './registration'
# because of circular dependency
Dancer = null

# A card gather several dancers to group their registrations
module.exports = class Card extends Persisted

  # how the dancers has known the school: leaflets, website, pagesjaunesFr, searchEngine, directory, associationsBiennal, mouth, elders, groupon, other
  knownBy: []

  # list of embedded registrations
  registrations: []

  # Creates a card from a set of raw JSON arguments
  # Default values will be applied, and only declared arguments are used
  #
  # @param raw [Object] raw attributes of this card
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      knownBy: []
      registrations: []
    # enrich registrations with models
    raw.registrations = (for rawRegistration in raw.registrations
      if rawRegistration?.constructor?.name isnt 'Registration'
        new Registration rawRegistration
      else
        rawRegistration
    )

    # fill attributes
    super(raw)
    Dancer = require './dancer' unless Dancer?

  # Merge current card with other
  # Dancers will be moved into this card, and removed from the other.
  # Registrations and known by will be merged
  # The other card will be removed
  #
  # @param other [Card] other card that will be merged into this one
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no error occured
  merge: (other, done) =>
    # find card's dancers
    Dancer.findWhere {cardId: other.id}, (err, dancers) =>
      return done err if err?
      # moves them to this card
      async.each dancers, (dancer, next) =>
        dancer.cardId = @id
        dancer.save next
      , (err) =>
        return done err if err?
        # merge known by
        @knownBy.push mean for mean in other.knownBy when not(mean in @knownBy)
        # merge registrations
        for imported in other.registrations
          existing = _.findWhere @registrations, season: imported.season
          if existing?
            # merge charge and payments
            existing.charged += imported.charged
            existing.payments = existing.payments.concat imported.payments
            existing.updateBalance()
            # merge also certificates
            existing.certificates[attr] = value for attr, value of other.certificates
          else
            @registrations.push imported
        # removes other card
        other.remove done