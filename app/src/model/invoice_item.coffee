_ = require 'lodash'
moment = require 'moment'
Base = require './tools/base'

# Item of a given invoice.
# Related to a given dance class, and one or more dancers.
# Embedded into invoice
module.exports = class Payment extends Base

  # item name
  name: null

  # sold quantity
  quantity: 1

  # unitary price, including taxes
  price: null

  # VAT percentage applied
  vat: 0

  # discount amount on total price
  discount: 0

  # related objects
  dancerIds: []
  danceClassId: null

  # Creates a payment from a set of raw JSON arguments
  #
  # @param raw [Object] raw attributes of this payment
  constructor: (raw = {}) ->
    # set default values
    _.defaults raw,
      name: null
      quantity: 1
      price: 0
      vat: 0
      discount: 0,
      dancerIds: []
      danceClassId: null
    # fill attributes
    super(raw)
    # enrich object attributes
    @quantity = +@quantity
    @prive = +@price
    @vat = +@vat
    @discount = +@discount