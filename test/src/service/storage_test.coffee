define [
  '../model/dancer/dancer'
  '../model/dancer/registration'
  '../model/dancer/payment'
  '../model/planning/planning'
  './storage'
], (Dancer, Registration, Payment, Planning, Storage) -> 

  describe 'Storage service tests', ->
    
    tested = null

    beforeEach (done) ->
      tested = new Storage()
      tested.removeAll Dancer, (err) ->
        return done err if err?
        tested.removeAll Planning, done

    # TODO test different error cases
    # TODO test multiple models isolation

    it 'should Dancer model and its submodels be saved and retrieved', (done) ->
      # given a new dancer model and its submodels
      payment = new Payment type: 'card', value: 150
      registration = new Registration danceclassId: 1, charged: 200, payments: [payment]
      dancer = new Dancer firstname: 'Jean', lastname: 'Dujardin', registrations: [registration]
      # when saving it
      tested.add dancer, (err) ->
        return done err if err?
        # then the dancer can be retrieved
        tested.get dancer.id, Dancer, (err, retrieved) ->
          return done err if err?
          expect(retrieved).to.exist
          expect(retrieved).to.be.an.instanceOf Dancer
          expect(retrieved.toJSON()).to.be.deep.equal dancer.toJSON()
          done()

    it 'should Planning model and its submodels be saved and retrieved', (done) ->
      # given a planning for season 2013
      planning = new Planning
        season: '2013/2014'
        danceClasses: [
          {kind: 'Toutes danses', level: 'débutant', start: 'Wed 19:45', end: 'Wed 20:45', hall: 'Gratte-ciel'}
          {kind: 'Toutes danses', level: 'intermédiaire', start: 'Thu 20:00', end: 'Thu 21:00', hall: 'Gratte-ciel'}
          {kind: 'Toutes danses', level: 'confirmé', start: 'Mon 20:30', end: 'Mon 21:30', hall: 'Gratte-ciel'}
        ]
      # when saving it
      tested.add planning, (err) ->
        return done err if err?
        # then the dancer can be retrieved
        tested.get planning.id, Planning, (err, retrieved) ->
          return done err if err?
          expect(retrieved).to.exist
          expect(retrieved).to.be.an.instanceOf Planning
          expect(retrieved.toJSON()).to.be.deep.equal planning.toJSON()
          done()

    describe 'given an existing dancer', ->

      dancer = null

      beforeEach (done) ->
        dancer = new Dancer firstname: 'Jean', lastname: 'Dujardin'
        tested.add dancer, done

      it 'should dancer be retrieved by key', (done) ->
        # when testing the dancer existence
        tested.has dancer.id, Dancer, (err, exist) ->
          return done err if err?
          # then it exists
          expect(exist).to.be.true

          # when requesting the dancer by its key
          tested.get dancer.id, Dancer, (err, retrieved) ->
            return done err if err?
            # then its returned
            expect(retrieved).to.exist
            expect(retrieved).to.be.an.instanceOf Dancer
            expect(retrieved.toJSON()).to.be.deep.equal dancer.toJSON()
            done()

      it 'should dancer be walked', (done) ->
        length = 0
        # when walking through dancers
        tested.walk Dancer, (model, next) ->
          # then dancer is returned
          expect(model).to.exist
          expect(model.toJSON()).to.be.deep.equal dancer.toJSON()
          length++
          next()
        , (err) ->
          # then only one dancer found
          expect(length).to.be.equal 1
          done err

      it 'should dancer be removed', (done) ->
        # when removing the dancer
        tested.remove dancer, (err) ->
          return done err if err?
          # then it's not any more stored
          tested.has dancer.id, Dancer, (err, exist) ->
            return done err if err?
            # then it exists
            expect(exist).to.be.false
            done()

      it 'should all model be removed', (done) ->
        # when removing all dancers
        tested.removeAll Dancer, (err) ->
          return done err if err?
          # then it's not any more stored
          tested.has dancer.id, Dancer, (err, exist) ->
            return done err if err?
            # then it exists
            expect(exist).to.be.false
            done()