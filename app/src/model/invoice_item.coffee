_ = require 'lodash'
moment = require 'moment'
Base = require './tools/base'

# Item of a given invoice.
# Related to a given dance class, and one or more dancers.
# Embedded into invoice
module.exports = class InvoiceItem extends Base

  # extends transient fields
  @_transient = Base._transient.concat ['total', 'dutyFreeTotal', 'taxTotal']

  # item name
  name: null

  # sold quantity
  quantity: 1

  # unitary price, including taxes
  price: null

  # VAT percentage applied (bellow 0)
  vat: 0

  # Discount percentage
  discount: 0

  # computed and read-only duty-free invoice total
  @property 'dutyFreeTotal',
    get: -> _.round((1 - @discount/100) * @price / (1 + @vat) * @quantity, 2) or 0

  # computed and read-only tax total
  @property 'taxTotal',
    get: -> _.round(@total - @dutyFreeTotal, 2) or 0

  # computed and read-only invoice total
  @property 'total',
    get: -> _.round((1 - @discount/100) * @price * @quantity, 2) or 0

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
    # fill attributes
    super(raw)
    # enrich object attributes
    @quantity = +@quantity
    @price = +@price
    @vat = +@vat
    @discount = +@discount