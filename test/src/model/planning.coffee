{expect} = require 'chai'
_ = require 'underscore'
moment = require 'moment'
Planning = require '../../../app/script/model/planning/planning'
DanceClass = require '../../../app/script/model/planning/danceclass'

describe 'Planning model tests', ->
  
  it 'should new planning be created with default values', ->
    # when creating a planning without values
    tested = new Planning()
    # then an id was set
    expect(tested).to.have.property('id').that.is.null
    # then the dance classes array was set
    expect(tested).to.have.property('danceClasses').that.is.an('array').and.that.have.lengthOf 0
    # then all plain attributes have been set to default
    expect(tested).to.have.property('season').that.equal '2014/2015'

  it 'should planning save raw values', ->
    # given a raw planning
    raw = 
      id: 'anId'
      season: '2012/2013'
      danceClasses: [
        {id: 'salsa2', kind: 'salsa', level: '2', start: 'Wed 18:15', end: 'Wed 19:15', teacher: 'Anthony', hall: 'Gratte-ciel 1'}
        {id: 'salsa1', kind: 'salsa', level: '1', start: 'Wed 17:15', end: 'Wed 18:15', teacher: 'Anthony', hall: 'Croix Luizet'}
      ]

    # when creating a planning with a clone to avoid modifications
    tested = new Planning _.clone raw
    # then all defined attributes have been saved
    expect(tested).to.have.property 'id', raw.id
    expect(tested).to.have.property 'season', raw.season
    # then the registrations have been enriched
    expect(tested).to.have.property 'danceClasses'
    expect(tested.danceClasses).to.be.an 'array'
    for danceClass, i in tested.danceClasses
      expect(danceClass).to.be.an.instanceOf DanceClass
      expect(danceClass.toJSON()).to.deep.equal raw.danceClasses[i]

  it 'should planning not save unallowed values', ->
    # when creating a planning with unallowed attributes
    tested = new Planning unallowed: 'toto'
    # then the attribute was not reported and the planning created
    expect(tested).not.to.have.property 'unallowed'

  describe 'given an existing planning', ->

    planning = null

    before (done) ->
      # given a empty Planning store
      Planning.drop (err) ->
        return done "Failed to remove existing plannings: #{err.message}" if err?
        # given an existing planning
        planning = new Planning season: '2012/2013', danceClasses: [kind: 'salsa', level: '2', start: 'Wed 18:15', end: 'Wed 19:15']
        planning.save done

    it 'should planning be retrieved by key', (done) ->
      # when finding the existing planning
      Planning.find planning.id, (err, model) ->
        return done "Failed to find planning: #{err.message}" if err?
        # then planning is returned
        expect(model).to.exist
        expect(model.toJSON()).to.be.deep.equal planning.toJSON()
        done()

    it 'should unknown planning not be retrieved by key', (done) ->
      # when finding an unknown planning
      Planning.find 'unknown', (err, model) ->
        # then an error is returned
        expect(err).to.exist
        expect(err).to.be.an.instanceOf Error
        expect(err.message).to.include "'unknown' not found"
        expect(model).not.to.exist
        done()

    it 'should multiple models be retrieved', (done) ->
      # given another planning
      planning2 = new Planning season: '2013/2014', danceClasses: []
      planning2.save (err) ->
        return done "Failed to save planning2: #{err.message}" if err?
        # when retrieving all plannings
        Planning.findAll (err, models) ->
          return done "Failed to findAll plannings: #{err.message}" if err?
          # then all planning are returned
          expect(models).to.exist
          expect(models).to.be.an 'array'
          expect(models).to.have.lengthOf 2
          for expected in [planning, planning2]
            model = _.findWhere models, id: expected.id
            expect(model).to.exist
            expect(model.toJSON()).to.be.deep.equal expected.toJSON()
          done()