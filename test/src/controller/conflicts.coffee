_ = require 'lodash'
async = require 'async'
{expect} = require 'chai'
{init} = require '../../../app/script/model/tools/initializer'
Address = require '../../../app/script/model/address'
Card = require '../../../app/script/model/card'
DanceClass = require '../../../app/script/model/dance_class'
Dancer = require '../../../app/script/model/dancer'
Payment = require '../../../app/script/model/payment'
Registration = require '../../../app/script/model/registration'
ConflictsController = require '../../../app/script/controller/conflicts'

describe 'Conflicts controller tests', ->

  # add fixtures
  models = [
    new Address id: '5f3da4e6a884', _v: 0, street: '11 rue des teinturiers', zipcode: 69100, city: 'Villeurbanne', phone: '0954293032'
    new Address id: '3900cc712ba3', _v: 0, street: '2 rue clément marrot', city: 'Lyon', zipcode: 69007
    new Address id: '000bcbc38576', _v: 0, street: '145 avenue sidoine apollinaire', city: 'Lyon', zipcode: 69009
    new Card id: '40b728d54a0d', _v: 0, knownBy: ['pagesjaunesFr', 'website'], registrations: [new Registration season: '2013/2014', charged: 300, period: 'year', payments:[
      new Payment type: 'cash',  value: 150, receipt: '2014-08-04', payer: 'Simonin'
      new Payment type: 'check', value: 150, receipt: '2014-08-26', payer: 'Simonin', bank: 'La Poste'
    ]]
    new Card id: '30cb3a48900e', _v: 0, registrations: [new Registration season: '2014/2015', charged: 0, period: 'year']
    new Card id: 'a8290940b47c', _v: 0, knownBy: ['Groupon']
    new Dancer id: 'ea18ba8a36c9', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['043737c8e083'], title: 'Mme', firstname:'Emilie', lastname:'Abraham', birth: '1991-01-01', cellphone: '0634144728', email: 'emilieab@live.fr'
    new Dancer id: 'fcf3d43e1f6f', _v: 0, cardId: '40b728d54a0d', addressId: '5f3da4e6a884', danceClassIds: ['00acbfb5e7d6', '043737c8e083'], title: 'M.', firstname:'Raphaël', lastname:'Azoulay', birth: '1989-01-01', cellphone: '0631063774', email: 'rafystilmot@hotmail.fr'
    new Dancer id: 'ea43920b42dc', _v: 0, cardId: '30cb3a48900e', addressId: '3900cc712ba3', title: 'Mme', firstname:'Rachel', lastname:'Durand', birth: '1970-01-01', cellphone: '0617979688'
    new Dancer id: '291047bce3ad', _v: 0, cardId: 'a8290940b47c', addressId: '000bcbc38576', title: 'Mlle', firstname:'Lila', lastname:'Ainine', birth: '1986-01-01', cellphone: '0640652009', email: 'lila.ainine@yahoo.fr'
    new DanceClass id: '00acbfb5e7d6', _v: 0, season: '2013/2014', kind: 'Rock/Salsa', color: 'color2', level: 'confirmé', start: 'Mon 20:00', end: 'Mon 21:30', teacher: 'Anthony', hall: 'Croix-Luizet'
    new DanceClass id: '043737c8e083', _v: 0, season: '2013/2014', kind: 'Danse sportive/Rock/Salsa', color: 'color3', level: '2 8/12 ans', start: 'Wed 17:30', end: 'Wed 18:30', teacher: 'Anthony', hall: 'Gratte-ciel 2'
    new DanceClass id: '00117fb1e188', _v: 0, season: '2013/2014', kind: 'Initiation', color: 'color1', level: '5/7 ans', start: 'Mon 17:00', end: 'Mon 17:45', teacher: 'Anthony', hall: 'Gratte-ciel 2'
    new DanceClass id: '0249f2c4b254', _v: 0, season: '2014/2015', kind: 'Danse sportive/Rock/Salsa', color: 'color3', level: '1 8/12 ans', start: 'Wed 16:30', end: 'Wed 17:30', teacher: 'Anthony', hall: 'Gratte-ciel 2'
    new Address id: 'f2569714287b', _v: 0, street: '1 cours Emile Zola', city: 'Villeurbanne', zipcode: 69100
  ]

  before init

  beforeEach (done) ->
    async.each [Card, Address, Dancer, DanceClass], (clazz, next) ->
      clazz.drop next
    , (err) ->
      return done err if err?
      async.map models, (model, next) ->
        model.save next
      , (err, saved) ->
        # make copies for comparison
        models = (new save.constructor save.toJSON() for save in saved)
        done err

  # build tested controller
  buildController = (conflicts, close, done, apply = ->) ->
    new ConflictsController {$apply: ->}, conflicts, {}, {close: close}, {trustAsHtml: (obj) -> obj}, {}, done

  it 'should not displayed conflict if no conflicts found', (done) ->
    buildController [], done, (->), => done new Error '$apply must not be invoked'

  it 'should displayed first conflict at construction', (done) ->
    newName = 'Mélanie'
    ctrl = buildController [{
      existing: models[6]
      imported: new Dancer _.extend models[6].toJSON(), firstname: newName
    },{
      existing: models[7]
      imported: new Dancer _.extend models[7].toJSON(), cellphone: '0601020304'
    }], (=> done new Error 'close must not be called'), (err) =>
      return done err if err?
      expect(ctrl.fields).to.have.lengthOf 1
      # then firstname change was identified
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'firstname'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'firstname'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal models[6].firstname
      expect(ctrl.fields[0]).to.have.property('imported').that.equal newName
      done()

  it 'should find address changes and associate them to first dancer', (done) ->
    newStreet = '19 rue Francis de Préssensé'
    newPhone = '0407080910'
    ctrl = buildController [
      existing: models[0]
      imported: new Address _.extend models[0].toJSON(), street: newStreet, phone: newPhone
    ], (=> done new Error 'close must not be called'), (err) =>
      return done err if err?
      expect(ctrl.fields).to.have.lengthOf 2
      # then street change was identified
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'street'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_address'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'street'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal models[0].street
      expect(ctrl.fields[0]).to.have.property('imported').that.equal newStreet
      # then phone change was identified
      expect(ctrl.fields[1]).to.have.property('label').that.equal 'phone'
      expect(ctrl.fields[1]).to.have.property('parentPath').that.equal '_address'
      expect(ctrl.fields[1]).to.have.property('path').that.equal 'phone'
      expect(ctrl.fields[1]).to.have.property('existing').that.equal models[0].phone
      expect(ctrl.fields[1]).to.have.property('imported').that.equal newPhone
      # then dancer was resolved from storage, either existing and imported
      expect(ctrl.conflicts[ctrl.rank].existing).to.be.an.instanceOf Dancer
      expect(ctrl.conflicts[ctrl.rank].existing.toJSON()).to.deep.equal models[6].toJSON()
      expect(ctrl.conflicts[ctrl.rank].imported).to.be.an.instanceOf Dancer
      expect(ctrl.conflicts[ctrl.rank].imported.toJSON()).to.deep.equal models[6].toJSON()
      done()

  it 'should handle address changes not associated to dancer', (done) ->
    buildController [
      existing: models[14]
      imported: new Address _.extend models[14].toJSON(), street: '19 rue Francis de Préssensé'
    ], done, (->) , => done new Error '$apply must not be invoked'

  it 'should find card changes and associate them to first dancer', (done) ->
    newCharged = 350
    newKnownBy = ['pagesjaunes.fr', 'website', 'elders']
    newPayment = new Payment type: 'cash', value: 50, receipt: '2014-10-01', payer: 'Simonin'
    newCard = new Card _.extend models[3].toJSON(), knownBy: newKnownBy
    newCard.registrations[0].charged = newCharged
    newCard.registrations[0].payments.push newPayment
    ctrl = buildController [
      existing: models[3]
      imported: newCard
    ], (=> done new Error 'close must not be called'), (err) =>
      return done err if err?
      expect(ctrl.fields).to.have.lengthOf 3
      # then card's change was identified
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'knownBy'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'knownBy'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal 'pagesjaunes.fr, site web'
      expect(ctrl.fields[0]).to.have.property('imported').that.equal 'pagesjaunes.fr, site web, anciens'
      # then registration's change was identified
      expect(ctrl.fields[1]).to.have.property('label').that.equal 'charged'
      expect(ctrl.fields[1]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[1]).to.have.property('path').that.equal 'registrations[0].charged'
      expect(ctrl.fields[1]).to.have.property('existing').that.equal ''+models[3].registrations[0].charged
      expect(ctrl.fields[1]).to.have.property('imported').that.equal ''+newCharged
      # then payement's addition was identified
      expect(ctrl.fields[2]).to.have.property('kind').that.equal 'payment'
      expect(ctrl.fields[2]).to.have.property('season').that.equal models[3].registrations[0].season
      expect(ctrl.fields[2]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[2]).to.have.property('path').that.equal 'registrations[0].payments[2]'
      expect(ctrl.fields[2]).to.have.property('imported').that.deep.equal ctrl._formatPayment newPayment
      # then dancer was resolved from storage, either existing and imported
      expect(ctrl.conflicts[ctrl.rank].existing).to.be.an.instanceOf Dancer
      expect(ctrl.conflicts[ctrl.rank].existing.toJSON()).to.deep.equal models[6].toJSON()
      expect(ctrl.conflicts[ctrl.rank].imported).to.be.an.instanceOf Dancer
      expect(ctrl.conflicts[ctrl.rank].imported.toJSON()).to.deep.equal models[6].toJSON()
      done()

  it 'should save modified dancer', (done) ->
    # given a conflicted dancer
    newName = 'Rachelle'
    ctrl = buildController [{
      existing: models[8]
      imported: new Dancer _.extend models[8].toJSON(), firstname: newName
    }], (=>
      # then model was saved
      Dancer.find models[8].id, (err, saved) =>
        return done err if err?
        console.log saved.toJSON(), _.extend models[8].toJSON(), firstname: newName, _v: models[8]._v+1
        expect(saved.toJSON()).to.deep.equal _.extend models[8].toJSON(), firstname: newName, _v: models[8]._v+1
        done()
    ), =>
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save added dance class', (done) ->
    # given a conflicted dancer
    modified = new Dancer models[6].toJSON()
    modified.danceClassIds.push models[12].id
    ctrl = buildController [{
      existing: models[6]
      imported: modified
    }], (=>
      # then model was saved
      Dancer.find models[6].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[6].toJSON(), _v: models[6]._v+1, danceClassIds: [models[11].id, models[12].id]
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('season').that.equal '2013/2014'
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'danceClasses'
      expect(ctrl.fields[0]).to.have.property('danceClassAdded').that.deep.equal [models[12].id]
      expect(ctrl.fields[0]).to.have.property('danceClassRemoved').that.has.lengthOf 0
      expect(ctrl.fields[0]).to.have.property('existing').that.equal "#{models[11].kind} #{models[11].level}"
      expect(ctrl.fields[0]).to.have.property('imported').that.equal "#{models[11].kind} #{models[11].level}, #{models[12].kind} #{models[12].level}"
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save removed dance class', (done) ->
    # given a conflicted dancer
    modified = new Dancer models[7].toJSON()
    modified.danceClassIds.splice 1, 1
    ctrl = buildController [{
      existing: models[7]
      imported: modified
    }], (=>
      # then model was saved
      Dancer.find models[7].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[7].toJSON(), _v: models[7]._v+1, danceClassIds: [models[10].id]
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('season').that.equal '2013/2014'
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'danceClasses'
      expect(ctrl.fields[0]).to.have.property('danceClassAdded').that.has.lengthOf 0
      expect(ctrl.fields[0]).to.have.property('danceClassRemoved').that.deep.equal [models[11].id]
      expect(ctrl.fields[0]).to.have.property('existing').that.equal "#{models[10].kind} #{models[10].level}, #{models[11].kind} #{models[11].level}"
      expect(ctrl.fields[0]).to.have.property('imported').that.equal "#{models[10].kind} #{models[10].level}"
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save changed address', (done) ->
    ctrl = buildController [{
      existing: models[7]
      imported: new Dancer _.extend models[7].toJSON(), addressId: models[1].id
    }], (=>
      # then model was saved
      Dancer.find models[7].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[7].toJSON(), _v: models[7]._v+1, addressId: models[1].id
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('kind').that.equal 'address'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'addressId'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal "<div>#{models[0].street} #{models[0].zipcode} #{models[0].city}</div>"
      expect(ctrl.fields[0]).to.have.property('imported').that.equal "<div>#{models[1].street} #{models[1].zipcode} #{models[1].city}</div>"
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save modified address', (done) ->
    # given a conflicted address
    newZipcode = 69008
    ctrl = buildController [{
      existing: models[1]
      imported: new Address _.extend models[1].toJSON(), zipcode: newZipcode
    }], (=>
      # then model was saved
      Address.find models[1].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[1].toJSON(), _v: models[1]._v+1, zipcode: newZipcode
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_address'
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'zipcode'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'zipcode'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal ''+models[1].zipcode
      expect(ctrl.fields[0]).to.have.property('imported').that.equal ''+newZipcode
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save new registration and danceclass', (done) ->
    # given a conflicted card
    newRegistration = new Registration season: '2014/2015', charged: 300, period: 'year'
    modified = new Card models[3].toJSON()
    modified.registrations.push newRegistration
    ctrl = buildController [{
      existing: models[3]
      imported: modified
    }], (=>
      # then model was saved
      Card.find models[3].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[3].toJSON(), _v: models[3]._v+1, registrations: models[3].toJSON().registrations.concat [newRegistration.toJSON()]
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('season').that.equal newRegistration.season
      expect(ctrl.fields[0]).to.have.property('kind').that.equal 'registration'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'registrations[1]'
      expect(ctrl.fields[0]).to.have.property('danceClassAdded').that.has.lengthOf 0
      expect(ctrl.fields[0]).to.have.property('imported').that.equal """<div>#{newRegistration.season}</div>
        <div>Cours :&nbsp;#{}</div>
        <div>Réglement de :&nbsp;#{newRegistration.charged} € (à l'année)</div>\n"""
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save modified registration', (done) ->
    # given a conflicted registration
    newDetails = 'something not really useful'
    certified = models[6].id
    modified = new Card models[3].toJSON()
    registration = modified.registrations[0]
    registration.details = newDetails
    registration.certificates[certified] = true
    ctrl = buildController [{
      existing: models[3]
      imported: modified
    }], (=>
      # then model was saved
      Card.find models[3].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[3].toJSON(), _v: models[3]._v+1, registrations: [registration.toJSON()]
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 2
      expect(ctrl.fields[0]).to.have.property('season').that.equal registration.season
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'details'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'registrations[0].details'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal ''
      expect(ctrl.fields[0]).to.have.property('imported').that.equal newDetails
      ctrl.fields[0].useImported = true
      expect(ctrl.fields[1]).to.have.property('season').that.equal registration.season
      expect(ctrl.fields[1]).to.have.property('label').that.equal 'certificates'
      expect(ctrl.fields[1]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[1]).to.have.property('path').that.equal 'registrations[0].certificates'
      expect(ctrl.fields[1]).to.have.property('existing').that.equal 0
      expect(ctrl.fields[1]).to.have.property('imported').that.equal 1
      ctrl.fields[1].useImported = true
      # when saving it
      ctrl.save()

  it 'should save removed registration', (done) ->
    # given a conflicted registration
    modified = new Card models[3].toJSON()
    removed = modified.registrations.pop()
    ctrl = buildController [{
      existing: models[3]
      imported: modified
    }], (=>
      # then model was saved
      Card.find models[3].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[3].toJSON(), _v: models[3]._v+1, registrations: []
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('season').that.equal removed.season
      expect(ctrl.fields[0]).to.have.property('kind').that.equal 'registration'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'registrations'
      expect(ctrl.fields[0]).to.have.property('spliced').that.equal 0
      expect(ctrl.fields[0]).to.have.property('existing').that.equal """<div>#{removed.season}</div>
        <div>Cours :&nbsp;#{models[11].kind} #{models[11].level}</div>
        <div>Réglement de :&nbsp;#{removed.charged} € (à l'année)</div>
        <div>04/08/2014 - 150 € Espèces (Simonin) </div>
        <div>26/08/2014 - 150 € Chèque (Simonin) </div>"""
      expect(ctrl.fields[0]).not.to.have.property 'imported'
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()


  it 'should save new payment', (done) ->
    # given a conflicted card
    newPayment = new Payment type: 'traveler',  value: 100, receipt: '2014-10-04', payer: 'Durand'
    modified = new Card models[4].toJSON()
    modified.registrations[0].payments.push newPayment
    ctrl = buildController [{
      existing: models[4]
      imported: modified
    }], (=>
      # then model was saved
      Card.find models[4].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[4].toJSON(), _v: models[4]._v+1, registrations: [_.extend models[4].registrations[0].toJSON(), payments: [newPayment.toJSON()]]
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('season').that.equal modified.registrations[0].season
      expect(ctrl.fields[0]).to.have.property('kind').that.equal 'payment'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'registrations[0].payments[0]'
      expect(ctrl.fields[0]).to.have.property('imported').that.equal '<div>04/10/2014 - 100 € ANCV (Durand) </div>'
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should saved modified payment as a whole', (done) ->
    # given a conflicted card
    modified = new Card models[3].toJSON()
    newType = 'traveler'
    modified.registrations[0].payments[1].type = newType
    ctrl = buildController [{
      existing: models[3]
      imported: modified
    }], (=>
      # then model was saved
      Card.find models[3].id, (err, saved) =>
        return done err if err?
        copy = _.extend models[3].toJSON(), _v: models[3]._v+1
        copy.registrations[0].payments[1].type = newType
        expect(saved.toJSON()).to.deep.equal copy
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('season').that.equal modified.registrations[0].season
      expect(ctrl.fields[0]).to.have.property('kind').that.equal 'payment'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'registrations[0].payments[1]'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal '<div>26/08/2014 - 150 € Chèque (Simonin) </div>'
      expect(ctrl.fields[0]).to.have.property('imported').that.equal '<div>26/08/2014 - 150 € ANCV (Simonin) </div>'
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save removed payment', (done) ->
    # given a conflicted card
    modified = new Card models[3].toJSON()
    removed = modified.registrations[0].payments.pop()
    ctrl = buildController [{
      existing: models[3]
      imported: modified
    }], (=>
      # then model was saved
      Card.find models[3].id, (err, saved) =>
        return done err if err?
        copy = _.extend models[3].toJSON(), _v: models[3]._v+1
        copy.registrations[0].payments.pop()
        expect(saved.toJSON()).to.deep.equal copy
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('season').that.equal modified.registrations[0].season
      expect(ctrl.fields[0]).to.have.property('kind').that.equal 'payment'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'registrations[0].payments'
      expect(ctrl.fields[0]).to.have.property('spliced').that.equal 1
      expect(ctrl.fields[0]).to.have.property('existing').that.equal '<div>26/08/2014 - 150 € Chèque (Simonin) </div>'
      expect(ctrl.fields[0]).not.to.have.property 'imported'
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save changed card', (done) ->
    ctrl = buildController [{
      existing: models[7]
      imported: new Dancer _.extend models[7].toJSON(), cardId: models[4].id
    }], (=>
      # then model was saved
      Dancer.find models[7].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend models[7].toJSON(), _v: models[7]._v+1, cardId: models[4].id
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('kind').that.equal 'card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'cardId'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal """
        <div>pagesjaunes.fr, site web</div>
        <ul><li><div>2013/2014</div>
        <div>Cours :&nbsp;Rock/Salsa confirmé, Danse sportive/Rock/Salsa 2 8/12 ans</div>
        <div>Réglement de :&nbsp;300 € (à l'année)</div>
        <div>04/08/2014 - 150 € Espèces (Simonin) </div>
        <div>26/08/2014 - 150 € Chèque (Simonin) </div></li></ul>"""
      expect(ctrl.fields[0]).to.have.property('imported').that.equal """
        <div></div>
        <ul><li><div>2014/2015</div>
        <div>Cours :&nbsp;</div>
        <div>Réglement de :&nbsp;0 € (à l'année)</div>
        </li></ul>"""
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()

  it 'should save modified card', (done) ->
    # given a conflicted card
    newKnownBy = ['website', 'elders']
    modified = new Card _.extend models[5].toJSON(), knownBy: newKnownBy
    ctrl = buildController [{
      existing: models[5]
      imported: modified
    }], (=>
      # then model was saved
      Card.find models[5].id, (err, saved) =>
        return done err if err?
        expect(saved.toJSON()).to.deep.equal _.extend modified.toJSON(), _v: models[5]._v+1
        done()
    ), =>
      expect(ctrl.fields).to.have.lengthOf 1
      expect(ctrl.fields[0]).to.have.property('label').that.equal 'knownBy'
      expect(ctrl.fields[0]).to.have.property('parentPath').that.equal '_card'
      expect(ctrl.fields[0]).to.have.property('path').that.equal 'knownBy'
      expect(ctrl.fields[0]).to.have.property('existing').that.equal 'Groupon'
      expect(ctrl.fields[0]).to.have.property('imported').that.equal 'site web, anciens'
      ctrl.fields[0].useImported = true
      # when saving it
      ctrl.save()


    # TODO merge a card with 2 dancers into one, and resolve conflicts