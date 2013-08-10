define [
  './common'
], (common) -> 

  describe 'Common utils tests', ->
    
    it 'should generateId() contains 12 characters', ->
      id = common.generateId()
      expect(id).to.be.a 'string'
      expect(id).to.have.lengthOf 12

    it 'should generateId() only contains hexadecimal characters', ->
      id = common.generateId()
      for char in id
        expect(char).to.be.a 'string'
        expect(['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']).to.include char