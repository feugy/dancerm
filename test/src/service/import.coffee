{expect} = require 'chai'
_ = require 'lodash'
async = require 'async'
moment = require 'moment'
{join} = require 'path'
{remove, mkdir} = require 'fs-extra'
{getDbPath} = require '../../../app/script/util/common'
{init} = require '../../../app/script/model/tools/initializer'
Import = require '../../../app/script/service/import'
Dancer = require '../../../app/script/model/dancer'
Card = require '../../../app/script/model/card'
DanceClass = require '../../../app/script/model/dance_class'
Registration = require '../../../app/script/model/registration'
Payment = require '../../../app/script/model/payment'
Address = require '../../../app/script/model/address'

describe 'Import service tests', ->

  before init

  beforeEach (done) -> 
    async.each [Card, Address, Dancer, DanceClass], (clazz, next) -> 
      clazz.drop next
    , done
      
  tested = new Import()

  describe 'given xlsx files', ->

    it 'should import extract dancers', (done) ->
      expected = [
        new Address street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'
        new Address street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100', phone: '0662885285'
        new Address street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009'
        new Address street: '40 rue du rhône allée 5', city: 'Lyon', zipcode:'69007', phone:'0478613207'
        new Address street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'
        new Card()
        new Card knownBy: ['associationsBiennal']
        new Card knownBy: ['groupon']
        new Card knownBy: ['leaflets']
        new Card()
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Nelly', lastname:'Aguilar'
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr'
        new Dancer danceClassIds: [], title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
        new Dancer danceClassIds: [], title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-01-01', cellphone: '0617979688'
      ]
      # links between models
      links = [{}, {}, {}, {}, {}, 
        {}, {}, {}, {}, {},
        {address: 0, card: 5},
        {address: 1, card: 6},
        {address: 2, card: 7},
        {address: 3, card: 8},
        {address: 4, card: 9}
      ]
      tested.fromFile join(__dirname, '..', '..', 'fixture', 'import_1.xlsx'), (err, models, report) ->
        return done err if err?
        # then all models are present
        expect(models).to.have.lengthOf expected.length
        for model, i in models
          if i < 5
            expect(model).to.be.an.instanceOf Address
          else if 5 <= i < 10 
            expect(model).to.be.an.instanceOf Card
          else
            expect(model).to.be.an.instanceOf Dancer
            expected[i].cardId = models[links[i].card].id
            expected[i].addressId = models[links[i].address].id
          expect(JSON.stringify _.omit model.toJSON(), ['id', 'created', 'registrations', '_v']).to.be.deep.equal JSON.stringify _.omit expected[i].toJSON(), ['id', 'created', 'registrations', '_v']
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
        new Address street: '11, route de st m. de gourdans', city: 'Meximieux', zipcode:'01800', phone:'0472697929'
        new Address street: '148, cours emile zola', city: 'Villeurbanne', zipcode: '69100', phone: '0478853765'
        new Address street: '100, rue château gaillard', city: 'Villeurbanne', zipcode: '69100', phone: '0478984945'
        new Address street: '43 rue lamartine', city: 'Vaulx en velin', zipcode: '69120', phone: '0472045796'
        new Card knownBy: ['elders']
        new Card knownBy: ['associationsBiennal', 'leaflets']
        new Card()
        new Card knownBy: ['elders']
        new Dancer danceClassIds: [], title: 'Mme', firstname: 'Amarande', lastname: 'Gniewek', cellphone: '0673284308'
        new Dancer danceClassIds: [], title: 'M.', firstname: 'Joseph', lastname: 'Gniewek', cellphone: '0673284308'
        new Dancer danceClassIds: [], title: 'Mlle', firstname: 'Maeva', lastname: 'Meloni', birth: '1994-01-01', cellphone:'0472102290'
        new Dancer danceClassIds: [], title: 'Mlle', firstname: 'Melissa', lastname: 'Meloni', birth: '1998-01-01', cellphone:'0472102290'
        new Dancer danceClassIds: [], title: 'Mme', firstname: 'Virginie', lastname: 'Marcolungo', birth: '1977-01-01', cellphone:'0662432173', email: 'vm112@hotmail.com'
        new Dancer danceClassIds: [], title: 'M.', firstname: 'Florent', lastname: 'Gros', birth: '2007-01-01', cellphone:'0662432173', email: 'vm112@hotmail.com'
        new Dancer danceClassIds: [], title: 'Mlle', firstname: 'Paloma', lastname: 'Gros', birth: '2007-01-01', cellphone:'0662432173', email: 'vm112@hotmail.com'
        new Dancer danceClassIds: [], title: 'M.', firstname: 'Jessim', lastname: 'Mohammedi', birth: '2002-01-01', cellphone:'0670823944'
        new Dancer danceClassIds: [], title: 'Mlle', firstname: 'Inès', lastname: 'Mohammedi', birth: '2002-01-01', cellphone:'0670823944'
        new Dancer danceClassIds: [], title: 'Mlle', firstname: 'Sirine', lastname: 'Mohammedi', birth: '2002-01-01', cellphone:'0670823944'
      ]
      # links between models
      links = [{}, {}, {}, {}, 
        {}, {}, {}, {},
        {address: 0, card: 4},
        {address: 0, card: 4},
        {address: 1, card: 5},
        {address: 1, card: 5},
        {address: 2, card: 6},
        {address: 2, card: 6},
        {address: 2, card: 6},
        {address: 3, card: 7},
        {address: 3, card: 7},
        {address: 3, card: 7}
      ]

      tested.fromFile join(__dirname, '..', '..', 'fixture', 'import_2.xlsx'), (err, models, report) ->
        return done err if err?
        # then all models are present
        expect(models).to.have.lengthOf expected.length
        for model, i in models
          if i < 4
            expect(model).to.be.an.instanceOf Address
          else if 4 <= i < 8
            expect(model).to.be.an.instanceOf Card
          else
            expect(model).to.be.an.instanceOf Dancer
            expected[i].cardId = models[links[i].card].id
            expected[i].addressId = models[links[i].address].id
          expect(JSON.stringify _.omit model.toJSON(), ['id', 'created', 'registrations', '_v']).to.equal JSON.stringify _.omit expected[i].toJSON(), ['id', 'created', 'registrations', '_v']
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

  describe 'given v3 dump files', ->

    it 'should import extract dancers', (done) ->
      expected = [
        new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
        new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[ 
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
        ]]
        new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Dancer id: 'fcf3d43e1f6f', _v: 1, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['00acbfb5e7d6', '043737c8e083'], title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
        new DanceClass id: '00acbfb5e7d6', _v: 0, season: '2013/2014', kind: 'Rock/Salsa', color: 'color2', level: 'confirmé', start: 'Mon 20:00', end: 'Mon 21:30', teacher: 'Anthony', hall: 'Croix-Luizet'
        new DanceClass id: '043737c8e083', _v: 0, season: '2013/2014', kind: 'Danse sportive/Rock/Salsa', color: 'color3', level: '2 8/12 ans', start: 'Wed 17:30', end: 'Wed 18:30', teacher: 'Anthony', hall: 'Gratte-ciel 2'
      ]

      tested.fromFile join(__dirname, '..', '..', 'fixture', 'import_3.json'), (err, models, report) ->
        return done err if err?
        # then all models are present
        expect(report).to.have.property('errors').that.is.empty
        expect(report).to.have.property('byClass').that.is.deep.equal Address: 1, Card: 1, Dancer: 2, DanceClass: 2
        expect(models).to.have.lengthOf expected.length
        for model, i in models
          expect(model).to.be.an.instanceOf expected[i].constructor
          expect(_.omit model.toJSON(), ['created']).to.be.deep.equal _.omit expected[i].toJSON(), ['created']
        done()

  describe 'merge test', ->

    existing = [
      new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
      new Address id: '3900cc712ba3', _v: 0, street: '2 rue clément marrot', city: 'Lyon', zipcode: 69007
      new Address id: '000bcbc38576', _v: 1, street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode: 69009
      new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[ 
        new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
        new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
      ]]
      new Card id: '30cb3a48900e', _v: 0
      new Card id: 'a8290940b47c', _v: 0, knownBy: ['Groupon']
      new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
      new Dancer id: 'fcf3d43e1f6f', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['00acbfb5e7d6', '043737c8e083'], title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
      new Dancer id: 'ea43920b42dc', _v: 1, cardId: '30cb3a48900e', addressId: '3900cc712ba3', title: 'Mme', firstname:'Rachel', lastname:'Durand', birth: '1970-01-01', cellphone: '0617979688'
      new Dancer id: '291047bce3ad', _v: 1, cardId: 'a8290940b47c', addressId: '000bcbc38576', title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr'
      new DanceClass id: '00acbfb5e7d6', _v: 0, season: '2013/2014', kind: 'Rock/Salsa', color: 'color2', level: 'confirmé', start: 'Mon 20:00', end: 'Mon 21:30', teacher: 'Anthony', hall: 'Croix-Luizet'
      new DanceClass id: '043737c8e083', _v: 0, season: '2013/2014', kind: 'Danse sportive/Rock/Salsa', color: 'color3', level: '2 8/12 ans', start: 'Wed 17:30', end: 'Wed 18:30', teacher: 'Anthony', hall: 'Gratte-ciel 2'
    ]

    beforeEach (done) ->
      i = 0
      async.eachSeries existing, (model, next) ->
        model._v = if i in [2, 7, 8] then 1 else 0
        i++
        model.save next
      , done

    it 'should new imported models be added', (done) ->
      imported = [
        new Address id: 'b393756e94cb', _v: 1, street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode: 69100
        new Dancer id: '0123abc398ee', v:0, cardId: '05928572039c', addressId: 'b393756e94cb', title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', cellphone: '0662885285'
        new Card id: '05928572039c', _v:2, knownBy: ['associationsBiennal']
      ]

      tested.merge imported, (err, byClass, conflicts) ->
        return done err if err?
        expect(byClass).to.deep.equal Dancer: 1, Address: 1, Card: 1
        expect(conflicts).to.be.empty

        Address.find imported[0].id, (err, addr) ->
          return done err if err?
          expect(addr).to.have.property('street').that.equal imported[0].street
          Dancer.find imported[1].id, (err, dancer) ->
            return done err if err?
            expect(dancer).to.have.property('firstname').that.equal imported[1].firstname
            Card.find imported[2].id, (err, card) ->
              return done err if err?
              expect(card).to.have.property('knownBy').that.deep.equal imported[2].knownBy
              done()

    it.skip '! version is not checked anymore !\nshould old imported models not be modified', (done) ->
      tested.merge [
        new Dancer id: 'ea43920b42dc', _v: 0, cardId: '30cb3a48900e', addressId: '3900cc712ba3', title: 'Mme', firstname:'Rachel', lastname:'Toto', birth: '1970-01-01'
      ], (err, byClass, conflicts) ->
        return done err if err?
        expect(byClass).to.deep.equal {}
        expect(conflicts).to.be.empty

        Dancer.find 'ea43920b42dc', (err, dancer) ->
          return done err if err?
          expect(dancer).to.have.property('lastname').that.equal 'Durand'
          done()

    it.skip '! version is not checked anymore !\nshould existing models be added with upper version', (done) ->
      imported = [
        new Card id: '30cb3a48900e', _v: 2, knownBy: ['Groupon', 'website'], registrations: [
          new Registration season: '2013/2014', charged: 300, period: 'year'
        ]
      ]

      # when merging new and existing dancers
      tested.merge imported, (err, byClass, conflicts) ->
        return done err if err?
        expect(byClass).to.deep.equal Card: 1
        expect(conflicts).to.be.empty

        # newest imported models have been updated
        Card.find imported[0].id, (err, result) ->
          return done err if err?
          expect(result).to.have.property('knownBy').that.deep.equal ['Groupon', 'website']
          expect(result).to.have.property('registrations').that.have.lengthOf 1
          done()

    it 'should conflicts be detected', (done) ->
      imported = [
        new Dancer id: 'ea18ba8a36c9', _v: 1, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083', '00acbfb5e7d6'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Card id: '40b728d54a0d', _v: 1, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 450, period: 'year', payments:[ 
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
          new Payment type: 'check', value: 150, receipt: '2014-10-14', payer: 'Simonin', bank: 'La Poste'
        ]]
      
      ]

      # when merging new and existing dancers
      tested.merge imported, (err, byClass, conflicts) ->
        return done err if err?
        expect(byClass).to.deep.equal {}

        # two conflicts have been detected
        expect(conflicts).to.have.lengthOf 2
        expect(conflicts[0].existing.toJSON()).to.deep.equal existing[6].toJSON()
        expect(conflicts[0].imported.toJSON()).to.deep.equal imported[0].toJSON()
        expect(conflicts[1].existing.toJSON()).to.deep.equal existing[3].toJSON()
        expect(conflicts[1].imported.toJSON()).to.deep.equal imported[1].toJSON()

        # models have not been changed
        Dancer.find imported[0].id, (err, dancer) ->
          return done err if err?
          expect(dancer).to.have.property('_v').that.equal 1
          Card.find imported[1].id, (err, card) ->
            return done err if err?
            expect(card).to.have.property('_v').that.equal 1
            done()