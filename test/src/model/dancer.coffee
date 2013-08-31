{expect} = require 'chai'
_ = require 'underscore'
moment = require 'moment'
Storage = require '../../../app/script/service/storage'
Dancer = require '../../../app/script/model/dancer/dancer'
Address = require '../../../app/script/model/dancer/address'
Registration = require '../../../app/script/model/dancer/registration'
Payment = require '../../../app/script/model/dancer/payment'
Planning = require '../../../app/script/model/planning/planning'
DanceClass = require '../../../app/script/model/planning/danceclass'

describe 'Dancer model tests', ->

  storage = null

  before (done) ->
    storage = new Storage()
    Dancer.bind storage
    Planning.bind storage
    Dancer._cache = {}
    storage.removeAll Dancer, (err) ->
      return done err if err?
      Planning._cache = {}
      storage.removeAll Planning, done
  
  it 'should new dancer be created with default values', ->
    # when creating a dancer withou values
    tested = new Dancer()
    # then an id was set
    expect(tested).to.have.property 'id'
    expect(tested.id).to.be.a 'string'
    expect(tested.id).to.have.lengthOf 12
    # then the creation date was set
    expect(tested).to.have.property 'created'
    expect(tested.created.valueOf()).to.be.closeTo moment().valueOf(), 500
    # then registrations is an empty array
    expect(tested).to.have.property 'registrations'
    expect(tested.registrations).to.be.an 'array'
    expect(tested.registrations).to.have.lengthOf 0
    # then all plain attributes have been set to default
    expect(tested).to.have.property 'title', 'Mme'
    expect(tested).to.have.property 'firstname', ''
    expect(tested).to.have.property 'lastname', ''
    expect(tested).to.have.property 'address', null
    expect(tested).to.have.property 'email', null
    expect(tested).to.have.property 'phone', null
    expect(tested).to.have.property 'cellphone', null
    expect(tested).to.have.property 'birth', null
    expect(tested).to.have.property 'certified', false

  it 'should dancer save raw values', ->
    # given a raw dancer
    raw = 
      id: 'anId'
      created: moment().toJSON()
      title: 'M.'
      firstname: 'Jean'
      lastname: 'Dujardin'
      address:
        street: '15 place de la bourse'
        zipcode: 69100
        city: 'Villeurbanne'
      registrations: [
        planningId: 18
        danceClassIds: [1, 2]
        charged: 300
        balance: 200
        details: 'Inclu le paiement de M. Legrand'
        period: 'quarter'
        payments: [
          type: 'cash'
          value: 100
          bank: null
          details: null
          receipt: moment().toJSON()
        ,
          type: 'check'
          value: 50
          bank: 'La Poste'
          details: 'something'
          receipt: moment().toJSON()
        , 
          type: 'card'
          value: 50
          details: null
          bank: null
          receipt: moment().toJSON()
        ]
      ,
        planningId: 17
        danceClassIds: [2]
        charged: 300
        balance: 300
        payments: [
          type: 'cash'
          value: 300
          details: null
          receipt: moment().toJSON()
        ]
      ]

    # when creating a dancer with a clone to avoid modifications
    tested = new Dancer _.clone raw
    # then all defined attributes have been saved
    expect(tested).to.have.property 'id', raw.id
    expect(tested).to.have.property 'title', raw.title
    expect(tested).to.have.property 'firstname', raw.firstname
    expect(tested).to.have.property 'lastname', raw.lastname
    # then the address have been enriched
    expect(tested).to.have.property 'address'
    expect(tested.address).to.be.an.instanceOf Address
    expect(tested.address.toJSON()).to.deep.equal raw.address
    # then the registrations have been enriched
    expect(tested).to.have.property 'registrations'
    expect(tested.registrations).to.be.an 'array'
    for registration, i in tested.registrations
      expect(registration).to.be.an.instanceOf Registration
      expect(_.omit registration.toJSON(), 'payments').to.deep.equal _.omit raw.registrations[i], 'payments'
      for payment, j in registration.payments
        expect(payment).to.be.an.instanceOf Payment
        expect(payment.toJSON()).to.deep.equal raw.registrations[i].payments[j]
    # then the creation date have been enriched
    expect(tested.created.isSame raw.created).to.be.true
    expect(_.pick tested.toJSON(), 'id', 'title', 'created', 'firstname', 'lastname', 'address').to.deep.equal _.omit raw, 'registrations'

  it 'should dancer not save unallowed values', ->
    # when creating a dancer with unallowed attributes
    tested = new Dancer unallowed: 'toto'
    # then the attribute was not reported and the dancer created
    expect(tested).not.to.have.property 'unallowed'

  describe 'given an existing dancer', ->

    existing = null

    beforeEach (done) ->
      # given no dancer
      Dancer._cache = {}
      storage.removeAll Dancer, (err) ->
        return done err if err?
        # given a brand new dancer 
        existing = new Dancer 
          title: 'Mlle'
          firstname: 'Lucie'
          lastname: 'Grandjean'
          registrations: [
            planningId: 18
            danceClassIds: [1, 2]
          ]
        existing.save done

    it 'should dancer be found by id', (done) ->
      Dancer.find existing.id, (err, retrieved) =>
        return done "Failed to find existing dancer by id: #{err}" if err?
        expect(retrieved).to.exist
        expect(retrieved).to.be.an.instanceOf Dancer
        expect(retrieved.toJSON()).to.be.deep.equal existing.toJSON()
        done()

    it 'should findWhere() found within array', (done) ->
      # given two another dancers
      dancer1 = new Dancer firstname: 'Bob', registrations: [planningId: 18, danceClassIds: [3]]
      dancer1.save (err) ->
        return done "Failed to save first dancer: #{err}" if err?
        dancer2 = new Dancer firstname: 'Jack', registrations: [planningId: 18, danceClassIds: [1]]
        dancer2.save (err) ->
          return done "Failed to save second dancer: #{err}" if err?
          Dancer.findWhere {'registrations.danceClassIds': 1}, (err, dancers) =>
            return done "Failed to find existing dancer by class id: #{err}" if err?
            expect(dancers).to.exist
            expect(dancers).to.have.lengthOf 2
            expect(_.findWhere dancers, firstname: 'Jack').to.exist
            expect(_.findWhere dancers, firstname: 'Lucie').to.exist
            expect(_.findWhere dancers, firstname: 'Bob').not.to.exist
            done()

    it 'should findWhere() single value', (done) ->
      # given two another dancers
      dancer1 = new Dancer firstname: 'Bob', registrations: [planningId: 18, charged: 100, danceClassIds: [3]]
      dancer1.save (err) ->
        return done "Failed to save first dancer: #{err}" if err?
        dancer2 = new Dancer firstname: 'Jack', registrations: [planningId: 18, charged: 100, danceClassIds: [1]]
        dancer2.save (err) ->
          return done "Failed to save second dancer: #{err}" if err?
          Dancer.findWhere {'registrations.charged': 100}, (err, dancers) =>
            return done "Failed to find existing dancer by charge: #{err}" if err?
            expect(dancers).to.exist
            expect(dancers).to.have.lengthOf 2
            expect(_.findWhere dancers, firstname: 'Jack').to.exist
            expect(_.findWhere dancers, firstname: 'Bob').to.exist
            expect(_.findWhere dancers, firstname: 'Lucie').not.to.exist
            done()

    it 'should findWhere() use multiple conditions', (done) ->
      # given two another dancers
      dancer1 = new Dancer firstname: 'Bob', registrations: [planningId: 18, charged: 100, danceClassIds: [3]]
      dancer1.save (err) ->
        return done "Failed to save first dancer: #{err}" if err?
        dancer2 = new Dancer firstname: 'Jack', registrations: [planningId: 18, charged: 50, danceClassIds: [1]]
        dancer2.save (err) ->
          return done "Failed to save second dancer: #{err}" if err?
          Dancer.findWhere {'registrations.danceClassIds': 1, 'registrations.charged': 50}, (err, dancers) =>
            return done "Failed to find existing dancer by charge: #{err}" if err?
            expect(dancers).to.exist
            expect(dancers).to.have.lengthOf 1
            expect(_.findWhere dancers, firstname: 'Jack').to.exist
            expect(_.findWhere dancers, firstname: 'Bob').not.to.exist
            expect(_.findWhere dancers, firstname: 'Lucie').not.to.exist
            done()

    it 'should findWhere() resolve plannings and dance classes', (done) ->
      anthony = 'Anthony'
      diana = 'Diana'
      # given two plannings
      new Planning(id:18, season:'2012/2013', danceClasses: [
        new DanceClass id: 1, teacher: anthony
        new DanceClass id: 2, teacher: diana
        new DanceClass id: 3, teacher: diana
      ]).save (err) ->
        return done "Failed to save first planning: #{err}" if err?
        new Planning(id:19, season:'2013/2014', danceClasses: [
          new DanceClass id: 4, teacher: anthony
          new DanceClass id: 5, teacher: diana
        ]).save (err) ->
          return done "Failed to save second planning: #{err}" if err?
          # given two another dancers
          dancer1 = new Dancer firstname: 'Jack', registrations: [planningId: 18, danceClassIds: [3]]
          dancer1.save (err) ->
            return done "Failed to save first dancer: #{err}" if err?
            dancer2 = new Dancer firstname: 'Mitch', registrations: [planningId: 19, danceClassIds: [4]]
            dancer2.save (err) ->
              return done "Failed to save second dancer: #{err}" if err?
              Dancer.findWhere {'registrations.danceClasses.teacher': anthony, 'registrations.planning.season': '2012/2013'}, (err, dancers) =>
                return done "Failed to find existing dancer by teacher: #{err}" if err?
                expect(dancers).to.exist
                expect(dancers).to.have.lengthOf 1
                expect(_.findWhere dancers, firstname: 'Lucie').to.exist
                expect(_.findWhere dancers, firstname: 'Jack').not.to.exist
                expect(_.findWhere dancers, firstname: 'Mitch').not.to.exist
                done()