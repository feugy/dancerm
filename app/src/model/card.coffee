_ = require 'underscore'
Persisted = require './tools/persisted'
Registration = require './registration'

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
    raw.registrations = (new Registration rawRegistration for rawRegistration in raw.registrations when rawRegistration?.constructor?.name isnt 'Registration')

    # fill attributes
    super(raw)

    # on registration change, remove old listeners and add new ones
    Object.defineProperty @, 'registrations',
      configurable: true
      get: -> @_raw.registrations
      set: (val) -> 
        if @_raw.registrations?
          Array.unobserve @_raw.registrations, @_onRegistrationsChanged
        @_raw.registrations = val
        if @_raw.registrations?
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