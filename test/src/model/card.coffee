{expect} = require 'chai'
_ = require 'underscore'
moment = require 'moment'
Registration = require '../../../app/script/model/registration'
Payment = require '../../../app/script/model/payment'
Card = require '../../../app/script/model/card'

describe 'Card model tests', ->

  beforeEach -> Card.drop()
  
  it 'should new card be created with default values', ->
    # when creating a card without values
    tested = new Card()
    # then an id was set
    expect(tested).to.have.property('id').that.is.null
    # then default values were set
    expect(tested).to.have.property('knownBy').that.is.an('array').and.that.has.lengthOf 0
    expect(tested).to.have.property('registrations').that.is.an('array').and.that.has.lengthOf 0
    expect()

  it 'should card save raw values', (done) ->
    # givan some registrations and payments
    registration13 = new Registration
      season: '2013/2014'
      charged: 300
      balance: 200
      details: 'Inclu le paiement de M. Legrand'
      period: 'quarter'
      payments: [new Payment(
        type: 'cash'
        value: 100
        payer: 'Jean'
        bank: null
        details: null
        receipt: moment().toJSON()
      ), new Payment(
        type: 'check'
        value: 50
        bank: 'La Poste'
        details: 'something'
        receipt: moment().toJSON()
      ), new Payment( 
        type: 'card'
        value: 50
        payer: 'Dujardin'
        details: null
        bank: null
        receipt: moment().toJSON()
     )]
        
    registration12 = new Registration
      season: '2012/2013'
      charged: 100
      balance: 100
      period: 'year'
      payments: [new Payment
        type: 'check'
        value: 100
        payer: 'Jean'
        bank: 'La Poste'
        details: null
        receipt: moment().toJSON()
      ]

    # given a raw card
    raw = 
      knownBy: ['something else', 'elders']
      registrations: [registration13, registration12]

    # when creating a dancer with a clone to avoid modifications
    tested = new Card _.clone raw
    # then all defined attributes have been saved
    expect(tested).to.have.property 'id'
    # the card fields are available
    expect(tested).to.have.property('knownBy').that.deep.equal ['something else', 'elders']
    # then the registrations are available
    expect(tested).to.have.property('registrations').that.deep.equal [registration13, registration12]
    done()