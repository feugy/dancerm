{expect} = require 'chai'
{each, map, eachSeries} = require 'async'
_ = require 'lodash'
path = require 'path'
{exists, readFile, ensureDir, remove} = require 'fs-extra'
Export = require '../../../app/script/service/export'
Import = require '../../../app/script/service/import'
{init} = require '../../../app/script/model/tools/initializer'
Dancer = require '../../../app/script/model/dancer'
Address = require '../../../app/script/model/address'
Registration = require '../../../app/script/model/registration'
Card = require '../../../app/script/model/card'
DanceClass = require '../../../app/script/model/dance_class'
Lesson = require '../../../app/script/model/lesson'
Invoice = require '../../../app/script/model/invoice'
InvoiceItem = require '../../../app/script/model/invoice_item'
{getDbPath, generateId} = require '../../../app/script/util/common'

describe 'Export service tests', ->

  tested = new Export()
  importer = new Import()

  danceClasses = [
    new DanceClass kind: 'Toutes danses', color:'color1', level: 'débutant', start: 'Wed 19:45', end: 'Wed 20:45', hall: 'Gratte-ciel 2', teacher: 'Michelle'
  ]

  registrations = [
    new Registration season: '2013/2014', charged: 300 #, invoiceIds: invoices[1..2]
    new Registration season: '2013/2014', charged: 300
    new Registration season: '2013/2014', charged: 100
    new Registration season: '2014/2015', charged: 400
  ]

  cards = [
    new Card id: generateId(), knownBy: ['associationsBiennal'], registrations: [registrations[0]]
    new Card id: generateId(), knownBy: ['elders', 'Une copine'], registrations: [registrations[1]]
    new Card id: generateId(), knownBy: [], registrations: registrations[2..3]
  ]

  invoiceItems = [
    new InvoiceItem name: 'Cours particulier', price: 45, quantity: 2
    new InvoiceItem name: 'Cours 1h trimestre', price: 180
    new InvoiceItem name: 'Cours 1h annuel', price: 260
  ]

  invoices = [
    new Invoice id: generateId(), ref: '2014-05-001', items: [invoiceItems[0]], sent: null, selectedTeacher: 0
    new Invoice id: generateId(), ref: '2014-05-002', items: [invoiceItems[1..2]], sent: null, cardId: cards[0].id, season: '2014/2015', selectedTeacher: 0
  ]
  registrations[0].invoiceIds = invoices[1..2].map (i) -> i.id

  lessons = [
    new Lesson id: generateId(), teacher: 'Anthony', details: 'rumba' #,dancerId: dancer1
    new Lesson id: generateId(), teacher: 'Diana', details: 'paso', invoiceId: invoices[0].id #,dancerId: dancer1
    new Lesson id: generateId(), teacher: 'Diana', details: 'jive', invoiceId: invoices[0].id #,dancerId: dancer1
  ]

  addresses = [
    new Address id: generateId(), street: '31 rue séverine', city: 'Villeurbanne', zipcode: '69100', phone: '0458291048'
    new Address id: generateId(), street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode: '69100'
    new Address id: generateId(), street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode: '69009', phone: '0478613207'
  ]

  dancers = [
    new Dancer id: generateId(), cardId: cards[0].id, addressId: addresses[0].id, lessonIds: lessons.map((l) -> l.id), title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-05-15', cellphone: '0634144728', email: 'emilieab@live.fr', lessonIds: lessons.map (l) -> l.id
    new Dancer id: generateId(), cardId: cards[0].id, addressId: addresses[0].id, title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', phone: '0662885285',
    new Dancer id: generateId(), cardId: cards[1].id, addressId: addresses[1].id, title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-04-18', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr'
    new Dancer id: generateId(), cardId: cards[2].id, addressId: addresses[2].id, title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
    new Dancer id: generateId(), cardId: cards[2].id, title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-10-22', cellphone: '0617979688'
  ]
  lessons[0].dancerId = dancers[0].id
  lessons[1].dancerId = dancers[0].id
  lessons[2].dancerId = dancers[0].id

  before (done) ->
    @timeout 10000
    init (err) ->
      return done err if err?
      each [Card, Address, Dancer, DanceClass, Invoice, Lesson], (clazz, next) ->
        clazz.drop next
      , (err) ->
        return done err if err?
        each [danceClasses, addresses, cards, dancers, lessons, invoices], (models, next) ->
          map models, (model, next) ->
            model.save next
          , next
        , done

  it 'should export base as compact format', (done) ->
    @timeout 30000
    # when exporting the list into a file
    out = path.join __dirname, '..', '..', 'fixture', 'out.dump.json'
    tested.dump out, (err) ->
      return done err if err?
      # then file exists
      exists out, (fileExists) =>
        expect(fileExists).to.be.true
        readFile out, {encoding: 'utf8'}, (err, content) =>
          return done err if err?
          json = null
          for clazz in [Address, Dancer, DanceClass, Card]
            expect(content).to.include "------#{clazz.name}"
            for model in addresses.concat cards, dancers
              for attr, value of model.toJSON()
                if attr in ['_v', 'zipcode'] or value is null
                  expect(content).to.include "\"#{attr}\":#{value}"
                else if attr is 'knownBy'
                  expect(content).to.include "\"#{attr}\":[#{if value.length then "\"#{value.join('","')}\"" else ''}]"
                else unless attr in ['registrations', 'danceClassIds', 'lessonIds']
                  expect(content).to.include "\"#{attr}\":\"#{value}\""
          done()

  it 'should export dancers list into xlsx file', (done) ->
    # when exporting the list into a file
    out = path.join(__dirname, '..', '..', 'fixture', 'out.export_1.xlsx')
    tested.toFile out, dancers, (err) ->
      return done err if err?
      # then file can be imported
      importer.fromFile out, (err, models) ->
        return done err if err?
        expect((model for model in models when model instanceof Dancer)).to.have.lengthOf dancers.length
        # then all dancers were properly extracted
        for expectedDancer in dancers
          dancer = _.find models, firstname: expectedDancer.firstname
          expect(dancer, "#{expectedDancer.firstname} not found").to.exist
          expect(JSON.stringify _.omit dancer.toJSON(), 'created', 'id', 'lessonIds', 'addressId', 'cardId', '_v').to.be.deep.equal JSON.stringify _.omit expectedDancer.toJSON(), 'created', 'id', 'lessonIds', 'addressId', 'cardId', '_v'
          # then their addresses were exported
          address = _.find models, id: dancer.addressId
          expectedAddress = _.find addresses, id: expectedDancer.addressId
          if expectedAddress?
            expect(address, "#{expectedAddress.street} not found").to.exist
            expect(JSON.stringify _.omit address.toJSON(), 'id', '_v').to.be.deep.equal JSON.stringify _.omit expectedAddress.toJSON(), 'id', '_v'
          else
            # unfound address has been generated
            expect(address).to.exist
            expect(address.city).to.be.empty
            expect(address.zipcode).to.equal 69100
            expect(address.street).to.be.empty
            expect(address.phone).not.to.exist
          # then their cards were exported
          card = _.find models, id: dancer.cardId
          expectedCard = _.find cards, id: expectedDancer.cardId
          expect(card, "#{expectedCard.street} not found").to.exist
          expect(JSON.stringify _.omit card.toJSON(), 'id', '_v', 'registrations').to.be.deep.equal JSON.stringify _.omit expectedCard.toJSON(), 'id', '_v', 'registrations'
        done()