_ = require 'underscore'
Persisted = require './tools/persisted'
Registration = require './registration'
# because of circular dependency
Dancer = null

observeSupported = Object.observe?

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

    # on registration change, remove old listeners and add new ones
    Object.defineProperty @, 'registrations',
      configurable: true
      get: -> @_raw.registrations
      set: (val) -> 
        if @_raw.registrations? and observeSupported
          Array.unobserve @_raw.registrations, @_onRegistrationsChanged
        @_raw.registrations = val
        if @_raw.registrations? and observeSupported
          Array.observe @_raw.registrations, @_onRegistrationsChanged
        @_onRegistrationsChanged [
          addedCount: @_raw.registrations.length
          index: 0
          object: @_raw.registrations
          removed: []
          type: 'splice'
        ]
    # for bindings initialization
    @registrations = @registrations

  # Merge current card with other
  # Dancers will be moved into this card, and removed from the other.
  # Registrations and known by will be merged
  # The other card will be removed
  #
  # @param other [Card] other card that will be merged into this one
  # @return a promise without any resolve parameter
  merge: (other) =>
    # find card's dancers
    Dancer.findWhere(cardId: other.id).then (dancers) =>
      # moves them to this card
      Promise.all((
        for dancer in dancers
          dancer.cardId = @id
          dancer.save()
      )).then =>
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
        # emit global change
        @emit 'change'
        # removes other card, returning the promise
        other.remove()

  # **private**
  # Emit change event when registration have changed
  #
  # @param details [Object] change details, containing added 'object' array, and 'removed' object array.
  _onRegistrationsChanged: ([details]) =>
    # update bindings
    if details?.removed?
      removed.removeListener 'change', @_onSingleRegistrationChanged for removed in details.removed when removed?.removeListener
    if details?.object
      added.on 'change', @_onSingleRegistrationChanged for added in details.object when added?.on
    @emit 'change', 'registrations', @_raw.registrations

  # **private**
  # Emit change event when single registration changed itself
  #
  # @param attr [String] modified path
  # @param value [Any] new value
  _onSingleRegistrationChanged: (attr, value) =>
    @emit 'change', "registrations.#{attr}", value