assert = require 'power-assert'
_ = require 'lodash'
async = require 'async'
moment = require 'moment'
{resolve} = require 'path'
{remove, mkdir} = require 'fs-extra'
{getDbPath} = require '../../app/src/util/common'
{init} = require '../../app/src/model/tools/initializer'
Import = require '../../app/src/service/import'
Dancer = require '../../app/src/model/dancer'
Card = require '../../app/src/model/card'
DanceClass = require '../../app/src/model/dance_class'
Registration = require '../../app/src/model/registration'
Payment = require '../../app/src/model/payment'
Address = require '../../app/src/model/address'
Invoice = require '../../app/src/model/invoice'
Lesson = require '../../app/src/model/lesson'

fixtures = resolve __dirname, '..', 'fixture'

describe 'Import service', ->

  before init

  beforeEach (done) ->
    async.each [Card, Address, Dancer, DanceClass], (clazz, next) ->
      clazz.drop next
    , done

  tested = new Import()

  it 'should fail when importing unsupported file', (done) ->
    tested.fromFile resolve(fixtures, 'test.txt'), (err) ->
      assert err?.message?.includes 'unsupported format text/plain'
      done()

  it 'should fail on missing file', (done) ->
    tested.fromFile null, (err) ->
      assert err?.message?.includes 'no file selected'
      done()

  it 'should fail on unknown file', (done) ->
    tested.fromFile resolve(fixtures, 'unknown.xlsx'), (err) ->
      assert err?.message?.includes 'no such file or directory'
      done()

  describe 'given xlsx files, fromFile()', ->

    it 'should fail on corrupted xlsx file', (done) ->
      tested.fromFile resolve(fixtures, 'v1-corrupted.xlsx'), (err) ->
        assert err?.message?.includes 'Corrupted zip : can\'t find end of central directory'
        done()

    it 'should fail on misformated xlsx file', (done) ->
      tested.fromFile resolve(fixtures, 'v1-misformated.xlsx'), (err) ->
        assert err?.message?.includes 'Cannot read property \'asText\' of null'
        done()

    it 'should fail on file without mandatory columns', (done) ->
      tested.fromFile resolve(fixtures, 'v1-missing-columns.xlsx'), (err, models, report) ->
        return done err if err?
        # then all models are present
        assert models.length is 0
        assert report.worksheets.length is 2
        assert report.worksheets[0].details is 'Missing title, lastname column'
        assert report.worksheets[1].details is 'Missing title, lastname column'
        done()

    it 'should import extract dancers', (done) ->
      expected = [
        new Address street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'
        new Address street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100', phone: '0662885285'
        new Address street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009'
        new Address street: '40 rue du rhône allée 5', city: 'Lyon', zipcode:'69007', phone:'0478613207'
        new Address street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'
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
        new Card knownBy: ['mouth']
        new Card knownBy: ['directory']
        new Card knownBy: ['pagesjaunesFr']
        new Card knownBy: ['website']
        new Card knownBy: ['searchEngine']
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Nelly', lastname:'Aguilar'
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr'
        new Dancer danceClassIds: [], title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-04-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
        new Dancer danceClassIds: [], title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-12-05', cellphone: '0617979688'
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Emilie2', lastname:'Abraham2', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Nelly2', lastname:'Aguilar2'
        new Dancer danceClassIds: [], title: 'Mlle', firstname:'Lila2', lastname:'Ainine2', birth: '1986-01-01', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr'
        new Dancer danceClassIds: [], title: 'M.', firstname:'Raphaël2', lastname:'Azoulay2', birth: '1989-04-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
        new Dancer danceClassIds: [], title: 'Mme', firstname:'Rachel2', lastname:'Barbosa2', birth: '1970-12-05'
      ]
      # links between models
      links = [
        {}, {}, {}, {}, {},
        {}, {}, {}, {}, {},
        {}, {}, {}, {}, {},
        {}, {}, {}, {}, {},
        {address: 0, card: 10},
        {address: 1, card: 11},
        {address: 2, card: 12},
        {address: 3, card: 13},
        {address: 4, card: 14},
        {address: 5, card: 15},
        {address: 6, card: 16},
        {address: 7, card: 17},
        {address: 8, card: 18},
        {address: 9, card: 19}
      ]
      tested.fromFile resolve(fixtures, 'v1-correct.xlsx'), (err, models, report) ->
        return done err if err?
        # then all models are present
        assert models.length is expected.length
        for model, i in models
          if i < 10
            assert model instanceof Address
          else if 10 <= i < 20
            assert model instanceof Card
          else
            assert model instanceof Dancer
            expected[i].cardId = models[links[i].card].id
            expected[i].addressId = models[links[i].address].id
          assert.deepStrictEqual _.omit(model.toJSON(), ['id', 'created', 'registrations', '_v']), _.omit expected[i].toJSON(), ['id', 'created', 'registrations', '_v']
        # then report should contain all informations
        assert report.modifiedBy is 'Damien'
        assert report.modifiedOn.isBetween '2017-08-03 08:00:00', '2017-08-03 20:00:00'
        assert report.worksheets.length is 3
        assert report.worksheets[0].extracted is 5
        assert report.worksheets[0].name is 'Feuil1'
        assert report.worksheets[0].details is null
        assert report.worksheets[1].extracted is 5
        assert report.worksheets[1].name is 'Feuil2'
        assert report.worksheets[1].details is null
        assert report.worksheets[2].extracted is 0
        assert report.worksheets[2].name is 'Feuil3'
        assert report.worksheets[2].details is 'Empty worksheet'
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

      tested.fromFile resolve(fixtures, 'v1-multiple-dancers.xlsx'), (err, models, report) ->
        return done err if err?
        # then all models are present
        assert models.length is expected.length
        for model, i in models
          if i < 4
            assert model instanceof Address
          else if 4 <= i < 8
            assert model instanceof Card
          else
            assert model instanceof Dancer
            expected[i].cardId = models[links[i].card].id
            expected[i].addressId = models[links[i].address].id
          assert.deepStrictEqual _.omit(model.toJSON(), ['id', 'created', 'registrations', '_v']), _.omit expected[i].toJSON(), ['id', 'created', 'registrations', '_v']
        # then report should contain all informations
        assert report.modifiedBy is 'Damien Feugas'
        assert report.modifiedOn.isBetween '2013-08-24 15:07:00', '2013-08-24 15:08:00'
        assert report.worksheets.length is 3
        assert report.worksheets[0].extracted is 10
        assert report.worksheets[0].name is 'Feuil1'
        assert report.worksheets[0].details is null
        assert report.worksheets[1].extracted is 0
        assert report.worksheets[1].name is 'Feuil2'
        assert report.worksheets[1].details is 'Empty worksheet'
        assert report.worksheets[2].extracted is 0
        assert report.worksheets[2].name is 'Feuil3'
        assert report.worksheets[2].details is 'Empty worksheet'
        done()

  describe 'given v2 dump files, fromFile()', ->

    it 'should fail on empty json v2 file', (done) ->
      tested.fromFile resolve(fixtures, 'v2-empty.json'), (err) ->
        assert err?.message?.includes 'no dancers found in file'
        done()

    it 'should fail on misformated json v2 file', (done) ->
      tested.fromFile resolve(fixtures, 'v2-misformated.json'), (err) ->
        assert err?.message?.includes 'Unexpected end of JSON input'
        done()

    it 'should import dancers', (done) ->
      expected = [
        new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Dancer id: 'fcf3d43e1f6f', _v: 1, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['00acbfb5e7d6', '043737c8e083'], title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
      ]

      tested.fromFile resolve(fixtures, 'v2-correct.json'), (err, models, report) ->
        return done err if err?
        # then all models are present
        assert.deepStrictEqual report.errors, [
          'created unexisting card (40b728d54a0d) for dancer Emilie Abraham (ea18ba8a36c9)'
          'created unexisting address (5f3da4e6a884) for dancer Emilie Abraham (ea18ba8a36c9)'
          'created unexisting card (40b728d54a0d) for dancer Raphaël Azoulay (fcf3d43e1f6f)'
          'created unexisting address (5f3da4e6a884) for dancer Raphaël Azoulay (fcf3d43e1f6f)'
        ]
        assert.deepStrictEqual report.byClass, Dancer: 2
        assert models.length is 6
        for expect, i in expected
          assert models[i] instanceof expect.constructor
          assert.deepStrictEqual _.unset(models[i].toJSON(), 'registrations[0].created'), _.unset expect.toJSON(), 'registrations[0].created'
        done()

  describe 'given v3 dump files, fromFile()', ->

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

    it 'should fail on empty json v3 file', (done) ->
      tested.fromFile resolve(fixtures, 'v3-empty.json'), (err) ->
        assert err?.message?.includes 'file is empty'
        done()

    it 'should import cards, dancers, addresses and dance classes', (done) ->
      tested.fromFile resolve(fixtures, 'v3-correct.json'), (err, models, report) ->
        return done err if err?
        # then all models are present
        assert.deepStrictEqual report.errors, []
        assert.deepStrictEqual report.byClass, Address: 1, Card: 1, Dancer: 2, DanceClass: 2
        assert models.length is expected.length
        for model, i in models
          assert model instanceof expected[i].constructor
          assert.deepStrictEqual _.unset(model.toJSON(), 'registrations[0].created'), _.unset expected[i].toJSON(), 'registrations[0].created'
        done()

    it 'should report unknown models as errors', (done) ->
      tested.fromFile resolve(fixtures, 'v3-unknown-model.json'), (err, models, report) ->
        return done err if err?
        # then unknown model were detected
        assert.deepStrictEqual report.errors, [
          'line 5: unsupported model class Unknown'
        ]
        # then all models are present
        assert.deepStrictEqual report.byClass, Address: 1, Card: 1, Dancer: 2, DanceClass: 2
        assert models.length is expected.length
        for model, i in models
          assert model instanceof expected[i].constructor
          assert.deepStrictEqual _.unset(model.toJSON(), 'registrations[0].created'), _.unset expected[i].toJSON(), 'registrations[0].created'
        done()

    it 'should report misformated records as errors', (done) ->
      tested.fromFile resolve(fixtures, 'v3-misformated.json'), (err, models, report) ->
        return done err if err?
        # then unknown model were detected
        assert.deepStrictEqual report.errors, [
          'line 6: failed to parse model Dancer: SyntaxError: Unexpected token \r in JSON at position 289'
        ]
        # then all models are present
        assert.deepStrictEqual report.byClass, Address: 1, Card: 1, Dancer: 1, DanceClass: 2
        assert models.length is expected.length - 1
        for model, i in models
          i = if i >= 2 then i + 1 else i # expected #2 isn't in models
          assert model instanceof expected[i].constructor
          assert.deepStrictEqual _.unset(model.toJSON(), 'registrations[0].created'), _.unset expected[i].toJSON(), 'registrations[0].created'
        done()

  describe '_checkRelationnalConstraints()', ->

    it 'should create unexisting cards for dancers', (done) ->
      report = errors: []
      models = [
        new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
        new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
      ]
      tested._checkRelationnalConstraints models, report, (err, toSave) ->
        return done err if err?
        assert report.errors.length is 1
        assert report.errors[0].includes "created unexisting card (#{toSave[2].id})"
        assert toSave.length is models.length + 1
        assert toSave[2] instanceof Card
        toSave[1].getCard (err, card) ->
          return done err if err?
          assert card is toSave[2]
          done()

    it 'should create unexisting addresses for dancers', (done) ->
      report = errors: []
      models = [
        new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
        ]]
        new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
      ]
      tested._checkRelationnalConstraints models, report, (err, toSave) ->
        return done err if err?
        assert report.errors.length is 1
        assert report.errors[0].includes "created unexisting address (#{toSave[2].id})"
        assert toSave.length is models.length + 1
        assert toSave[2] instanceof Address
        toSave[1].getAddress (err, address) ->
          return done err if err?
          assert address is toSave[2]
          done()

    it 'should remove unexisting lesson referenced from dancers', (done) ->
      report = errors: []
      models = [
        new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
        new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
        ]]
        new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', lessonIds: ['8aefcf146b7f', '028b385ca56e', '861f4afe518e'], danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Lesson id: '028b385ca56e', dancerId: 'ea18ba8a36c9'
      ]
      tested._checkRelationnalConstraints models, report, (err, toSave) ->
        return done err if err?
        assert report.errors.length is 2
        assert report.errors[0].includes "remove unexisting lesson reference (8aefcf146b7f)"
        assert report.errors[1].includes "remove unexisting lesson reference (861f4afe518e)"
        assert toSave.length is models.length
        assert.deepStrictEqual toSave[2].lessonIds, ['028b385ca56e']
        assert
        done()

    it 'should remove unexisting invoice references from cards', (done) ->
      report = errors: []
      models = [
        new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
        ], invoiceIds: ['1d28eb5b6fb0', '2d28eb5b6fb0']]
        new Invoice id: '2d28eb5b6fb0', ref: '2017-08-045', season: '2013/2014', customer: name: 'Emilie Abraham', street: '1 cours Emile Zola', zipcode: '69100', city: 'Villeurbanne'
      ]
      tested._checkRelationnalConstraints models, report, (err, toSave) ->
        return done err if err?
        assert report.errors.length is 1
        assert report.errors[0].includes "remove unexisting invoice reference (1d28eb5b6fb0)"
        assert toSave.length is models.length
        assert.deepStrictEqual toSave[0].registrations[0].invoiceIds, ['2d28eb5b6fb0']
        done()

    it 'should remove unexisting invoice references from lessons', (done) ->
      report = errors: []
      models = [
        # proper lesson
        new Lesson id: '028b385ca56e', invoiceId: '2d28eb5b6fb0', dancerId: 'ea18ba8a36c9'
        # unexisting invoice
        new Lesson id: '128b385ca56e', invoiceId: '1d28eb5b6fb0', dancerId: 'ea18ba8a36c9'
        new Invoice id: '2d28eb5b6fb0', ref: '2017-08-045', season: '2013/2014', customer: name: 'Emilie Abraham', street: '1 cours Emile Zola', zipcode: '69100', city: 'Villeurbanne'
        new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
        new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
        ]]
        new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
      ]
      tested._checkRelationnalConstraints models, report, (err, toSave) ->
        return done err if err?
        assert report.errors.length is 1
        assert report.errors[0].includes "remove unexisting invoice reference (1d28eb5b6fb0)"
        assert toSave.length is models.length
        assert toSave[1].invoiceId is null
        done()

    it 'should ignore lessons without any dancers', (done) ->
      report = errors: []
      models = [
        # references added dancer
        new Lesson id: '028b385ca56e', dancerId: 'ea18ba8a36c9'
        new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
        new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
        ]]
        # no dancer found
        new Lesson id: '128b385ca56e', dancerId: '0a18ba8a36c9'
        new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
     ]
      tested._checkRelationnalConstraints models, report, (err, toSave) ->
        return done err if err?
        assert report.errors.length is 1
        assert report.errors[0].includes "ignore lesson from teacher 0 at"
        assert report.errors[0].includes "(128b385ca56e) because dancer 0a18ba8a36c9 couldn't be found"
        assert toSave.length is models.length - 1
        assert -1 is toSave.indexOf models[3]
        done()

  describe 'merge()', ->

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
      new Invoice id: 'a763d551db4c', ref: '2016-07-001', selectedTeacher: 0, season: '2016/2017', customer: {name: 'Mlle Mila Montelle', street: '3 rue racine', zipcode: 69100, city: 'Villeurbanne'}, items: [name: 'Forfait 45 minutes enfants/ado', quantity: 1, price: 191, vat: 0, discount: 0], cardId: '3e551fdadd3c', date: '2016-07-01', dueDate: '2016-08-30'
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

      tested.merge imported, (err, {byClass}, conflicts) ->
        return done err if err?
        assert.deepStrictEqual byClass, Dancer: 1, Address: 1, Card: 1
        assert.deepStrictEqual conflicts, []

        Address.find imported[0].id, (err, addr) ->
          return done err if err?
          assert addr.street is imported[0].street
          Dancer.find imported[1].id, (err, dancer) ->
            return done err if err?
            assert dancer.firstname is imported[1].firstname
            Card.find imported[2].id, (err, card) ->
              return done err if err?
              assert.deepStrictEqual card.knownBy, imported[2].knownBy
              done()

    it.skip '! version is not checked anymore !\nshould old imported models not be modified', (done) ->
      tested.merge [
        new Dancer id: 'ea43920b42dc', _v: 0, cardId: '30cb3a48900e', addressId: '3900cc712ba3', title: 'Mme', firstname:'Rachel', lastname:'Toto', birth: '1970-01-01'
      ], (err, byClass, conflicts) ->
        return done err if err?
        assert.deepStrictEqual byClass, {}
        assert.deepStrictEqual conflicts, []

        Dancer.find 'ea43920b42dc', (err, dancer) ->
          return done err if err?
          assert dancer.lastname is 'Durand'
          done()

    it.skip '! version is not checked anymore !\nshould existing models be added with upper version', (done) ->
      imported = [
        new Card id: '30cb3a48900e', _v: 2, knownBy: ['Groupon', 'website'], registrations: [
          new Registration season: '2013/2014', charged: 300, period: 'year'
        ]
      ]

      # when merging new and existing dancers
      tested.merge imported, (err, {byClass}, conflicts) ->
        return done err if err?
        assert.deepStrictEqual byClass, Card: 1
        assert.deepStrictEqual conflicts, []

        # newest imported models have been updated
        Card.find imported[0].id, (err, result) ->
          return done err if err?
          assert.deepStrictEqual result.knownBy, ['Groupon', 'website']
          assert result.registrations.length is 1
          done()

    it 'should conflicts be detected', (done) ->
      imported = [
        new Dancer id: 'ea18ba8a36c9', _v: 1, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083', '00acbfb5e7d6'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
        new Card id: '40b728d54a0d', _v: 1, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 450, period: 'year', payments:[
          new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
          new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
          new Payment type: 'check', value: 150, receipt: '2014-10-14', payer: 'Simonin', bank: 'La Poste'
        ]]
        new Invoice id: 'a763d551db4c', ref: '2016-07-001', selectedTeacher: 0, cardId: '9433f22b3aec', season: '2016/2017', date: '2016-07-06', customer: {name: 'Mlle Mélany Pourriol', street: '51 rue de Fontanières', zipcode: 69100, city: 'Villeurbanne'}, items: [name: 'Forfait 1h enfants/ado', quantity: 1, price: 254], dueDate: '2016-09-04'
      ]

      # when merging new and existing dancers
      tested.merge imported, (err, {byClass}, conflicts) ->
        return done err if err?
        assert.deepStrictEqual byClass, {}

        # three conflicts have been detected
        assert conflicts.length is 3
        assert.deepStrictEqual conflicts[0].existing.toJSON(), existing[6].toJSON()
        assert.deepStrictEqual conflicts[0].imported.toJSON(), imported[0].toJSON()
        assert.deepStrictEqual conflicts[1].existing.toJSON(), existing[3].toJSON()
        assert.deepStrictEqual conflicts[1].imported.toJSON(), imported[1].toJSON()
        assert.deepStrictEqual conflicts[2].existing.toJSON(), existing[12].toJSON()
        assert.deepStrictEqual conflicts[2].imported.toJSON(), imported[2].toJSON()

        # models have not been changed
        Dancer.find imported[0].id, (err, dancer) ->
          return done err if err?
          assert dancer._v is 1
          Card.find imported[1].id, (err, card) ->
            return done err if err?
            assert card._v is 1
            Invoice.find imported[2].id, (err, invoice) ->
              return done err if err?
              assert invoice._v is 1
              done()

    it 'should Invoice reference reuse be considered as conflicts', (done) ->
      imported = [
        new Invoice id: '4513f0bd5997', ref: '2016-07-001', selectedSchool: 1, cardId: '9433f22b3aec', season: '2016/2017', date: '2016-07-06', customer: {name: 'Mlle Mélany Pourriol', street: '51 rue de Fontanières', zipcode: 69100, city: 'Villeurbanne'}, items: [name: 'Forfait 1h enfants/ado', quantity: 1, price: 254], dueDate: '2016-09-04'
      ]

      # when merging new and existing invoices
      tested.merge imported, (err, {byClass}, conflicts) ->
        return done err if err?
        assert.deepStrictEqual byClass, {Invoice: 0}

        # one conflicts has been detected
        assert conflicts.length is 1
        assert.deepStrictEqual conflicts[0].imported.toJSON(), imported[0].toJSON()
        assert.deepStrictEqual conflicts[0].existing, {ref: imported[0].ref, selectedTeacher: imported[0].selectedTeacher}

        # models have not been changed
        Invoice.find imported[0].id, (err, invoice) ->
          assert err?.message?.includes 'not found'
          Invoice.find existing[12].id, (err, invoice) ->
            return done err if err?
            assert invoice._v is 1
            assert invoice.cardId isnt imported[0].cardId
            done()