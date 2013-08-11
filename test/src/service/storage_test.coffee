define [
  '../model/dancer'
  '../model/registration'
  '../model/payment'
  '../model/danceclass'
  './storage'
], (Dancer, Registration, Payment, DanceClass, Storage) -> 

  describe 'Storage service tests', ->
    
    tested = null

    before (done) ->
      tested = new Storage()
      tested.removeAll Dancer, (err) ->
        return done err if err?
        tested.removeAll DanceClass, done

    # TODO test different error cases
    # TODO test multiple models isolation

    it 'should model and its submodels be saved and retrieved', (done) ->
      # given a new dancer model and its submodels
      payment = new Payment type: 'card', value: 150
      registration = new Registration danceclassId: 1, charged: 200, payments: [payment]
      dancer = new Dancer firstname: 'Jean', lastname: 'Dujardin', registrations: [registration]
      # when saving it
      tested.push dancer, (err) ->
        return done err if err?
        # then the dancer can be retrieved
        tested.pop dancer.id, Dancer, (err, retrieved) ->
          return done err if err?
          expect(retrieved).to.exist
          expect(retrieved).to.be.an.instanceOf Dancer
          expect(retrieved.toJSON()).to.be.deep.equal dancer.toJSON()
          done()

    describe 'given an existing dancer', ->

      dancer = null

      before (done) ->
        dancer = new Dancer firstname: 'Jean', lastname: 'Dujardin'
        tested.push dancer, done

      it 'should dancer be retrieved by key', (done) ->
        # when testing the dancer existence
        tested.has dancer.id, Dancer, (err, exist) ->
          return done err if err?
          # then it exists
          expect(exist).to.be.true

          # when requesting the dancer by its key
          tested.pop dancer.id, Dancer, (err, retrieved) ->
            return done err if err?
            # then its returned
            expect(retrieved).to.exist
            expect(retrieved).to.be.an.instanceOf Dancer
            expect(retrieved.toJSON()).to.be.deep.equal dancer.toJSON()
            done()

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