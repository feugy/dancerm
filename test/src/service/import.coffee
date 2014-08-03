{expect} = require 'chai'
_ = require 'underscore'
async = require 'async'
moment = require 'moment'
path = require 'path'
Import = require '../../../app/script/service/import'
Dancer = require '../../../app/script/model/dancer/dancer'
Planning = require '../../../app/script/model/planning/planning'

describe 'Import service tests', ->

  planning2011 = null

  before (done) ->
    Planning.drop (err) ->
      return done err if err?
      Dancer.drop (err) ->
        return done err if err?
        planning2011 = new Planning season: '2011/2012'
        planning2011.save done

  tested = new Import()

  it 'should import extract dancers from xlsx file', (done) ->
    expected = [
      {lastReg: 2012, dancer: new Dancer title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', address:{ street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'}, cellphone: '0634144728', email: 'emilieab@live.fr'}
      {lastReg: null, dancer: new Dancer title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', address:{ street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'}, phone: '0662885285', knownBy: ['associationsBiennal']}
      {lastReg: 2011, dancer: new Dancer title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', address:{ street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009'}, cellphone: '0640652009', email: 'lila.ainine@yahoo.fr', knownBy: ['Groupon']}
      {lastReg: null, dancer: new Dancer title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', address:{ street: '40 rue du rhône allée 5', city: 'Lyon', zipcode:'69007'}, cellphone: '0631063774', phone:'0478613207', email: 'rafystilmot@hotmail.fr', knownBy: ['leaflets']}
      {lastReg: 2011, dancer: new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-01-01', address:{ street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'}, cellphone: '0617979688'}
    ]

    tested.fromFile path.join(__dirname, '..', '..', 'fixture', 'import_1.xlsx'), (err, models, report) ->
      return done err if err?
      # then all models are present
      models = _.sortBy models, 'lastname'
      expect(models).to.have.lengthOf 5
      for {dancer, lastRegistration}, i in models
        expect(dancer).to.be.an.instanceOf Dancer
        expect(lastRegistration).to.be.equal expected[i].lastReg
        expect(_.omit dancer.toJSON(), ['id', 'created']).to.be.deep.equal _.omit expected[i].dancer.toJSON(), ['id', 'created']
      # then report should contain all informations
      expect(report.modifiedBy).to.be.equal 'Damien Feugas'
      expect(report.modifiedOn.valueOf()).to.be.closeTo moment('2013-09-04 07:54:00').valueOf(), 60000
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

    tested.fromFile path.join(__dirname, '..', '..', 'fixture', 'import_2.xlsx'), (err, models, report) ->
      return done err if err?
      # then all models are present
      models = _.sortBy models, (model) -> model.dancer.lastname + model.dancer.firstname
      expect(models).to.have.lengthOf 10
      for {dancer, lastReg}, i in models
        expect(dancer).to.be.an.instanceOf Dancer
        expect(JSON.stringify _.omit dancer.toJSON(), ['id', 'created']).to.be.deep.equal JSON.stringify _.omit expected[i].toJSON(), ['id', 'created']
      # then report should contain all informations
      expect(report.modifiedBy).to.be.equal 'Damien Feugas'
      expect(report.modifiedOn.valueOf()).to.be.closeTo moment('2013-08-24 17:07:00').valueOf(), 60000
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

  it 'should imported dancer registrations be merged', (done) ->
    existing = [
      new Dancer title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', address:{ street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'}, cellphone: '0634144728', email: 'emilieab@live.fr'
      new Dancer title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', address:{ street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'}, phone: '0662885285', knownBy: ['associationsBiennal']
      new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-01-01', address:{ street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'}, cellphone: '0617979688', registrations: [planningId: planning2011.id, danceClassIds:[1, 2]]
      new Dancer title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', address:{ street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009'}, cellphone: '0640652009', email: 'lila.ainine@yahoo.fr', knownBy: ['Groupon'], registrations: [planningId: planning2011.id]
    ]
    added = [
      {lastRegistration: 2012, dancer: new Dancer title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', address:{ street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'}, cellphone: '0634144728', email: 'emilieab@live.fr'}
      {lastRegistration: null, dancer: new Dancer title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', address:{ street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'}, phone: '0662885285', knownBy: ['associationsBiennal']}
      {lastRegistration: 2012, dancer: new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-01-01', address:{ street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'}, cellphone: '0617979688'}
      {lastRegistration: 2011, dancer: new Dancer title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', address:{ street: '40 rue du rhône allée 5', city: 'Lyon', zipcode:'69007'}, cellphone: '0631063774', phone:'0478613207', email: 'rafystilmot@hotmail.fr', knownBy: ['leaflets']}
    ]

    # when merging new and existing dancers
    tested.merge existing, added, (err, imported) ->
      expect(imported).to.be.equal 3
      planning2012 = null

      async.series [
        (next) -> 
         # then existing Emilie has new registration and created planningId
         Dancer.find existing[0].id, (err, model) ->
            return next "Failed to check Emilie: #{err}" if err?
            reg = added[0].lastRegistration
            expect(model.registrations).to.have.lengthOf 1
            expect(model.registrations[0].danceClassIds).to.have.lengthOf 0
            expect(_.omit model.toJSON(), 'id', 'registrations', 'created').to.be.deep.equal _.omit added[0].dancer.toJSON(), ['id', 'registrations', 'created']
            # then a planning has been created
            Planning.find model.registrations[0].planningId, (err, model) ->
              return next err if err?
              expect(model).to.have.property('season').that.is.equal "#{reg}/#{reg+1}"
              planning2012 = model
              next()
        # then existing Nelly has no modification
        (next) -> 
          Dancer.find existing[1].id, (err, model) ->
            expect(err, "Nelly was modified").to.exist
            expect(err.message).to.contain 'not found'
            next()
        (next) -> 
          # then existing Rachel has new registration added to its existing
          Dancer.find existing[2].id, (err, model) ->
            return next "Failed to check Rachel: #{err}" if err?
            reg = added[2].lastRegistration
            expect(model.registrations).to.have.lengthOf 2
            expect(model.registrations[1].planningId).to.be.equal planning2012.id
            expect(model.registrations[1].danceClassIds).to.have.lengthOf 0
            expect(model.registrations[0].planningId).to.be.equal planning2011.id
            expect(model.registrations[0].danceClassIds).to.be.deep.equals [1, 2]
            expect(_.omit model.toJSON(), 'id', 'registrations', 'created').to.be.deep.equal _.omit added[2].dancer.toJSON(), ['id', 'registrations', 'created']
            next()
        # then Raphaël has been added whith registration on reused planningSeason
        (next) -> 
          Dancer.find added[3].dancer.id, (err, model) ->
            return next "Failed to check Raphaël: #{err}" if err?
            reg = added[3].lastRegistration
            expect(model.registrations).to.have.lengthOf 1
            expect(model.registrations[0].planningId).to.be.equal planning2011.id
            expect(model.registrations[0].danceClassIds).to.have.lengthOf 0
            expect(_.omit model.toJSON(), 'registrations').to.be.deep.equal _.omit added[3].dancer.toJSON(), 'registrations'
            next()
        # then Lila has not been modified
        (next) -> 
          Dancer.find existing[3].id, (err, model) ->
            expect(err, 'Lila was modified !').to.exist
            expect(err.message).to.contain 'not found'
            next()
        (next) ->
          Planning.findAll (err, plannings) ->
            expect(plannings).to.have.lengthOf 2
            expect(_.chain(plannings).pluck('season').value().sort()).to.be.deep.equal ['2011/2012', '2012/2013']
            next()
      ], done