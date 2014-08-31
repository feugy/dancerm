{expect} = require 'chai'
_ = require 'underscore'
moment = require 'moment'
{Promise} = require 'es6-promise'
Registration = require '../../../app/script/model/registration'
Payment = require '../../../app/script/model/payment'
Card = require '../../../app/script/model/card'
Dancer = require '../../../app/script/model/dancer'
Address = require '../../../app/script/model/address'
DanceClass = require '../../../app/script/model/danceclass'

describe 'Card model tests', ->

  beforeEach -> Promise.all [Card.drop(), Dancer.drop(), DanceClass.drop(), Address.drop()]
  
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

  describe 'given registration with dancers', ->

    existing = [
      new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [
        new Registration season: '2013/2014', charged: 300, period: 'year', payments:[ 
          new Payment type: 'cash', value: 150, receipt: '2013-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2013-08-26', payer: 'Simonin', bank: 'La Poste'
        ]
        new Registration season: '2014/2015', charged: 150, period: 'year', payments:[ 
          new Payment type: 'check', value: 150, receipt: '2014-10-24', payer: 'Simonin', bank: 'Société Générale'
        ]
      ]
      new Card id: '30cb3a48900e', _v: 0, knownBy: ['Groupon', 'website'], registrations: [
        new Registration season: '2013/2014', charged: 200, period: 'year', payments:[ 
          new Payment type: 'cash', value: 100, receipt: '2013-08-10', payer: 'Durand'
          new Payment type: 'cash', value: 100, receipt: '2013-09-10', payer: 'Durand'
        ]
        new Registration season: '2012/2013', charged: 100, period: 'year', payments:[ 
          new Payment type: 'check',  value: 100, receipt: '2012-09-10', payer: 'Durand', bank: 'La Poste'
        ]
      ]
      new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
      new Dancer id: 'fcf3d43e1f6f', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['00acbfb5e7d6', '043737c8e083'], title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
      new Dancer id: 'ea43920b42dc', _v: 0, cardId: '30cb3a48900e', addressId: '3900cc712ba3', title: 'Mme', firstname:'Rachel', lastname:'Durand', birth: '1970-01-01', cellphone: '0617979688'
      new DanceClass id: '00acbfb5e7d6', _v: 0, season: '2013/2014', kind: 'Rock/Salsa', color: 'color2', level: 'confirmé', start: 'Mon 20:00', end: 'Mon 21:30', teacher: 'Anthony', hall: 'Croix-Luizet'
      new DanceClass id: '043737c8e083', _v: 0, season: '2013/2014', kind: 'Danse sportive/Rock/Salsa', color: 'color3', level: '2 8/12 ans', start: 'Wed 17:30', end: 'Wed 18:30', teacher: 'Anthony', hall: 'Gratte-ciel 2'
      new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
      new Address id: '3900cc712ba3', _v: 0, street: '2 rue clément marrot', city: 'Lyon', zipcode: 69007
    ]


    beforeEach ->
      @timeout 5000
      Promise.all (model.save() for model in existing)
    
    it 'should merge with another card', ->
      existing[0].merge(existing[1]).then ->
        # all dancers have been migrated
        for i in [2..4]
          expect(Dancer.find existing[i].id).to.eventually.have.property('cardId').that.equal existing[0].id
        # known by have been merge
        expect(existing[0]).to.have.property('knownBy').that.deep.equal ['pagesjaunesFr', 'website', 'Groupon']
        # registrations have been merged
        expect(existing[0]).to.have.property('registrations').that.has.lengthOf 3
        for registration, i in [
            new Registration season: '2013/2014', charged: 500, period: 'year', payments:[ 
              new Payment type: 'cash', value: 150, receipt: '2013-08-04', payer: 'Simonin'
              new Payment type: 'check', value: 150, receipt: '2013-08-26', payer: 'Simonin', bank: 'La Poste'
              new Payment type: 'cash', value: 100, receipt: '2013-08-10', payer: 'Durand'
              new Payment type: 'cash', value: 100, receipt: '2013-09-10', payer: 'Durand'
            ]
            new Registration season: '2014/2015', charged: 150, period: 'year', payments:[ 
              new Payment type: 'check', value: 150, receipt: '2014-10-24', payer: 'Simonin', bank: 'Société Générale'
            ]
            new Registration season: '2012/2013', charged: 100, period: 'year', payments:[ 
              new Payment type: 'check',  value: 100, receipt: '2012-09-10', payer: 'Durand', bank: 'La Poste'
            ]
          ]
          expect(existing[0].registrations[i].toJSON()).to.deep.equal registration.toJSON()
        # card does not exists any more
        expect(Card.find existing[1].id).to.eventually.be.rejectedWith "'#{existing[1].id}' not found"
