assert = require 'power-assert'
lab = require 'lab'
{generateId, getAttr, setAttr} = require '../app/src/util/common'

exports.lab = lab.script()
{describe, it, before, after} = exports.lab

describe 'Common utils tests', ->

  it 'should generateId() contains 12 characters', (done) ->
    id = generateId()
    assert typeof id, 'string'
    assert.strictEqual id.length, 12
    done()

  it 'should generateId() only contains hexadecimal characters', (done) ->
    id = generateId()
    for char in id
      assert typeof char, 'string'
      assert ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'].includes char
    done()

  describe 'getAttr unit tests', ->

    it 'should retrieves property', (done) ->
      assert.strictEqual getAttr(x:10, 'x'), 10
      done()

    it 'should retrieves sub object property', (done) ->
      assert.strictEqual getAttr(x: y: 'haha', 'x.y'), 'haha'
      done()

    it 'should retrieves array value', (done) ->
      assert.strictEqual getAttr([0..3], '[2]'), 2
      done()

    it 'should retrieves sub array value', (done) ->
      assert.strictEqual getAttr(x: y: [3..0], 'x.y[3]'), 0
      done()

    it 'should handle complex path', (done) ->
      assert.strictEqual getAttr(x: [{y: true}, {y: false}, {z: 'yeah'}], 'x[1].y'), false
      done()

  describe 'setAttr unit tests', ->

    it 'should modifies propery', (done) ->
      obj = test: true
      setAttr obj, 'x', 10
      assert.deepStrictEqual obj, test: true, x: 10
      done()

    it 'should not create missing sub properties', (done) ->
      assert.throws ->
        setAttr {msg: 'yes'}, 'x.y', true
      , 'No element at x in x.y'
      done()

    it 'should modifies sub object propery', (done) ->
      obj = msg: 'yes', x:{}
      setAttr obj, 'x.y', true
      assert.deepStrictEqual obj, msg: 'yes', x: y:true
      done()

    it 'should modifies array value', (done) ->
      obj = ['a', 'b', 'c']
      setAttr obj, '[1]', false
      assert.deepStrictEqual obj, ['a', false, 'c']
      done()

    it 'should modifies sub array value', (done) ->
      obj = x: ['a', 'b', 'c']
      setAttr obj, 'x[3]', 'd'
      assert.deepStrictEqual obj, x: ['a', 'b', 'c', 'd']
      done()