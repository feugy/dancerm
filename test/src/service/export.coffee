{expect} = require 'chai'
{each} = require 'async'
_ = require 'underscore'
path = require 'path'
rimraf = require 'rimraf'
{exists, readFile, ensureDir} = require 'fs-extra'
{Promise} = require 'es6-promise'
Export = require '../../../app/script/service/export'
Import = require '../../../app/script/service/import'
Dancer = require '../../../app/script/model/dancer'
Address = require '../../../app/script/model/address'
Registration = require '../../../app/script/model/registration'
Card = require '../../../app/script/model/card'
DanceClass = require '../../../app/script/model/danceclass'
{getDbPath} = require '../../../app/script/util/common'

describe 'Export service tests', ->

  tested = new Export()
  importer = new Import()

  addresses = [
    new Address street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100', phone: '0458291048'
    new Address street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'
    new Address street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode: '69009', phone: '0478613207'
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
    new Dancer title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-04-18', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr'
    new Dancer title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
    new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-10-22', cellphone: '0617979688'
  ]

  cards = [
    new Card knownBy: ['associationsBiennal'], registrations: [registrations[0]]
    new Card knownBy: ['elders', 'web'], registrations: [registrations[1]]
    new Card knownBy: [], registrations: registrations[1..2]
  ]

  danceClasses = [
    new DanceClass kind: 'Toutes danses', color:'color1', level: 'débutant', start: 'Wed 19:45', end: 'Wed 20:45', hall: 'Gratte-ciel 2', teacher: 'Michelle'
  ]

  before (done) ->
    @timeout 10000
    rimraf getDbPath(), ->
      ensureDir getDbPath(), ->
        Promise.all((danceClass.save() for danceClass in danceClasses)).then((_danceClasses) ->
          Promise.all((address.save() for address in addresses)).then (_addresses) ->
            Promise.all((card.save() for card in cards)).then (_cards) ->
              cards = [_cards[0], _cards[1], _cards[2], _cards[2]]
              addresses = [_addresses[0], _addresses[0], _addresses[1], _addresses[2]]
              Promise.all((for dancer, i in dancers
                dancer.card = cards[i]
                dancer.address = addresses[i]
                dancer.save()
              )).then () ->
                done()
        ).catch done

  it 'should export base as compact format', (done) ->
    @timeout 30000
    # when exporting the list into a file
    out = path.join __dirname, '..', '..', 'fixture', 'out.dump.json'
    tested.dump(out).then(() =>
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
                if attr in ['_v'] or value is null
                  expect(content).to.include "\"#{attr}\":#{value}"
                else if attr is 'id'
                  expect(content).to.include "\"_#{attr}\":\"#{value}\""
                else if attr is 'knownBy'
                  expect(content).to.include "\"#{attr}\":[#{if value.length then "\"#{value.join('","')}\"" else ''}]"
                else unless attr in ['registrations', 'danceClassIds']
                  expect(content).to.include "\"#{attr}\":\"#{value}\""
          done()
    ).catch done

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