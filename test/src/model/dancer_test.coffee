define [
  'underscore'
  'moment'
  './dancer'
  './address'
  './registration'
  './payment'
], (_, moment, Dancer, Address, Registration, Payment) -> 

  describe 'Dancer model tests', ->
    
    it 'should new dancer be created with default values', ->
      # when creating a dancer withou values
      tested = new Dancer()
      # then an id was set
      expect(tested).to.have.property 'id'
      expect(tested.id).to.be.a 'string'
      expect(tested.id).to.have.lengthOf 12
      # then the creation date was set
      expect(tested).to.have.property 'created'
      expect(tested.created.valueOf()).to.be.closeTo moment().valueOf(), 500
      # then registrations is an empty array
      expect(tested).to.have.property 'registrations'
      expect(tested.registrations).to.be.an 'array'
      expect(tested.registrations).to.have.lengthOf 0
      # then all plain attributes have been set to default
      expect(tested).to.have.property 'firstname', ''
      expect(tested).to.have.property 'lastname', ''
      expect(tested).to.have.property 'address', null
      expect(tested).to.have.property 'email', null
      expect(tested).to.have.property 'phone', null
      expect(tested).to.have.property 'birth', null
      expect(tested).to.have.property 'certified', false

    it 'should dancer save raw values', ->
      # given a raw dancer
      raw = 
        id: 'anId'
        created: moment().toJSON()
        firstname: 'Jean'
        lastname: 'Dujardin'
        address:
          street: '15 place de la bourse'
          zipcode: 69100
          city: 'Villeurbanne'
        registrations: [
          danceclassId: 1
          charged: 300
          balance: 200
          payments: [
            type: 'cash'
            value: 100
            duration: 3
            details: null
            receipt: moment().toJSON()
          ,
            type: 'check'
            value: 50
            duration: 3
            details: 'something'
            receipt: moment().toJSON()
          , 
            type: 'card'
            value: 50
            details: null
            duration: 6
            receipt: moment().toJSON()
          ]
        ,
          danceclassId: 2
          charged: 300
          balance: 300
          payments: [
            type: 'cash'
            value: 300
            duration: 12
            details: null
            receipt: moment().toJSON()
          ]
        ]

      # when creating a dancer with a clone to avoid modifications
      tested = new Dancer _.clone raw
      # then all defined attributes have been saved
      expect(tested).to.have.property 'id', raw.id
      expect(tested).to.have.property 'firstname', raw.firstname
      expect(tested).to.have.property 'lastname', raw.lastname
      # then the address have been enriched
      expect(tested).to.have.property 'address'
      expect(tested.address).to.be.an.instanceOf Address
      expect(tested.address.toJSON()).to.deep.equal raw.address
      # then the registrations have been enriched
      expect(tested).to.have.property 'registrations'
      expect(tested.registrations).to.be.an 'array'
      for registration, i in tested.registrations
        expect(registration).to.be.an.instanceOf Registration
        expect(_.omit registration.toJSON(), 'payments').to.deep.equal _.omit raw.registrations[i], 'payments'
        for payment, j in registration.payments
          expect(payment).to.be.an.instanceOf Payment
          expect(payment.toJSON()).to.deep.equal raw.registrations[i].payments[j]
      # then the creation date have been enriched
      expect(tested.created.isSame raw.created).to.be.true
      expect(_.pick tested.toJSON(), 'id', 'created', 'firstname', 'lastname', 'address').to.deep.equal _.omit raw, 'registrations'

    it 'should dancer not save unallowed values', ->
      # when creating a dancer with unallowed attributes
      tested = new Dancer unallowed: 'toto'
      # then the attribute was not reported and the dancer created
      expect(tested).not.to.have.property 'unallowed'
