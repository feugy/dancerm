{expect} = require 'chai'
async = require 'async'
_ = require 'lodash'
moment = require 'moment'
{init} = require '../../../app/script/model/tools/initializer'
Dancer = require '../../../app/script/model/dancer'
Address = require '../../../app/script/model/address'
Registration = require '../../../app/script/model/registration'
Payment = require '../../../app/script/model/payment'
DanceClass = require '../../../app/script/model/dance_class'
Card = require '../../../app/script/model/card'

describe 'Dancer model tests', ->

  before init

  beforeEach (done) ->
    async.each [Card, Address, Dancer, DanceClass], (clazz, next) ->
      clazz.drop next
    , done

  it 'should new dancer be created with default values', (done) ->
    # when creating a dancer without values
    tested = new Dancer()
    # then an id was set
    expect(tested).to.have.property('id').that.is.null
    # then the creation date was set
    expect(tested).to.have.property 'created'
    expect(tested.created.valueOf()).to.be.closeTo moment().valueOf(), 500
    # then default values were set
    expect(tested).to.have.property('title').that.is.null
    expect(tested).to.have.property('firstname').that.is.null
    expect(tested).to.have.property('lastname').that.is.null
    expect(tested).to.have.property('cellphone').that.is.null
    expect(tested).to.have.property('email').that.is.null
    expect(tested).to.have.property('birth').that.is.null
    # then dancer's address is empty
    expect(tested).to.have.property('addressId').that.is.null
    tested.getAddress (err, addr) ->
      return done err if err?
      expect(addr).to.be.null
      # then dance classes is an empty array
      expect(tested).to.have.property('danceClassIds').that.is.an('array').and.that.has.lengthOf 0
      tested.getClasses (err, classes) ->
        return done err if err?
        expect(classes).to.be.an('array').that.has.lengthOf 0
        # then dancer's card is set to default
        expect(tested).to.have.property('cardId').that.is.null
        tested.getCard (err, card) ->
          return done err if err?
          expect(card).to.be.an.instanceOf Card
          done()

  it 'should dancer save raw values', (done) ->
    season = '2013/2014'
    # givan a some address, registration, dance classes
    async.map [
      new Address street: '15 place de la bourse', zipcode: 69100, city: 'Villeurbanne', phone: '0401020304'
      new Card knownBy: ['searchEngine', 'elders']
      new DanceClass season: season, kind: 'salsa', teacher: 'Anthony'
      new DanceClass season: season, kind: 'ballroom', teacher: 'Diana'
    ], (model, next) ->
      model.save next
    , (err, [address, card, salsa, ballroom]) ->
      return done err if err?
      # given a raw dancer
      raw =
        created: moment().toJSON()
        title: 'M.'
        firstname: 'Jean'
        lastname: 'Dujardin'
        cellphone: '0601020304'
        email: 'jean.dujardin@yopmail.com'
        birth: '1980-05-24'
        addressId: address.id
        cardId: card.id
        danceClassIds: [salsa.id, ballroom.id]

      # when creating a dancer with a clone to avoid modifications
      tested = new Dancer _.clone raw
      # then all defined attributes have been saved
      expect(tested).to.have.property 'id'
      # the personnal fields are available
      expect(tested).to.have.property('title').that.equal 'M.'
      expect(tested).to.have.property('firstname').that.equal 'Jean'
      expect(tested).to.have.property('lastname').that.equal 'Dujardin'
      expect(tested).to.have.property('cellphone').that.equal '0601020304'
      expect(tested).to.have.property('email').that.equal 'jean.dujardin@yopmail.com'
      expect(tested).to.have.property('birth').that.satisfy (b) -> moment.isMoment(b) and b.isSame '1980-05-24'
      # then address containing relevant fields
      expect(tested).to.have.property('addressId').that.equal address.id
      tested.getAddress (err, addr) ->
        return done err if err?
        expect(addr.toJSON()).to.deep.equal address.toJSON()
        # then the dance classes are available
        expect(tested).to.have.property('danceClassIds').that.deep.equal [salsa.id, ballroom.id]
        tested.getClasses (err, classes) ->
          return done err if err?
          expect(_.invoke classes, 'toJSON').to.deep.equal _.invoke [salsa, ballroom], 'toJSON'
          # then the registrations are available
          expect(tested).to.have.property('cardId').that.equal card.id
          tested.getCard (err, card) ->
            return done err if err?
            expect(card.toJSON()).to.deep.equal card.toJSON()
            done()

  it 'should dancer not save unallowed values', ->
    # when creating a dancer with unallowed attributes
    tested = new Dancer unallowed: 'toto'
    # then the attribute was not reported and the dancer created
    expect(tested).not.to.have.property 'unallowed'

  describe 'given a dancer without address, card or dance classes', ->

    dancer = new Dancer
      title: 'Mlle.'
      firstname: 'Lucy'
      lastname: 'Grandjean'

    beforeEach (done) -> dancer.save done

    it 'should dancer empty address be resolved at construction', (done) ->
      expect(dancer).to.have.property('addressId').that.is.null
      dancer.getAddress (err, addr) ->
        return done err if err?
        expect(addr).to.be.null
        done()

    it 'should dancer address be modified', (done) ->
      # given an address
      new Address(
        street: '15 place de la bourse'
        zipcode: 69100
        city: 'Villeurbanne'
      ).save (err, address) ->
        return done err if err?
        # when affecting this address to the dancer
        dancer.setAddress address
        # then the id was updated
        expect(dancer).to.have.property('addressId').that.equal address.id
        dancer.getAddress (err, addr) ->
          return done err if err?
          expect(addr).that.equal address
          dancer.save (err) ->
            return done err if err?
            # then address getter read from data base is consistent
            Dancer.find dancer.id, (err, result) ->
              return done err if err?
              expect(result).to.exist
              expect(result).to.have.property('addressId').that.equal address.id
              result.getAddress (err, addr) ->
                return done err if err?
                expect(addr).to.be.an.instanceOf Address
                expect(addr).to.have.property('id').that.equal address.id
                done()

    it 'should dancer empty card be resolved at construction', (done) ->
      expect(dancer).to.have.property('cardId').that.is.null
      dancer.getCard (err, card) ->
        return done err if err?
        expect(card).to.be.an.instanceOf Card
        done()

    it 'should dancer card be modified', (done) ->
      # given an registration
      new Card(
        knownBy: 'searchEngine'
      ).save (err, card) ->
        return done err if err?
        # when affecting this card to the dancer
        dancer.setCard card
        # then the id was updated
        expect(dancer).to.have.property('cardId').that.equal card.id
        dancer.getCard (err) ->
          return done err if err?
          dancer.save (err) ->
            return done err if err?
            # then address getter read from data base is consistent
            Dancer.find dancer.id, (err, result) ->
              return done err if err?
              expect(result).to.exist
              expect(result).to.have.property('cardId').that.equal card.id
              result.getCard (err, result) ->
                return done err if err?
                expect(result).to.be.an.instanceOf Card
                expect(result).to.have.property('id').that.equal card.id
                done()

    it 'should dancer empty dance classes be resolved at construction', (done) ->
      expect(dancer).to.have.property('danceClassIds').that.has.lengthOf 0
      dancer.getClasses (err, danceClasses) ->
        return done err if err?
        expect(danceClasses).to.have.lengthOf 0
        done()

    it 'should dancer dance classes be modified', (done) ->
      # given multiple dance classes
      async.map [
        new DanceClass season: '2014/2015', kind: 'salsa', teacher: 'Anthony'
        new DanceClass season: '2013/2014', kind: 'ballroom', teacher: 'Diana'
        new DanceClass season: '2013/2014', kind: 'salsa', teacher: 'Anthony'
      ], (model, next) ->
        model.save next
      , (err, classes) ->
        return done err if err?
        # when affecting this classes to the dancer
        dancer.setClasses classes
        # then the id was updated
        expect(dancer).to.have.property('danceClassIds').that.deep.equal _.map classes, 'id'
        dancer.getClasses (err, danceClasses) ->
          return done err if err?
          expect(danceClasses).to.deep.equal classes
          dancer.save (err) ->
            return done err if err?
            # then address getter read from data base is consistent
            Dancer.find dancer.id, (err, result) ->
              return done err if err?
              expect(result).to.exist
              expect(result).to.have.property('danceClassIds').that.deep.equal _.map classes, 'id'
              result.getClasses (err, results) ->
                return done err if err?
                i = 0
                for danceClass in results
                  expect(danceClass).to.be.an.instanceOf DanceClass
                  expect(danceClass).to.have.property('id').that.equal classes[i++].id
                done()

  describe 'given some dancers, card, classes and registrations', ->

    lucy = new Dancer title: 'Mlle.', firstname: 'Lucy', lastname: 'Grandjean'
    bob = new Dancer title: 'M.', firstname: 'Bob', lastname: 'Marchant'
    jack = new Dancer title: 'M.', firstname: 'Jack', lastname: 'Marchant'
    salsa14 = new DanceClass season: '2014/2015', kind: 'salsa', teacher: 'Anthony'
    salsa13 = new DanceClass season: '2013/2014', kind: 'salsa', teacher: 'Anthony'
    batchata14 = new DanceClass season: '2014/2015', kind: 'batchata', teacher: 'Anthony'
    ballroom14 = new DanceClass season: '2014/2015', kind: 'ballroom', teacher: 'Diana'
    ballroom13 = new DanceClass season: '2013/2014', kind: 'ballroom', teacher: 'Diana'
    cardBobJack = new Card registrations: [
      new Registration season: '2014/2015', charged: 600
      new Registration season: '2013/2014', charged: 200, period: 'quarter'
    ]
    cardLucy = new Card registrations: [
      new Registration season: '2014/2015', charged: 400
      new Registration season: '2013/2014', charged: 200
    ]
    addressBobJack = new Address city: 'Lyon', street: 'rue Bellecour', zipcode: '69001'
    addressLucy = new Address city: 'Villeurbanne', street: 'cours Emile Zola', zipcode: '69100'

    beforeEach (done) ->
      async.each [salsa14 ,salsa13, batchata14, ballroom14, ballroom13,
        cardBobJack, cardLucy, addressBobJack, addressLucy
      ], (model, next) ->
        model.save next
      , (err) ->
        return done err if err?
        lucy.setAddress addressLucy
        lucy.setClasses [ballroom13, ballroom14, salsa14]
        lucy.setCard cardLucy
        jack.setAddress addressBobJack
        jack.setClasses [salsa14]
        jack.setCard cardBobJack
        bob.setAddress addressBobJack
        bob.setClasses [salsa13, salsa14, batchata14]
        bob.setCard cardBobJack
        async.each [lucy, bob, jack], (model, next) ->
          model.save next
        , done

    it 'should findWhere() resolve on dance classes id', (done) ->
      Dancer.findWhere {danceClassIds: $in: [batchata14.id]}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 1
        expect(_.find(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.find(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.find(dancers, id: jack.id), 'jack was found').not.to.exist
        done()

    it 'should findWhere() resolve on dance classes teacher', (done) ->
      Dancer.findWhere {'danceClasses.teacher': 'Anthony'}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 3
        expect(_.find(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.find(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.find(dancers, id: jack.id), 'jack not found').to.exist
        done()

    it 'should findWhere() resolve multiple criteria on dance classes', (done) ->
      Dancer.findWhere {'danceClasses.teacher': 'Anthony', 'danceClasses.season': '2013/2014'}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 1
        expect(_.find(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.find(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.find(dancers, id: jack.id), 'jack not found').not.to.exist
        done()

    it 'should findWhere() resolve on registrations', (done) ->
      Dancer.findWhere {'card.registrations.charged': 200}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 3
        expect(_.find(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.find(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.find(dancers, id: jack.id), 'jack not found').to.exist
        done()

    it 'should findWhere() resolve multiple criteria on registrations', (done) ->
      Dancer.findWhere {'card.registrations.charged': 200, 'card.registrations.period': 'quarter'}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 2
        expect(_.find(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.find(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.find(dancers, id: jack.id), 'jack not found').to.exist
        done()

    it 'should findWhere() resolve registrations and dance classes', (done) ->
      Dancer.findWhere {'card.registrations.charged': 200, 'danceClasses.kind': 'ballroom'}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 1
        expect(_.find(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.find(dancers, id: bob.id), 'bob was found').not.to.exist
        expect(_.find(dancers, id: jack.id), 'jack was found').not.to.exist
        done()

    it 'should findWhere() resolve on address', (done) ->
      Dancer.findWhere {'address.city': 'Lyon'}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 2
        expect(_.find(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.find(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.find(dancers, id: jack.id), 'jack not found').to.exist
        done()

    it 'should findWhere() resolve multiple criteria on address', (done) ->
      Dancer.findWhere {'address.city': {$in: ['Lyon', 'Villeurbanne']}, 'address.street': /Zola/}, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 1
        expect(_.find(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.find(dancers, id: bob.id), 'bob was found').not.to.exist
        expect(_.find(dancers, id: jack.id), 'jack was found').not.to.exist
        done()

    it 'should findWhere() resolve address, registrations and dance classes', (done) ->
      Dancer.findWhere {
        'danceClasses.teacher': 'Anthony'
        'card.registrations.season': '2013/2014'
        'address.city': 'Villeurbanne'
      }, (err, dancers) ->
        return done err if err?
        expect(dancers).to.have.lengthOf 1
        expect(_.find(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.find(dancers, id: bob.id), 'bob was found').not.to.exist
        expect(_.find(dancers, id: jack.id), 'jack was found').not.to.exist
        done()