{expect} = require 'chai'
{each} = require 'async'
_ = require 'underscore'
path = require 'path'
Export = require '../../../app/script/service/export'
Import = require '../../../app/script/service/import'
Dancer = require '../../../app/script/model/dancer'

describe.only 'Export service tests', ->

  tested = new Export()
  importer = new Import()

  addresses = [
    new Address street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100', phone '0458291048'
    new Address street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'
    new Address street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009', phone:'0478613207'
  ]

  registrations = [
    new Registration season: '2013/2014', charged: 300
    new Registration season: '2013/2014', charged: 300
    new Registration season: '2013/2014', charged: 100
    new Registration season: '2014/2015', charged: 400
  ]

  dancers = [
    new Dancer title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-05-15', cellphone: '0634144728', email: 'emilieab@live.fr'
    new Dancer title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', phone: '0662885285', 
    new Dancer title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-04-18', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr', knownBy: ['Groupon']
    new Dancer title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', , email: 'rafystilmot@hotmail.fr', knownBy: ['leaflets']
    new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-10-22', address:{ street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'}, cellphone: '0617979688'
  ]

  cards = [
    new Card knownBy: ['associationsBiennal']
    new Card knownBy: ['elders', 'web']
    new Card knownBy: []
  ]

  before (done) ->
    Promise.all((address.save() for address in addresses)).then (_addresses) ->
      Promise.all((registrations.save() for registration in registrations)).then (_registrations) ->
        registrations = [[_registrations[0]], [_registrations[1]], [_registrations[1], _registrations[2]]]
        Promise.all((for card, i in cards
          card.registrations = registrations[i]
          card.save()
        )).then (_cards) ->
          cards = [_cards[0], _cards[1], _cards[2], _cards[2]]
          addresses = [_addresses[0], _addresses[0], _addresses[1], _addresses[2]]
          Promise.all((for dancer, i in dancers
            dancer.card = cards[i]
            dancer.address = addresses[i]
            dancer.save()
          )).then (_dancers) ->
            console.log _dancers
            done()

  it 'should export base as compact format', (done) ->

    tested.dump out, (err) ->

  it.skip 'should export dancers list into xlsx file', (done) ->

    # when exporting the list into a file
    out = path.join(__dirname, '..', '..', 'fixture', 'out.export_1.xlsx')
    tested.toFile out, dancers, (err) ->
      return done "Failed to export to file #{err}" if err?

      # then file can be imported
      importer.fromFile out, (err, models) ->
        return done "Failed to import from generated file: #{err}" if err?
        expect(models).to.have.lengthOf dancers.length
        # then all dancers were properly extracted
        each dancers, (expected, next) ->
          found = _.find(models, (model) -> model.dancer.firstname is expected.firstname)?.dancer
          expect(found).to.exist
          expect(_.omit found.toJSON(), 'created', 'id').to.be.deep.equal _.omit expected.toJSON(), 'created', 'id'
          next()
        , done