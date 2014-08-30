{expect} = require 'chai'
require('chai').use require 'chai-as-promised'
_ = require 'underscore'
moment = require 'moment'
{Promise} = require 'es6-promise'
Dancer = require '../../../app/script/model/dancer'
Address = require '../../../app/script/model/address'
Registration = require '../../../app/script/model/registration'
Payment = require '../../../app/script/model/payment'
DanceClass = require '../../../app/script/model/danceclass'
Card = require '../../../app/script/model/card'

describe 'Dancer model tests', ->

  beforeEach ->
    Promise.all [
      Card.drop()
      Dancer.drop()
      Address.drop()
      DanceClass.drop()
    ]
  
  it 'should new dancer be created with default values', ->
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
    expect(tested).to.have.property('address').that.eventually.be.null
    # then dance classes is an empty array
    expect(tested).to.have.property('danceClassIds').that.is.an('array').and.that.has.lengthOf 0
    expect(tested).to.have.property('danceClasses').that.eventually.be.an('array').and.that.has.lengthOf 0
    # then dancer's card is set to default
    expect(tested).to.have.property('cardId').that.is.null
    expect(tested).to.have.property('card').that.eventually.be.an.instanceOf Card
    expect()

  it 'should dancer save raw values', (done) ->
    season = '2013/2014'
    # givan a some address, registration, dance classes
    Promise.all([
      new Address(
        street: '15 place de la bourse'
        zipcode: 69100
        city: 'Villeurbanne'
        phone: '0401020304'
      ).save(),
      new Card(
        knownBy: ['searchEngine', 'elders']
      ).save(),
      new DanceClass(season: season, kind: 'salsa', teacher: 'Anthony').save(),
      new DanceClass(season: season, kind: 'ballroom', teacher: 'Diana').save()
    ]).then ([address, card, salsa, ballroom]) ->
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
        expect(tested).to.have.property('address').that.eventually.is.an.instanceOf(Address).and.that.equal address
        # then the registrations are available
        expect(tested).to.have.property('cardId').that.equal card.id
        expect(tested).to.have.property('card').that.eventually.is.an.instanceOf(Card).and.that.equal card
        # then the dance classes are available
        expect(tested).to.have.property('danceClassIds').that.deep.equal [salsa.id, ballroom.id]
        expect(tested).to.have.property('danceClasses').that.eventually.deep.equal [salsa, ballroom]
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
     
    beforeEach dancer.save

    it 'should dancer empty address be resolved at construction', (done) ->
      expect(dancer).to.have.property('addressId').that.is.null
      expect(dancer).to.have.property('address').that.eventually.is.null.notify done

    it 'should dancer addres be modified', (done) ->
      # given an address
      new Address(
        street: '15 place de la bourse'
        zipcode: 69100
        city: 'Villeurbanne'
      ).save().then (address) ->
        # when affecting this address to the dancer
        dancer.address = address
        # then the id was updated
        expect(dancer).to.have.property('addressId').that.equal address.id
        expect(dancer).to.have.property('address').that.eventually.equal(address).notify ->
          dancer.save().then ->
            # then address getter read from data base is consistent
            Dancer.find(dancer.id).then (result) ->
              expect(result).to.exist
              expect(result).to.have.property('addressId').that.equal address.id
              expect(result).to.have.property('address').that.eventually.satisfy((result) ->
                expect(result).to.be.an.instanceOf Address
                expect(result).to.have.property('id').that.equal address.id
              ).notify done

    it 'should dancer empty card be resolved at construction', (done) ->
      expect(dancer).to.have.property('cardId').that.is.null
      expect(dancer).to.have.property('card').that.eventually.is.an.instanceOf(Card).notify done

    it 'should dancer card be modified', (done) ->
      # given an registration
      new Card(
        knownBy: 'searchEngine'
      ).save().then (card) ->
        # when affecting this card to the dancer
        dancer.card = card
        # then the id was updated
        expect(dancer).to.have.property('cardId').that.equal card.id
        expect(dancer).to.have.property('card').that.eventually.equal(card).notify ->
          dancer.save().then ->
            # then address getter read from data base is consistent
            Dancer.find(dancer.id).then (result) ->
              expect(result).to.exist
              expect(result).to.have.property('cardId').that.equal card.id
              expect(result).to.have.property('card').that.eventually.satisfy((result) ->
                expect(result).to.be.an.instanceOf Card
                expect(result).to.have.property('id').that.equal card.id
              ).notify done

    it 'should dancer empty dance classes be resolved at construction', (done) ->
      expect(dancer).to.have.property('danceClassIds').that.has.lengthOf 0
      expect(dancer).to.have.property('danceClasses').that.eventually.has.lengthOf(0).notify done

    it 'should dancer dance classes be modified', (done) ->
      # given multiple dance classes
      Promise.all([
        new DanceClass(season: '2014/2015', kind: 'salsa', teacher: 'Anthony').save(),
        new DanceClass(season: '2013/2014', kind: 'ballroom', teacher: 'Diana').save(),
        new DanceClass(season: '2013/2014', kind: 'salsa', teacher: 'Anthony').save()
      ]).then((classes) ->
        # when affecting this classes to the dancer
        dancer.danceClasses = classes
        # then the id was updated
        expect(dancer).to.have.property('danceClassIds').that.deep.equal _.pluck classes, 'id'
        expect(dancer).to.have.property('danceClasses').that.eventually.deep.equal(classes).notify ->
          dancer.save().then ->
            # then address getter read from data base is consistent
            Dancer.find(dancer.id).then (result) ->
              expect(result).to.exist
              expect(result).to.have.property('danceClassIds').that.deep.equal _.pluck classes, 'id'
              expect(result).to.have.property('danceClasses').that.eventually.satisfy((results) ->
                i = 0
                for danceClass in results
                  expect(danceClass).to.be.an.instanceOf DanceClass
                  expect(danceClass).to.have.property('id').that.equal classes[i++].id
              ).notify done
      ).catch done

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
      Promise.all([salsa14.save(), salsa13.save(), batchata14.save(), ballroom14.save(), ballroom13.save(), 
        cardBobJack.save(), cardLucy.save(), addressBobJack.save(), addressLucy.save()
      ]).then( ->
        lucy.address = addressLucy
        lucy.danceClasses = [ballroom13, ballroom14, salsa14]
        lucy.card = cardLucy
        jack.address = addressBobJack
        jack.danceClasses = [salsa14]
        jack.card = cardBobJack
        bob.address = addressBobJack
        bob.danceClasses = [salsa13, salsa14, batchata14]
        bob.card = cardBobJack
        Promise.all([lucy.save(), bob.save(), jack.save()]).then ->
          console.log "lucy #{lucy.id}"
          console.log "bob #{bob.id}"
          console.log "jack #{jack.id}"
          console.log "cardBobJack #{cardBobJack.id}"
          console.log "cardLucy #{cardLucy.id}"
          console.log "addressBobJack #{addressBobJack.id}"
          console.log "addressLucy #{addressLucy.id}"
          done()
      ).catch done

    it 'should findWhere() resolve on dance classes', ->
      Dancer.findWhere('danceClassIds': $in: [batchata14.id]).then (dancers) ->
        expect(dancers).to.have.lengthOf 1
        expect(_.findWhere(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack was found').not.to.exist

    it 'should findWhere() resolve on dance classes', ->
      Dancer.findWhere('danceClasses.teacher': 'Anthony').then (dancers) ->
        expect(dancers).to.have.lengthOf 3
        expect(_.findWhere(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack not found').to.exist

    it 'should findWhere() resolve multiple criteria on dance classes', ->
      Dancer.findWhere('danceClasses.teacher': 'Anthony', 'danceClasses.season': '2013/2014').then (dancers) ->
        expect(dancers).to.have.lengthOf 1
        expect(_.findWhere(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack not found').not.to.exist

    it 'should findWhere() resolve on registrations', ->
      Dancer.findWhere('card.registrations.charged': 200).then (dancers) ->
        expect(dancers).to.have.lengthOf 3
        expect(_.findWhere(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack not found').to.exist

    it 'should findWhere() resolve multiple criteria on on registrations', ->
      Dancer.findWhere('card.registrations.charged': 200, 'card.registrations.period': 'quarter').then (dancers) ->
        expect(dancers).to.have.lengthOf 2
        expect(_.findWhere(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack not found').to.exist

    it 'should findWhere() resolve registrations and dance classes', ->
      Dancer.findWhere('card.registrations.charged': 200, 'danceClasses.kind': 'ballroom').then (dancers) ->
        expect(dancers).to.have.lengthOf 1
        expect(_.findWhere(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob was found').not.to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack was found').not.to.exist

    it 'should findWhere() resolve on address', ->
      Dancer.findWhere('address.city': 'Lyon').then (dancers) ->
        expect(dancers).to.have.lengthOf 2
        expect(_.findWhere(dancers, id: lucy.id), 'lucy was found').not.to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob not found').to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack not found').to.exist

    it 'should findWhere() resolve multiple criteria on on address', ->
      Dancer.findWhere('address.city': {$in: ['Lyon', 'Villeurbanne']}, 'address.street': $regex: /Zola/).then (dancers) ->
        expect(dancers).to.have.lengthOf 1
        expect(_.findWhere(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob was found').not.to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack was found').not.to.exist

    it 'should findWhere() resolve address, registrations and dance classes', ->
      Dancer.findWhere(
        'danceClasses.teacher': 'Anthony'
        'card.registrations.season': '2013/2014' 
        'address.city': 'Villeurbanne'
      ).then (dancers) ->
        expect(dancers).to.have.lengthOf 1
        expect(_.findWhere(dancers, id: lucy.id), 'lucy not found').to.exist
        expect(_.findWhere(dancers, id: bob.id), 'bob was found').not.to.exist
        expect(_.findWhere(dancers, id: jack.id), 'jack was found').not.to.exist