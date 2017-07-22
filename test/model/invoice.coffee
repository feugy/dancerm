assert = require 'power-assert'
_ = require 'lodash'
async = require 'async'
moment = require 'moment'
{currentSeason} = require '../../app/src/util/common'
{init} = require '../../app/src/model/tools/initializer'
Invoice = require '../../app/src/model/invoice'
InvoiceItem = require '../../app/src/model/invoice_item'
Dancer = require '../../app/src/model/dancer'
DanceClass = require '../../app/src/model/dance_class'
Address = require '../../app/src/model/address'
Registration = require '../../app/src/model/registration'
Payment = require '../../app/src/model/payment'
Card = require '../../app/src/model/card'
Persisted = require '../../app/src/model/tools/persisted'

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
    assert tested.id is null
    # then the application and due date were set
    assert tested.date?
    assert tested.date.isSame moment(), 'second'
    assert tested.dueDate?
    assert tested.dueDate.isSame moment().add(60, 'days'), 'second'
    # then default values were set
    assert tested.ref is '2016-02-001'
    assert tested.customer.name is ''
    assert tested.customer.street is ''
    assert tested.customer.zipcode is ''
    assert tested.customer.city is ''
    assert.deepStrictEqual tested.items, []
    assert tested.discount is 0
    assert tested.delayFee is 5
    assert tested.sent is null
    assert tested.cardId is null
    assert tested.season is null
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
      delayFee: 7
      items: [
        new InvoiceItem
          name: "#{danceClass1.kind} #{danceClass1.level} #{danceClass1.start}"
          price: 50
          dancerIds: [dancer1.id]
          danceClassId: danceClass1.id
      ]
      cardId: card.id
    tested = new Invoice _.clone raw

    assert tested.id is null
    assert tested.date?
    assert tested.date.isSame moment(raw.date), 'second'
    assert tested.dueDate?
    assert tested.dueDate.isSame moment(raw.date).add(60, 'days'), 'second'
    assert tested.ref is raw.ref
    assert.deepStrictEqual tested.customer, raw.customer
    assert tested.items.length is 1
    item = tested.items[0]
    assert item instanceof InvoiceItem
    assert item.name is raw.items[0].name
    assert item.price is raw.items[0].price
    assert item.quantity is 1
    assert item.vat is 0
    assert tested.discount is raw.discount
    assert tested.delayFee is raw.delayFee
    assert tested.sent is null
    assert tested.cardId is raw.cardId

    tested.save (err) ->
      return done err if err?
      assert tested.id?
      assert tested._v?
      assert tested.items.length is 1
      item = tested.items[0]
      assert item instanceof InvoiceItem
      assert item.name is raw.items[0].name
      assert item.price is raw.items[0].price
      assert item.quantity is 1
      assert item.vat is 0
      done()

  it 'should set customer details from dancer', (done) ->
    tested = new Invoice
      ref: '2016-01-003'
      customer:
        name: 'Mlle. Jeanne Dou'
        street: '10 rue du pont',
        zipcode: 69001
        city: 'Lyon'

    tested.setCustomers [dancer1], (err) ->
      return done err if err?
      assert tested.customer.name is 'M. Jean Dupond'
      assert tested.customer.street is address1.street
      assert tested.customer.city is address1.city
      assert tested.customer.zipcode is address1.zipcode
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

    tested.setCustomers [dancer2], (err) ->
      return done err if err?
      assert tested.customer.name is 'Mme. Julie Durand'
      assert tested.customer.street is raw.customer.street
      assert tested.customer.city is raw.customer.city
      assert tested.customer.zipcode is raw.customer.zipcode
      done()

  describe 'given a set of existing references', () ->

    teacher1 = 0
    teacher2 = 1
    refs = [
      {ref: '2016-08-001', selectedTeacher: teacher1}
      {ref: '2016-08-001', selectedTeacher: teacher2}
      {ref: '2016-08-002', selectedTeacher: teacher1}
      {ref: '2016-07-001', selectedTeacher: teacher1}
      {ref: '2016-07-003', selectedTeacher: teacher1}
      {ref: '2016-07-010', selectedTeacher: teacher1}
      {ref: '2016-07-1000', selectedTeacher: teacher1}
      {ref: 'FR-2016-COL-06-JAZZ-10 custom', selectedTeacher: teacher1}
      {ref: '2016-05-unparseable', selectedTeacher: teacher1}
      {ref: '2016-05-89-90', selectedTeacher: teacher1}
      {ref: '2016-unparseable-90', selectedTeacher: teacher1}
    ]

    before (done) ->
      Invoice.drop (err) ->
        return done err if err?
        async.each refs, ((raw, next) ->
          invoice = new Invoice(raw)
          # disabled ref checks for test invoices
          invoice.save = Persisted::save
          invoice.save next
        ), done

    after (done) -> Invoice.drop done

    it 'should check that null refs are invalid', (done) ->
      Invoice.isRefValid null, {}, (err, isValid) ->
        return done err if err?
        assert isValid is false
        done()

    it 'should check that undefined refs are invalid', (done) ->
      Invoice.isRefValid undefined, {}, (err, isValid) ->
        return done err if err?
        assert isValid is false
        done()

    it 'should check that numerical refs are invalid', (done) ->
      Invoice.isRefValid 18, {}, (err, isValid) ->
        return done err if err?
        assert isValid is false
        done()

    it 'should check that refs without 4-digit year are invalid', (done) ->
      Invoice.isRefValid '16-05-001', {}, (err, isValid) ->
        return done err if err?
        assert isValid is false
        done()

    it 'should check that refs without 2-digit month are invalid', (done) ->
      Invoice.isRefValid '2016-5-001', {}, (err, isValid) ->
        return done err if err?
        assert isValid is false
        done()

    it 'should check that refs without rank month are invalid', (done) ->
      Invoice.isRefValid '2016-01', {}, (err, isValid) ->
        return done err if err?
        assert isValid is false
        done()

    it 'should check that existing refs are invalid', (done) ->
      Invoice.isRefValid '2016-07-001', {ref:'2016-08-001', selectedTeacher: teacher1}, (err, isValid) ->
        return done err if err?
        assert isValid is false
        done()

    it 'should accept valid references formats', (done) ->
      Invoice.isRefValid '2017-07-001', {ref:'2016-08-001', selectedTeacher: teacher1}, (err, isValid) ->
        return done err if err?
        assert isValid is true
        done()

    it 'should get reference for an empty month', (done) ->
      Invoice.getNextRef 2016, 9, teacher1, (err, ref) ->
        return done err if err?
        assert ref is '2016-09-001'
        done()

    it 'should get next reference for month with existing refs', (done) ->
      Invoice.getNextRef 2016, 8, teacher1, (err, ref) ->
        return done err if err?
        assert ref is '2016-08-003'
        done()

    it 'should get next reference for month with existing refs for a different school', (done) ->
      Invoice.getNextRef 2016, 8, teacher2, (err, ref) ->
        return done err if err?
        assert ref is '2016-08-002'
        done()

    it 'should get next reference for month with more than 999 refs', (done) ->
      Invoice.getNextRef 2016, 7, teacher1, (err, ref) ->
        return done err if err?
        assert ref is '2016-07-1001'
        done()

    it 'should ignore extra words when getting next reference', (done) ->
      Invoice.getNextRef 2016, 6, teacher1, (err, ref) ->
        return done err if err?
        assert ref is '2016-06-011'
        done()

    it 'should ignore unparseable refs when getting next reference', (done) ->
      Invoice.getNextRef 2016, 5, teacher1, (err, ref) ->
        return done err if err?
        assert ref is '2016-05-090'
        done()

    it 'should check ref validity when saving new invoice', (done) ->
      saved = new Invoice ref: '2016-08-001', selectedTeacher: teacher1
      saved.save (err) ->
        assert err?
        assert err.message.includes 'misformated or already used'
        done()

    it 'should can save the with the same ref', (done) ->
      saved = new Invoice ref: '2016-08-003', selectedTeacher: teacher1
      saved.save (err) ->
        return done err if err?
        saved.save (err) ->
          assert not err?
          done()

    it 'should can reuse same ref if school is different', (done) ->
      saved = new Invoice ref: '2016-08-002', selectedTeacher: teacher2
      saved.save (err) ->
        return done err if err?
        saved.save (err) ->
          assert not err?
          done()