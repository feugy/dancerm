{expect} = require 'chai'
_ = require 'underscore'
Persisted = require '../../../app/script/model/tools/persisted'

describe 'Persisted model tests', ->
  
  # given a test model
  class Tested extends Persisted

    @_transient: Persisted._transient.concat ['fullname']

    # data attributes
    name: null,
    age: 16,
    payments: []
    fullname: null

    custom: (attr...) => attr

  beforeEach (done) ->
    Tested.drop().then done

  it 'should model be constructed', (done) ->
    # when creating a model
    test = new Tested name: 'john', age: 18, payments: [{type: 'card', value: 150}]
    # then all its attributes were set
    expect(test).to.have.property('id').that.is.null
    expect(test).to.have.property('name').that.equal 'john'
    expect(test).to.have.property('age').that.equal 18
    expect(test).to.have.property('payments').that.deep.equal [{type: 'card', value: 150}]
    done()

  it 'should undeclared attribute not be kept and default be used', (done) ->
    # when creating a model with undeclared 
    test = new Tested name: 'sarah', unknown: 'haha !'
    # then all its attributes were set
    expect(test).to.have.property('id').that.is.null
    expect(test).to.have.property('name').that.equal 'sarah'
    expect(test).to.have.property('age').that.equal 16
    expect(test).to.have.property('payments').that.deep.equal []
    expect(test).not.to.have.property 'unknown'
    expect(test.custom(1, 2)).to.deep.equal [1, 2]
    done()

  it 'should toJSON return raw values', (done) ->
    test = new Tested name: 'chlotilde', fullname: 'chlotilde', age: 33, payments: [{type: 'money', value: 100}, {type:'money', value: 150}]
    # when dumping it
    dump = test.toJSON()
    expect(dump).to.have.deep.equal 
      name: 'chlotilde'
      age: 33
      payments: [{type: 'money', value: 100}, {type:'money', value: 150}]
      id: null
      _v: -1
    # then transient properties are not serialized
    expect(dump).not.to.have.property 'fullname'
    done()

  it 'should model be saved and retrieved', (done) ->
    # given a model a model
    test = new Tested name: 'peter', age: 25, payments: [{type: 'check', value: 100}]
    # when saving it
    test.save().then(->
      # then it can be retrieved by id
      Tested.find(test.id).then (retrieved) ->
        # then all its attributes were set
        expect(retrieved).to.be.an.instanceOf Tested
        expect(retrieved).to.have.property('id').that.equal test.id
        expect(retrieved).to.have.property('name').that.equal 'peter'
        expect(retrieved).to.have.property('age').that.equal 25
        expect(retrieved).to.have.property('payments').that.deep.equal [{type: 'check', value: 100}]
        done()
    ).catch done

  it 'should find raise an error on unknown model', (done) ->
    # when finding unknown model
    Tested.find('123457').then( ->
      done new Error "an error should have been raised"
    ).catch (err) ->
      expect(err).to.have.property('message').that.include 'not found'
      done()

  it 'should version be incremented on save', (done) ->
    new Tested(name: 'damien').save().then((saved) ->
      expect(saved).to.have.property('_v').that.equal 0
      saved.save().then (saved) ->
        expect(saved).to.have.property('_v').that.equal 1
        done()
    ).catch done

  describe 'given an existing model', ->

    existing = null

    beforeEach (done) ->
      # given no dancer
      existing = new Tested name: 'peter', age: 25, payments: [{type: 'check', value: 100}]
      existing.save().then -> done()

    it 'should dancer be found by id', (done) ->
      Tested.find(existing.id).then((retrieved) ->
        expect(retrieved).to.exist
        expect(retrieved).to.be.an.instanceOf Tested
        expect(retrieved.toJSON()).to.be.deep.equal _.omit existing.toJSON()
        done()
      ).catch done

    it 'should findWhere() found within array', (done) ->
      # given two another models
      new Tested(name: 'bob', payments: [{type: 'check', value: 100}]).save().then(->

        new Tested(name: 'rob', payments: [{type: 'card', value: 100}]).save().then ->

          # when finding within an array
          Tested.findWhere('payments.type': 'check').then (retrieved) ->
            expect(retrieved).to.exist
            expect(retrieved).to.have.lengthOf 2
            expect(obj).to.be.an.instanceOf Tested for obj in retrieved
            expect(_.findWhere(retrieved, name: 'bob'), 'bob should be found').to.exist
            expect(_.findWhere(retrieved, name: 'peter'), 'peter should be found').to.exist
            expect(_.findWhere(retrieved, name: 'rob'), 'rob should not be found').not.to.exist
            done()
      ).catch done

    it 'should be updated', (done) ->
      # given a modification
      existing.payments.push type: 'card', value: 50
      existing.age = 30
      # when saving it
      existing.save().then( ->
        # then it was saved in storage
        Tested.find(existing.id).catch(done).then (retrieved) ->
          expect(retrieved).to.exist
          expect(retrieved).to.be.an.instanceOf Tested
          expect(retrieved).to.have.property('age').that.equal 30
          expect(retrieved).to.have.property('payments').that.have.lengthOf(2).and.that.deep.equal [
            {type: 'check', value: 100}
            {type: 'card', value: 50}
          ]
          done()
      ).catch done

    # TODO remove, findAll, find with conditions