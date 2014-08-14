{expect} = require 'chai'
{each} = require 'async'
_ = require 'underscore'
path = require 'path'
Export = require '../../../app/script/service/export'
Import = require '../../../app/script/service/import'
Dancer = require '../../../app/script/model/dancer'

describe.skip 'Export service tests', ->

  tested = new Export()
  importer = new Import()

  it 'should export dancers list into xlsx file', (done) ->
    # given a dancers list
    dancers = [
      new Dancer title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-05-15', address:{ street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'}, cellphone: '0634144728', email: 'emilieab@live.fr'
      new Dancer title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', address:{ street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'}, phone: '0662885285', knownBy: ['associationsBiennal']
      new Dancer title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-04-18', address:{ street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009'}, cellphone: '0640652009', email: 'lila.ainine@yahoo.fr', knownBy: ['Groupon']
      new Dancer title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', address:{ street: '40 rue du rhône allée 5', city: 'Lyon', zipcode:'69007'}, cellphone: '0631063774', phone:'0478613207', email: 'rafystilmot@hotmail.fr', knownBy: ['leaflets']
      new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-10-22', address:{ street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'}, cellphone: '0617979688'
    ]

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