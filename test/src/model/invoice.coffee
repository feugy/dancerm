{expect} = require 'chai'
_ = require 'lodash'
async = require 'async'
moment = require 'moment'
{currentSeason} = require '../../../app/script/util/common'
{init} = require '../../../app/script/model/tools/initializer'
Invoice = require '../../../app/script/model/invoice'
InvoiceItem = require '../../../app/script/model/invoice_item'
Dancer = require '../../../app/script/model/dancer'
DanceClass = require '../../../app/script/model/dance_class'
Address = require '../../../app/script/model/address'
Registration = require '../../../app/script/model/registration'
Payment = require '../../../app/script/model/payment'
Card = require '../../../app/script/model/card'

describe 'Invoice  model tests', ->

  card = new Card registrations: [new Registration()]

  dancer1 = new Dancer
    title: 'M.'
    firstname: 'Jean'
    lastname: 'Dupond'

  dancer2 = new Dancer
    title: 'Mme.'
    firstname: 'Julie'
    lastname: 'Durand'

  address1 = new Address
    street: '1 cours Emile Zola'
    zipcode: 69100
    city: 'Villeurbanne'

  danceClass1 = new DanceClass
    kind: 'Salsa Rock'
    level: 'débutants'
    start: 'Mon 17:00'
    end: 'Mon 18:00'

  before (done) ->
    init (err) ->
      return done err if err?
      card.save (err) ->
        return done err if err?
        address1.save (err) ->
          return done err if err?
          dancer1.setAddress address1
          dancer1.setCard card,
          dancer2.setCard card
          async.each [dancer1, dancer2, danceClass1], ((model, next) -> model.save next), done

  it 'should new invoice be created with default values', (done) ->
    # when creating an invoice without values
    tested = new Invoice()
    # then an id was set
    expect(tested).to.have.property('id').that.is.null
    # then the application and due date were set
    expect(tested).to.have.property 'date'
    expect(tested.date.valueOf()).to.be.closeTo moment().valueOf(), 500
    expect(tested).to.have.property 'dueDate'
    expect(tested.dueDate.valueOf()).to.be.closeTo moment().add(60, 'days').valueOf(), 500
    # then default values were set
    expect(tested).to.have.property('ref').that.is.null
    expect(tested).to.have.deep.property('customer.name').that.is.empty
    expect(tested).to.have.deep.property('customer.street').that.is.empty
    expect(tested).to.have.deep.property('customer.zipcode').that.is.empty
    expect(tested).to.have.deep.property('customer.city').that.is.empty
    expect(tested).to.have.property('items').that.is.empty
    expect(tested).to.have.property('discount').that.equals 0
    expect(tested).to.have.property('delayFee').that.equals 0
    expect(tested).to.have.property('sent').that.is.null
    expect(tested).to.have.property('cardId').that.is.null
    done()

  it 'should invoice save raw values', (done) ->
    raw =
      ref: '2016-01-001'
      date: '2016-01-01'
      customer:
        name: 'Mlle. Jeanne Dou'
        stret: '10 rue du pont',
        zipcode: 69001
        city: 'Lyon'
      discount: 10
      delayFee: 5
      items: [
        new InvoiceItem
          name: "#{danceClass1.kind} #{danceClass1.level} #{danceClass1.start}"
          price: 50
          dancerIds: [dancer1.id]
          danceClassId: danceClass1.id
      ]
      cardId: card.id
    tested = new Invoice _.clone raw

    expect(tested).to.have.property('id').that.is.null
    expect(tested).to.have.property 'date'
    expect(tested.date.valueOf()).to.be.closeTo moment(raw.date).valueOf(), 500
    expect(tested).to.have.property 'dueDate'
    expect(tested.dueDate.valueOf()).to.be.closeTo moment(raw.date).add(60, 'days').valueOf(), 500
    expect(tested).to.have.property('ref').that.equals raw.ref
    expect(tested).to.have.property('customer').that.deep.equals raw.customer
    expect(tested).to.have.property('items').that.has.lengthOf 1
    item = tested.items[0]
    expect(item).to.be.an.instanceOf InvoiceItem
    expect(item).to.have.property('name').that.equals raw.items[0].name
    expect(item).to.have.property('price').that.equals raw.items[0].price
    expect(item).to.have.property('quantity').that.equals 1
    expect(item).to.have.property('discount').that.equals 0
    expect(item).to.have.property('vat').that.equals 0
    expect(item).to.have.property('dancerIds').that.deep.equals raw.items[0].dancerIds
    expect(item).to.have.property('danceClassId').that.equals raw.items[0].danceClassId
    expect(tested).to.have.property('discount').that.equals raw.discount
    expect(tested).to.have.property('delayFee').that.equals raw.delayFee
    expect(tested).to.have.property('sent').that.is.null
    expect(tested).to.have.property('cardId').that.equals raw.cardId

    tested.save (err) ->
      return done err if err?
      expect(tested).to.have.property('id').that.exist
      expect(tested).to.have.property('_v').that.exist
      expect(tested).to.have.property('items').that.has.lengthOf 1
      item = tested.items[0]
      expect(item).to.be.an.instanceOf InvoiceItem
      expect(item).to.have.property('name').that.equals raw.items[0].name
      expect(item).to.have.property('price').that.equals raw.items[0].price
      expect(item).to.have.property('quantity').that.equals 1
      expect(item).to.have.property('discount').that.equals 0
      expect(item).to.have.property('vat').that.equals 0
      expect(item).to.have.property('dancerIds').that.deep.equals raw.items[0].dancerIds
      expect(item).to.have.property('danceClassId').that.equals raw.items[0].danceClassId
      done()

  it 'should set customer details from dancer', (done) ->
    tested = new Invoice
      customer:
        name: 'Mlle. Jeanne Dou'
        street: '10 rue du pont',
        zipcode: 69001
        city: 'Lyon'

    tested.setCustomer dancer1, (err) ->
      return done err if err?
      expect(tested).to.have.deep.property('customer.name').that.equals 'M. Jean Dupond'
      expect(tested).to.have.deep.property('customer.street').that.equals address1.street
      expect(tested).to.have.deep.property('customer.city').that.equals address1.city
      expect(tested).to.have.deep.property('customer.zipcode').that.equals address1.zipcode
      done()

  it 'should not erase address if new customer hasn\'t one', (done) ->
    raw =
      customer:
        name: 'Mlle. Jeanne Dou'
        street: '10 rue du pont',
        zipcode: 69001
        city: 'Lyon'
    tested = new Invoice _.clone raw

    tested.setCustomer dancer2, (err) ->
      return done err if err?
      expect(tested).to.have.deep.property('customer.name').that.equals 'Mme. Julie Durand'
      expect(tested).to.have.deep.property('customer.street').that.equals raw.customer.street
      expect(tested).to.have.deep.property('customer.city').that.equals raw.customer.city
      expect(tested).to.have.deep.property('customer.zipcode').that.equals raw.customer.zipcode
      done()