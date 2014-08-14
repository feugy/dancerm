_ = require 'underscore'
Persisted = require './tools/persisted'

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
    # fill attributes
    super(raw)