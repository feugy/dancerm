assert = require 'power-assert'
{generateId, getAttr, setAttr, roundEuro} = require '../app/src/util/common'

describe 'Common utils tests', ->

  it 'should round to upper half euro', (done) ->
    assert roundEuro(5.0) is 5.0
    assert roundEuro(5.15) is 5.5
    assert roundEuro(5.50) is 5.5
    assert roundEuro(5.51) is 6.0
    assert roundEuro(5.6) is 6.0
    done()

  it 'should generateId() contains 12 characters', (done) ->
    id = generateId()
    assert.equal typeof id, 'string'
    assert id.length is 12
    done()

  it 'should generateId() only contains hexadecimal characters', (done) ->
    id = generateId()
    for char in id
      assert.equal typeof char, 'string'
      assert ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'].includes char
    done()

  describe 'getAttr unit tests', ->

    it 'should retrieves property', (done) ->
      assert getAttr(x:10, 'x') is 10
      done()

    it 'should retrieves sub object property', (done) ->
      assert getAttr(x: y: 'haha', 'x.y') is 'haha'
      done()

    it 'should retrieves array value', (done) ->
      assert getAttr([0..3], '[2]') is 2
      done()

    it 'should retrieves sub array value', (done) ->
      assert getAttr(x: y: [3..0], 'x.y[3]') is 0
      done()

    it 'should handle complex path', (done) ->
      assert getAttr(x: [{y: true}, {y: false}, {z: 'yeah'}], 'x[1].y') is false
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
      , /No element at x in x.y/
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