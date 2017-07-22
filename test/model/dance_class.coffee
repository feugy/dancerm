assert = require 'power-assert'
_ = require 'lodash'
async = require 'async'
moment = require 'moment'
{init} = require '../../app/src/model/tools/initializer'
DanceClass = require '../../app/src/model/dance_class'

describe 'DanceClass model tests', ->

  before init

  beforeEach (done) -> DanceClass.drop done

  it 'should new dance class be created with default values', (done) ->
    # when creating a dancer withou values
    tested = new DanceClass()
    # then all plain attributes have been set to default
    assert tested.start is 'Mon 08:00'
    assert tested.end is 'Mon 09:00'
    assert tested.teacher is null
    assert tested.hall is null
    assert tested.level is ''
    assert tested.kind is ''
    assert tested.season is ''
    assert tested.color is 'color1'
    done()

  it 'should dance class save raw values', (done) ->
    new DanceClass(
      season: '2013/2014'
      kind: 'salsa'
      teacher: 'Anthony'
      hall: 'Gratte-ciel 1'
      level: '2'
      start: 'Wed 18:15'
      end: 'Wed 19:15'
      color: 'color2'
    ).save (err, saved) ->
      return done err if err?
      assert typeof saved.id is 'string'
      assert saved.start is 'Wed 18:15'
      assert saved.end is 'Wed 19:15'
      assert saved.teacher is 'Anthony'
      assert saved.hall is 'Gratte-ciel 1'
      assert saved.level is '2'
      assert saved.kind is 'salsa'
      assert saved.season is '2013/2014'
      assert saved.color is 'color2'

      DanceClass.find saved.id, (err, result) ->
        return done err if err?
        assert.deepStrictEqual result.toJSON(), saved.toJSON()
        done()

  it 'should dance class not save unallowed values', (done) ->
    # when creating a dance class with unallowed attributes
    tested = new DanceClass unallowed: 'toto'
    # then the attribute was not reported and the dance class created
    assert not tested.unallowed?
    done()

  it 'should planning be listed', (done) ->
    seasons = ['2014/2015', '2013/2014', '2012/2013']
    # given classes from different seasons
    async.parallel [
      (next) -> new DanceClass(season:seasons[2], kind: 'ballroom').save next
      (next) -> new DanceClass(season:seasons[2], kind: 'salsa').save next
      (next) -> new DanceClass(season:seasons[1], kind: 'ballroom').save next
      (next) -> new DanceClass(season:seasons[1], kind: 'salsa').save next
      (next) -> new DanceClass(season:seasons[0], kind: 'ballroom').save next
    ], (err) ->
      return done err if err?
      DanceClass.listSeasons (err, results) ->
        return done err if err?
        assert.deepStrictEqual results, seasons
        done()

  it 'should planning be retreived', (done) ->
    seasons = ['2012/2013', '2013/2014', '2014/2015']
    # given classes from different seasons
    async.map [
      new DanceClass season:seasons[0], kind: 'ballroom', start: 'Mon 09:00'
      new DanceClass season:seasons[0], kind: 'salsa', start: 'Tue 09:00'
      new DanceClass season:seasons[1], kind: 'ballroom', start: 'Tue 09:00'
      new DanceClass season:seasons[1], kind: 'salsa', start: 'Mon 09:00'
      new DanceClass season:seasons[2], kind: 'ballroom', start: 'Tue 09:00'
    ], (model, next) ->
      model.save next
    , (err, classes) ->
      return done err if err?
      DanceClass.getPlanning seasons[1], (err, results) ->
        return done err if err?
        assert results.length is 2
        assert results[0].id is classes[3].id
        assert results[1].id is classes[2].id
        done()