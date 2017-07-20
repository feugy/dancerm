assert = require 'power-assert'
_ = require 'lodash'
{each} = require 'async'
{init} = require '../../app/src/model/tools/initializer'
Persisted = require '../../app/src/model/tools/persisted'

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

  before init

  beforeEach (done) ->
    Tested.drop done

  it 'should model be constructed', (done) ->
    # when creating a model
    test = new Tested name: 'john', age: 18, payments: [{type: 'card', value: 150}]
    # then all its attributes were set
    assert test.id is null
    assert test.name is 'john'
    assert test.age is 18
    assert.deepStrictEqual test.payments, [{type: 'card', value: 150}]
    done()

  it 'should undeclared attribute not be kept and default be used', (done) ->
    # when creating a model with undeclared
    test = new Tested name: 'sarah', unknown: 'haha !'
    # then all its attributes were set
    assert test.id is null
    assert test.name is 'sarah'
    assert test.age is 16
    assert.deepStrictEqual test.payments,  []
    assert not test.unknown?
    assert.deepStrictEqual test.custom(1, 2), [1, 2]
    done()

  it 'should toJSON return raw values', (done) ->
    test = new Tested name: 'chlotilde', fullname: 'chlotilde', age: 33, payments: [{type: 'money', value: 100}, {type:'money', value: 150}]
    # when dumping it
    dump = test.toJSON()
    assert.deepStrictEqual dump,
      name: 'chlotilde'
      age: 33
      payments: [{type: 'money', value: 100}, {type:'money', value: 150}]
      id: null
      _v: -1
    # then transient properties are not serialized
    assert not dump.fullname?
    done()

  it 'should model be saved and retrieved', (done) ->
    # given a model a model
    test = new Tested name: 'peter', age: 25, payments: [{type: 'check', value: 100}]
    # when saving it
    test.save (err) ->
      return done err if err?
      # then it can be retrieved by id
      Tested.find test.id, (err, retrieved) ->
        return done err if err?
        # then all its attributes were set
        assert retrieved instanceof Tested
        assert retrieved.id is test.id
        assert retrieved.name is 'peter'
        assert retrieved.age is 25
        assert.deepStrictEqual retrieved.payments, [{type: 'check', value: 100}]
        done()

  it 'should find raise an error on unknown model', (done) ->
    # when finding unknown model
    Tested.find '123457', (err) ->
      assert err.message.includes 'not found'
      done()

  it 'should version be incremented on save', (done) ->
    new Tested(name: 'damien').save (err, saved) ->
      return done err if err?
      assert saved._v is 0
      saved.save (err, saved) ->
        return done err if err?
        assert saved._v is 1
        done()

  describe 'given an existing model', ->

    existing = null

    beforeEach (done) ->
      Tested.drop (err) ->
        # given no dancer
        existing = new Tested name: 'peter', age: 25, payments: [{type: 'check', value: 100}]
        existing.save done

    it 'should model be found by id', (done) ->
      Tested.find existing.id, (err, retrieved) ->
        return done err if err?
        assert retrieved
        assert retrieved instanceof Tested
        assert.deepStrictEqual retrieved.toJSON(), _.omit existing.toJSON()
        done()

    it 'should findWhere() found within array', (done) ->
      # given two another models
      new Tested(name: 'bob', payments: [{type: 'check', value: 100}]).save (err) ->
        return done err if err?
        new Tested(name: 'rob', payments: [{type: 'card', value: 100}]).save (err) ->
          return done err if err?
          # when finding within an array
          Tested.findWhere 'payments.type': 'check', (err, retrieved) ->
            return done err if err?
            assert retrieved
            assert retrieved.length is 2
            assert obj instanceof Tested for obj in retrieved
            assert _.find(retrieved, name: 'bob'), 'bob should be found'
            assert _.find(retrieved, name: 'peter'), 'peter should be found'
            assert not _.find(retrieved, name: 'rob'), 'rob should not be found'
            done()

    it 'should findWhere() found with $or condition', (done) ->
      # given several models
      each [
        new Tested name: 'luc', payments: [{type: 'cash', value: 100}]
        new Tested name: 'lucie', payments: []
        new Tested name: 'babette', payments: [{type: 'cash', value: 150}]
        new Tested name: 'marie', payments: [{type: 'ancv', value: 50}, {type: 'cash', value: 100}]
        new Tested name: 'jean', payments: [{type: 'check', value: 100}]
      ], ((model, next) -> model.save next), (err) ->
        return done err if err?
        # when selecting with an $or condition
        Tested.findWhere $or: [{name: /^lu/}, {'payments.type': 'cash'}], (err, retrieved) ->
          return done err if err?
          assert retrieved
          assert retrieved.length is 4
          assert obj instanceof Tested for obj in retrieved
          assert _.find(retrieved, name: 'luc'), 'luc should be found'
          assert _.find(retrieved, name: 'lucie'), 'lucie should be found'
          assert _.find(retrieved, name: 'babette'), 'babette should be found'
          assert _.find(retrieved, name: 'marie'), 'marie should be found'
          assert not _.find(retrieved, name: 'jean'), 'jean should not be found'
          done()

    it 'should be updated', (done) ->
      # given a modification
      existing.payments.push type: 'card', value: 50
      existing.age = 30
      # when saving it
      existing.save (err) ->
        return done err if err?
        # then it was saved in storage
        Tested.find existing.id, (err, retrieved) ->
          return done err if err?
          assert retrieved
          assert retrieved instanceof Tested
          assert retrieved.age is 30
          assert retrieved.payments.length is 2
          assert.deepStrictEqual retrieved.payments, [
            {type: 'check', value: 100}
            {type: 'card', value: 50}
          ]
          done()

    # TODO remove, findAll, find with conditions