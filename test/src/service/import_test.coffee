define [
  'underscore'
  './import'
  '../model/dancer/dancer'
], (_, Import, Dancer) ->

  describe 'Import service tests', ->

    tested = null
    file = null
    expected = []

    # Utility function for file loading inside before() methods
    # @param name [String] suggested fixture file name (without extension)
    # @param done [Function] setUp done callback
    loadFile = (name, done) ->
      chrome.fileSystem.chooseEntry {
        suggestedName: "../../fixture/#{name}.xlsx"
        acceptsAllTypes: false
        accepts: [
          extensions: ['xlsx'] 
          mimeTypes: ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
        ]}, (fileEntry) ->
          return done "Failed to select original file" unless fileEntry?
          file = fileEntry
          done()

    before (done) ->
      tested = new Import done

    describe 'given a well-formated file', ->

      before (done) ->
        @timeout 60000
        expected = [
          new Dancer title: 'Mlle', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', address:{ street: '31 rue séverine', city: 'Villeurbanne', zipcode:'69100'}, cellphone: '0634144728', email: 'emilieab@live.fr'
          new Dancer title: 'Mlle', firstname:'Nelly', lastname:'Aguilar', address:{ street: '15 rue henri barbusse', city: 'Villeurbanne', zipcode:'69100'}, phone: '0662885285', knownBy: ['associationsBiennal']
          new Dancer title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', address:{ street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode:'69009'}, cellphone: '0640652009', email: 'lila.ainine@yahoo.fr', knownBy: ['Groupon']
          new Dancer title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', address:{ street: '40 rue du rhône allée 5', city: 'Lyon', zipcode:'69007'}, cellphone: '0631063774', phone:'0478613207', email: 'rafystilmot@hotmail.fr', knownBy: ['leaflets']
          new Dancer title: 'Mme', firstname:'Rachel', lastname:'Barbosa', birth: '1970-01-01', address:{ street: '2 rue clément marrot', city: 'Lyon', zipcode:'69007'}, cellphone: '0617979688'
        ]
        loadFile 'import_1', done

      it 'should import extract dancers from xlsx file', (done) ->
        tested.fromFile file, (err, models, report) ->
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