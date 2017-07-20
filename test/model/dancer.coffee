assert = require 'power-assert'
async = require 'async'
_ = require 'lodash'
moment = require 'moment'
{init} = require '../../app/src/model/tools/initializer'
Dancer = require '../../app/src/model/dancer'
Address = require '../../app/src/model/address'
Registration = require '../../app/src/model/registration'
Payment = require '../../app/src/model/payment'
DanceClass = require '../../app/src/model/dance_class'
Card = require '../../app/src/model/card'

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
    assert tested.id is null
    # then the creation date was set
    assert tested.created
    assert tested.created.isSame moment(), 'second'
    # then default values were set
    assert tested.title is null
    assert tested.firstname is null
    assert tested.lastname is null
    assert tested.cellphone is null
    assert tested.email is null
    assert tested.birth is null
    # then dancer's address is empty
    assert tested.addressId is null
    tested.getAddress (err, addr) ->
      return done err if err?
      assert addr is null
      # then dance classes is an empty array
      assert tested.danceClassIds.length is 0
      tested.getClasses (err, classes) ->
        return done err if err?
        assert classes.length is 0
        # then dancer's card is set to default
        assert tested.cardId is null
        tested.getCard (err, card) ->
          return done err if err?
          assert card instanceof Card
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
      assert tested.id is null
      # the personnal fields are available
      assert tested.title is 'M.'
      assert tested.firstname is 'Jean'
      assert tested.lastname is 'Dujardin'
      assert tested.cellphone is '0601020304'
      assert tested.email is 'jean.dujardin@yopmail.com'
      assert tested.birth.isSame '1980-05-24'
      # then address containing relevant fields
      assert tested.addressId is address.id
      tested.getAddress (err, addr) ->
        return done err if err?
        assert.deepStrictEqual addr.toJSON(), address.toJSON()
        # then the dance classes are available
        assert.deepStrictEqual tested.danceClassIds, [salsa.id, ballroom.id]
        tested.getClasses (err, classes) ->
          return done err if err?
          assert.deepStrictEqual _.invoke(classes, 'toJSON'), _.invoke [salsa, ballroom], 'toJSON'
          # then the registrations are available
          assert tested.cardId is card.id
          tested.getCard (err, card) ->
            return done err if err?
            assert.deepStrictEqual card.toJSON(), card.toJSON()
            done()

  it 'should dancer not save unallowed values', (done) ->
    # when creating a dancer with unallowed attributes
    tested = new Dancer unallowed: 'toto'
    # then the attribute was not reported and the dancer created
    assert not tested.unallowed?
    done()

  describe 'given a dancer without address, card or dance classes', ->

    dancer = new Dancer
      title: 'Mlle.'
      firstname: 'Lucy'
      lastname: 'Grandjean'

    beforeEach (done) -> dancer.save done

    it 'should dancer empty address be resolved at construction', (done) ->
      assert dancer.addressId is null
      dancer.getAddress (err, addr) ->
        return done err if err?
        assert addr is null
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
        assert dancer.addressId is address.id
        dancer.getAddress (err, addr) ->
          return done err if err?
          assert addr is address
          dancer.save (err) ->
            return done err if err?
            # then address getter read from data base is consistent
            Dancer.find dancer.id, (err, result) ->
              return done err if err?
              assert result?
              assert result.addressId is address.id
              result.getAddress (err, addr) ->
                return done err if err?
                assert addr instanceof Address
                assert addr.id is address.id
                done()

    it 'should dancer empty card be resolved at construction', (done) ->
      assert dancer.cardId is null
      dancer.getCard (err, card) ->
        return done err if err?
        assert card instanceof Card
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
        assert dancer.cardId is card.id
        dancer.getCard (err) ->
          return done err if err?
          dancer.save (err) ->
            return done err if err?
            # then address getter read from data base is consistent
            Dancer.find dancer.id, (err, result) ->
              return done err if err?
              assert result?
              assert result.cardId is card.id
              result.getCard (err, result) ->
                return done err if err?
                assert result instanceof Card
                assert result.id is card.id
                done()

    it 'should dancer empty dance classes be resolved at construction', (done) ->
      assert dancer.danceClassIds.length is 0
      dancer.getClasses (err, danceClasses) ->
        return done err if err?
        assert danceClasses.length is 0
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
        assert.deepStrictEqual dancer.danceClassIds, _.map classes, 'id'
        dancer.getClasses (err, danceClasses) ->
          return done err if err?
          assert.deepStrictEqual danceClasses, classes
          dancer.save (err) ->
            return done err if err?
            # then address getter read from data base is consistent
            Dancer.find dancer.id, (err, result) ->
              return done err if err?
              assert result?
              assert.deepStrictEqual result.danceClassIds, _.map classes, 'id'
              result.getClasses (err, results) ->
                return done err if err?
                i = 0
                for danceClass in results
                  assert danceClass instanceof DanceClass
                  assert danceClass.id is classes[i++].id
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
        assert dancers.length is 1
        assert not _.find(dancers, id: lucy.id)?, 'lucy was found'
        assert _.find(dancers, id: bob.id)?, 'bob not found'
        assert not _.find(dancers, id: jack.id)?, 'jack was found'
        done()

    it 'should findWhere() resolve on dance classes teacher', (done) ->
      Dancer.findWhere {'danceClasses.teacher': 'Anthony'}, (err, dancers) ->
        return done err if err?
        assert dancers.length is 3
        assert _.find(dancers, id: lucy.id)?, 'lucy not found'
        assert _.find(dancers, id: bob.id)?, 'bob not found'
        assert _.find(dancers, id: jack.id)?, 'jack not found'
        done()

    it 'should findWhere() resolve multiple criteria on dance classes', (done) ->
      Dancer.findWhere {'danceClasses.teacher': 'Anthony', 'danceClasses.season': '2013/2014'}, (err, dancers) ->
        return done err if err?
        assert dancers.length is 1
        assert not _.find(dancers, id: lucy.id)?, 'lucy was found'
        assert _.find(dancers, id: bob.id)?, 'bob not found'
        assert not _.find(dancers, id: jack.id)?, 'jack not found'
        done()

    it 'should findWhere() resolve on registrations', (done) ->
      Dancer.findWhere {'card.registrations.charged': 200}, (err, dancers) ->
        return done err if err?
        assert dancers.length is 3
        assert _.find(dancers, id: lucy.id)?, 'lucy not found'
        assert _.find(dancers, id: bob.id)?, 'bob not found'
        assert _.find(dancers, id: jack.id)?, 'jack not found'
        done()

    it 'should findWhere() resolve multiple criteria on registrations', (done) ->
      Dancer.findWhere {'card.registrations.charged': 200, 'card.registrations.period': 'quarter'}, (err, dancers) ->
        return done err if err?
        assert dancers.length is 2
        assert not _.find(dancers, id: lucy.id)?, 'lucy was found'
        assert _.find(dancers, id: bob.id)?, 'bob not found'
        assert _.find(dancers, id: jack.id)?, 'jack not found'
        done()

    it 'should findWhere() resolve registrations and dance classes', (done) ->
      Dancer.findWhere {'card.registrations.charged': 200, 'danceClasses.kind': 'ballroom'}, (err, dancers) ->
        return done err if err?
        assert dancers.length is 1
        assert _.find(dancers, id: lucy.id)?, 'lucy not found'
        assert not _.find(dancers, id: bob.id)?, 'bob was found'
        assert not _.find(dancers, id: jack.id)?, 'jack was found'
        done()

    it 'should findWhere() resolve on address', (done) ->
      Dancer.findWhere {'address.city': 'Lyon'}, (err, dancers) ->
        return done err if err?
        assert dancers.length is 2
        assert not _.find(dancers, id: lucy.id)?, 'lucy was found'
        assert _.find(dancers, id: bob.id)?, 'bob not found'
        assert _.find(dancers, id: jack.id)?, 'jack not found'
        done()

    it 'should findWhere() resolve multiple criteria on address', (done) ->
      Dancer.findWhere {'address.city': {$in: ['Lyon', 'Villeurbanne']}, 'address.street': /Zola/}, (err, dancers) ->
        return done err if err?
        assert dancers.length is 1
        assert _.find(dancers, id: lucy.id)?, 'lucy not found'
        assert not _.find(dancers, id: bob.id)?, 'bob was found'
        assert not _.find(dancers, id: jack.id)?, 'jack was found'
        done()

    it 'should findWhere() resolve address, registrations and dance classes', (done) ->
      Dancer.findWhere {
        'danceClasses.teacher': 'Anthony'
        'card.registrations.season': '2013/2014'
        'address.city': 'Villeurbanne'
      }, (err, dancers) ->
        return done err if err?
        assert dancers.length is 1
        assert _.find(dancers, id: lucy.id)?, 'lucy not found'
        assert not _.find(dancers, id: bob.id)?, 'bob was found'
        assert not _.find(dancers, id: jack.id)?, 'jack was found'
        done()