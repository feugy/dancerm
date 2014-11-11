{expect} = require 'chai'
{generateId, getAttr, setAttr} = require '../../app/script/util/common'

describe 'Common utils tests', ->
  
  it 'should generateId() contains 12 characters', ->
    id = generateId()
    expect(id).to.be.a 'string'
    expect(id).to.have.lengthOf 12

  it 'should generateId() only contains hexadecimal characters', ->
    id = generateId()
    for char in id
      expect(char).to.be.a 'string'
      expect(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']).to.include char

  describe 'getAttr unit tests', ->

    it 'should retrieves property', ->
      expect(getAttr x:10, 'x').to.equal 10

    it 'should retrieves sub object property', ->
      expect(getAttr x: y: 'haha', 'x.y').to.equal 'haha'

    it 'should retrieves array value', ->
      expect(getAttr [0..3], '[2]').to.equal 2

    it 'should retrieves sub array value', ->
      expect(getAttr x: y: [3..0], 'x.y[3]').to.equal 0

    it 'should handle complex path', ->
      expect(getAttr x: [{y: true}, {y: false}, {z: 'yeah'}], 'x[1].y').to.be.false

  describe 'setAttr unit tests', ->

    it 'should modifies propery', ->
      obj = test: true
      setAttr obj, 'x', 10
      expect(obj).to.deep.equal test: true, x: 10

    it 'should not create missing sub properties', ->
      expect(->
        setAttr {msg: 'yes'}, 'x.y', true
      ).to.throw 'No element at x in x.y'

    it 'should modifies sub object propery', ->
      obj = msg: 'yes', x:{}
      setAttr obj, 'x.y', true
      expect(obj).to.deep.equal msg: 'yes', x: y:true

    it 'should modifies array value', ->
      obj = ['a', 'b', 'c']
      setAttr obj, '[1]', false
      expect(obj).to.deep.equal ['a', false, 'c']

    it 'should modifies sub array value', ->
      obj = x: ['a', 'b', 'c']
      setAttr obj, 'x[3]', 'd'
      expect(obj).to.deep.equal x: ['a', 'b', 'c', 'd']