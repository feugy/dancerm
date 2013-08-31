{expect} = require 'chai'
_ = require 'underscore'
moment = require 'moment'
path = require 'path'
Import = require '../../../app/script/service/import'
Dancer = require '../../../app/script/model/dancer/dancer'

describe 'Import service tests', ->

  tested = new Import()

  it 'should import extract dancers from xlsx file', (done) ->
    expected = [
      new Dancer title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', address:{ street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'}, cellphone: '0634144728', email: 'emilieab@live.fr'
      new Dancer title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', address:{ street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'}, phone: '0662885285', knownBy: ['associationsBiennal']
      new Dancer title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', address:{ street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009'}, cellphone: '0640652009', email: 'lila.ainine@yahoo.fr', knownBy: ['Groupon']
      new Dancer title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', address:{ street: '40 rue du rhône allée 5', city: 'Lyon', zipcode:'69007'}, cellphone: '0631063774', phone:'0478613207', email: 'rafystilmot@hotmail.fr', knownBy: ['leaflets']
      new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-01-01', address:{ street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'}, cellphone: '0617979688'
    ]

    tested.fromFile path.join('fixture', 'import_1.xlsx'), (err, models, report) ->
      return done err if err?
      # then all models are present
      models = _.sortBy models, 'lastname'
      expect(models).to.have.lengthOf 5
      for model, i in models
        expect(model).to.be.an.instanceOf Dancer
        expect(_.omit model.toJSON(), ['id', 'created']).to.be.deep.equal _.omit expected[i].toJSON(), ['id', 'created']
      # then report should contain all informations
      expect(report.modifiedBy).to.be.equal 'Damien Feugas'
      expect(report.modifiedOn.valueOf()).to.be.closeTo moment('2013-08-24 08:41:51').valueOf(), 500
      expect(report.worksheets).to.have.lengthOf 3
      expect(report.worksheets[0].extracted).to.be.equal 5
      expect(report.worksheets[0].name).to.be.equal 'Feuil1'
      expect(report.worksheets[0].details).to.be.null
      expect(report.worksheets[1].extracted).to.be.equal 0
      expect(report.worksheets[1].name).to.be.equal 'Feuil2'
      expect(report.worksheets[1].details).to.be.equal 'Empty worksheet'
      expect(report.worksheets[2].extracted).to.be.equal 0
      expect(report.worksheets[2].name).to.be.equal 'Feuil3'
      expect(report.worksheets[2].details).to.be.equal 'Empty worksheet'
      done()

  it 'should import extract multiple dancers same raw', (done) ->
    expected = [
      new Dancer title: 'Mme', firstname: 'Amarande', lastname: 'Gniewek', address:{ street: '11, route de st m. de gourdans', city: 'Meximieux', zipcode:'01800'}, phone:'0472697929', cellphone: '0673284308', knownBy: ['Ancien']
      new Dancer title: 'M.', firstname: 'Joseph', lastname: 'Gniewek', address:{ street: '11, route de st m. de gourdans', city: 'Meximieux', zipcode:'01800'}, phone:'0472697929', cellphone: '0673284308', knownBy: ['Ancien']
      new Dancer title: 'M.', firstname: 'Florent', lastname: 'Gros', birth: '2007-01-01', address:{ street: '100, rue château gaillard', city: 'Villeurbanne', zipcode: '69100'}, phone: '0478984945', cellphone:'0662432173', email: 'vm112@hotmail.com'
      new Dancer title: 'Mlle', firstname: 'Paloma', lastname: 'Gros', birth: '2007-01-01', address:{ street: '100, rue château gaillard', city: 'Villeurbanne', zipcode: '69100'}, phone: '0478984945', cellphone:'0662432173', email: 'vm112@hotmail.com'
      new Dancer title: 'Mme', firstname: 'Virginie', lastname: 'Marcolungo', birth: '1977-01-01', address:{ street: '100, rue château gaillard', city: 'Villeurbanne', zipcode: '69100'}, phone: '0478984945', cellphone:'0662432173', email: 'vm112@hotmail.com'
      new Dancer title: 'Mlle', firstname: 'Maeva', lastname: 'Meloni', birth: '1994-01-01', address:{ street: '148, cours emile zola', city: 'Villeurbanne', zipcode: '69100'}, phone: '0478853765', cellphone:'0472102290', knownBy: ['associationsBiennal', 'leaflets']
      new Dancer title: 'Mlle', firstname: 'Melissa', lastname: 'Meloni', birth: '1998-01-01', address:{ street: '148, cours emile zola', city: 'Villeurbanne', zipcode: '69100'}, phone: '0478853765', cellphone:'0472102290', knownBy: ['associationsBiennal', 'leaflets']
      new Dancer title: 'Mlle', firstname: 'Inès', lastname: 'Mohammedi', birth: '2002-01-01', address:{ street: '43 rue lamartine', city: 'Vaulx en velin', zipcode: '69120'}, phone: '0472045796', cellphone:'0670823944', knownBy: ['Ancien']
      new Dancer title: 'M.', firstname: 'Jessim', lastname: 'Mohammedi', birth: '2002-01-01', address:{ street: '43 rue lamartine', city: 'Vaulx en velin', zipcode: '69120'}, phone: '0472045796', cellphone:'0670823944', knownBy: ['Ancien']
      new Dancer title: 'Mlle', firstname: 'Sirine', lastname: 'Mohammedi', birth: '2002-01-01', address:{ street: '43 rue lamartine', city: 'Vaulx en velin', zipcode: '69120'}, phone: '0472045796', cellphone:'0670823944', knownBy: ['Ancien']
    ]

    tested.fromFile path.join('fixture', 'import_2.xlsx'), (err, models, report) ->
      return done err if err?
      # then all models are present
      models = _.sortBy models, (model) -> model.lastname + model.firstname
      expect(models).to.have.lengthOf 10
      for model, i in models
        expect(model).to.be.an.instanceOf Dancer
        expect(JSON.stringify _.omit model.toJSON(), ['id', 'created']).to.be.deep.equal JSON.stringify _.omit expected[i].toJSON(), ['id', 'created']
      # then report should contain all informations
      expect(report.modifiedBy).to.be.equal 'Damien Feugas'
      expect(report.modifiedOn.valueOf()).to.be.closeTo moment('2013-08-24 17:07:07').valueOf(), 500
      expect(report.worksheets).to.have.lengthOf 3
      expect(report.worksheets[0].extracted).to.be.equal 10
      expect(report.worksheets[0].name).to.be.equal 'Feuil1'
      expect(report.worksheets[0].details).to.be.null
      expect(report.worksheets[1].extracted).to.be.equal 0
      expect(report.worksheets[1].name).to.be.equal 'Feuil2'
      expect(report.worksheets[1].details).to.be.equal 'Empty worksheet'
      expect(report.worksheets[2].extracted).to.be.equal 0
      expect(report.worksheets[2].name).to.be.equal 'Feuil3'
      expect(report.worksheets[2].details).to.be.equal 'Empty worksheet'
      done()