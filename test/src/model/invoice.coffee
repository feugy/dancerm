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
Persisted = require '../../../app/script/model/tools/persisted'

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
    tested = new Invoice ref: '2016-02-001'
    # then an id was set
    expect(tested).to.have.property('id').that.is.null
    # then the application and due date were set
    expect(tested).to.have.property 'date'
    expect(tested.date.valueOf()).to.be.closeTo moment().valueOf(), 500
    expect(tested).to.have.property 'dueDate'
    expect(tested.dueDate.valueOf()).to.be.closeTo moment().add(60, 'days').valueOf(), 500
    # then default values were set
    expect(tested).to.have.property('ref').that.equals '2016-02-001'
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
      ref: '2016-01-003'
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
      ref: '2016-01-004'
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

  describe 'given a set of existing references', () ->

    refs = [
      '2016-08-001'
      '2016-08-002'
      '2016-07-001'
      '2016-07-003'
      '2016-07-010'
      '2016-07-1000'
      'FR-2016-COL-06-JAZZ-10 custom'
      '2016-05-unparseable'
      '2016-05-89-90'
      '2016-unparseable-90'
    ]

    before (done) ->
      Invoice.drop (err) ->
        return done err if err?
        async.each refs, ((ref, next) ->
          invoice = new Invoice(ref: ref)
          # disabled ref checks for test invoices
          invoice.save = Persisted::save
          invoice.save next
        ), done

    after (done) -> Invoice.drop done

    it 'should check that null refs are invalid', (done) ->
      Invoice.isRefValid null, (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.false
        done()

    it 'should check that undefined refs are invalid', (done) ->
      Invoice.isRefValid undefined, (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.false
        done()

    it 'should check that numerical refs are invalid', (done) ->
      Invoice.isRefValid 18, (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.false
        done()

    it 'should check that refs without 4-digit year are invalid', (done) ->
      Invoice.isRefValid '16-05-001', (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.false
        done()

    it 'should check that refs without 2-digit month are invalid', (done) ->
      Invoice.isRefValid '2016-5-001', (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.false
        done()

    it 'should check that refs without rank month are invalid', (done) ->
      Invoice.isRefValid '2016-01', (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.false
        done()

    it 'should check that existing refs are invalid', (done) ->
      Invoice.isRefValid '2016-07-001', (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.false
        done()

    it 'should accept valid references formats', (done) ->
      Invoice.isRefValid '2017-07-001', (err, isValid) ->
        return done err if err?
        expect(isValid).to.be.true
        done()

    it 'should get reference for an empty month', (done) ->
      Invoice.getNextRef 2016, 9, (err, ref) ->
        return done err if err?
        expect(ref).to.equals '2016-09-001'
        done()

    it 'should get next reference for month with existing refs', (done) ->
      Invoice.getNextRef 2016, 8, (err, ref) ->
        return done err if err?
        expect(ref).to.equals '2016-08-003'
        done()

    it 'should get next reference for month with more than 999 refs', (done) ->
      Invoice.getNextRef 2016, 7, (err, ref) ->
        return done err if err?
        expect(ref).to.equals '2016-07-1001'
        done()

    it 'should ignore extra words when getting next reference', (done) ->
      Invoice.getNextRef 2016, 6, (err, ref) ->
        return done err if err?
        expect(ref).to.equals '2016-06-011'
        done()

    it 'should ignore unparseable refs when getting next reference', (done) ->
      Invoice.getNextRef 2016, 5, (err, ref) ->
        return done err if err?
        expect(ref).to.equals '2016-05-090'
        done()

    it 'should check ref validity when saving new invoice', (done) ->
      saved = new Invoice ref: '2016-08-001'
      saved.save (err) ->
        expect(err).to.exist
        expect(err).to.have.property('message').that.includes 'misformated or already used'
        done()

    it 'should can save the with the same ref', (done) ->
      saved = new Invoice ref: '2016-08-003'
      saved.save (err) ->
        return done err if err?
        saved.save (err) ->
          expect(err).not.to.exist
          done()