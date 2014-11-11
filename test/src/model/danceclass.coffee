{expect} = require 'chai'
_ = require 'lodash'
moment = require 'moment'
DanceClass = require '../../../app/script/model/danceclass'

describe 'DanceClass model tests', ->

  beforeEach -> DanceClass.drop()
  
  it 'should new dance class be created with default values', ->
    # when creating a dancer withou values
    tested = new DanceClass()
    # then all plain attributes have been set to default
    expect(tested).to.have.property('start').that.equal 'Mon 08:00'
    expect(tested).to.have.property('end').that.equal 'Mon 09:00'
    expect(tested).to.have.property('teacher').that.is.null
    expect(tested).to.have.property('hall').that.is.null
    expect(tested).to.have.property('level').that.is.empty
    expect(tested).to.have.property('kind').that.is.empty
    expect(tested).to.have.property('season').that.is.empty
    expect(tested).to.have.property('color').that.equal 'color1'

  it 'should dance class save raw values', ->
    new DanceClass(
      season: '2013/2014'
      kind: 'salsa'
      teacher: 'Anthony'
      hall: 'Gratte-ciel 1'
      level: '2'
      start: 'Wed 18:15'
      end: 'Wed 19:15'
      color: 'color2'
    ).save().then (saved) ->
      expect(saved).to.have.property('id').that.is.a 'string'
      expect(saved).to.have.property('start').that.equal 'Wed 18:15'
      expect(saved).to.have.property('end').that.equal 'Wed 19:15'
      expect(saved).to.have.property('teacher').that.equal 'Anthony'
      expect(saved).to.have.property('hall').that.equal 'Gratte-ciel 1'
      expect(saved).to.have.property('level').that.equal '2'
      expect(saved).to.have.property('kind').that.equal 'salsa'
      expect(saved).to.have.property('season').that.equal '2013/2014'
      expect(saved).to.have.property('color').that.equal 'color2'

      DanceClass.find(saved.id).then (result) ->
        expect(result.toJSON()).to.deep.equal(saved.toJSON())

  it 'should dance class not save unallowed values', ->
    # when creating a dance class with unallowed attributes
    tested = new DanceClass unallowed: 'toto'
    # then the attribute was not reported and the dance class created
    expect(tested).not.to.have.property 'unallowed'

  it 'should planning be listed', ->
    seasons = ['2014/2015', '2013/2014', '2012/2013']
    # given classes from different seasons
    Promise.all([
      new DanceClass(season:seasons[2], kind: 'ballroom').save()
      new DanceClass(season:seasons[2], kind: 'salsa').save()
      new DanceClass(season:seasons[1], kind: 'ballroom').save()
      new DanceClass(season:seasons[1], kind: 'salsa').save()
      new DanceClass(season:seasons[0], kind: 'ballroom').save()
    ]).then ->
      DanceClass.listSeasons().then (results) ->
        expect(results).to.deep.equal seasons

  it 'should planning be retreived', ->
    seasons = ['2012/2013', '2013/2014', '2014/2015']
    # given classes from different seasons
    Promise.all([
      new DanceClass(season:seasons[0], kind: 'ballroom', start: 'Mon 09:00').save()
      new DanceClass(season:seasons[0], kind: 'salsa', start: 'Tue 09:00').save()
      new DanceClass(season:seasons[1], kind: 'ballroom', start: 'Tue 09:00').save()
      new DanceClass(season:seasons[1], kind: 'salsa', start: 'Mon 09:00').save()
      new DanceClass(season:seasons[2], kind: 'ballroom', start: 'Tue 09:00').save()
    ]).then (classes) ->
      DanceClass.getPlanning(seasons[1]).then (results) ->
        expect(results).to.have.lengthOf 2
        expect(results[0]).to.have.property('id').that.equal classes[3].id
        expect(results[1]).to.have.property('id').that.equal classes[2].id