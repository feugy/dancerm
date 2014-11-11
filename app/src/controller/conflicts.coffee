_ = require 'lodash'
Dancer = require '../model/dancer'
Address = require '../model/address'
Card = require '../model/card'
DanceClass = require '../model/danceclass'
i18n = require '../labels/common'
{setAttr, getAttr} = require '../util/common'

# Display conflict resolution, pair by pair
module.exports = class ConflictsController

  # Controller dependencies
  @$inject: ['$rootScope', 'conflicts', '$modalInstance', '$sce']

  # Popup declaration
  @declaration:
    controller: ConflictsController
    controllerAs: 'ctrl'
    templateUrl: 'conflicts.html'

  # list of conflicts, with `existing` and `imported` properties
  conflicts: []

  # display name of edited dancer
  name: ''

  # list of currently edited fields
  fields: []

  # currently displayed conflict rank
  rank: 0

  # currently resolved existing model
  existing: null

  # currently resolved imported model
  imported: null

  # list of al possible dance classes, stored by ids
  danceClasses: {}

  # Angular's Strict Contextual Escaping facility
  sce: null

  # **private**
  # Current dialog instance
  _dialog: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param rootScope [Object] Angular's root scope for refreshs
  # @param rawConflicts [Object] list of conflicts, with `existing` and `imported` properties
  # @param dialog [Object] current dialog instance
  # @param sce [Object] Angular's Strict Contextual Escaping facility
  constructor: (@rootScope, rawConflicts, @_dialog, @sce) ->
    @conflicts = []
    @rank = -1
    # first, get dancers
    dancers = (imported for {imported} in rawConflicts when imported instanceof Dancer)
    # then add missing addresses and card
    resolvable = []
    resolved = []
    for {imported} in rawConflicts 
      found = false
      if imported instanceof Card
        # search for imported dancers with this card
        for dancer in dancers when dancer.cardId is imported.id
          found = true
          dancer.card = imported
          break
        unless found
          resolved.push imported
          resolvable.push Dancer.findWhere cardId: imported.id 
      else if imported instanceof Address  
        # search for imported dancers with this address
        for dancer in dancers when dancer.addressId is imported.id
          found = true
          dancer.address = imported
          break
        unless found
          resolved.push imported
          resolvable.push Dancer.findWhere addressId: imported.id

    # add extra dancers to manage addresses and cards
    Promise.all(resolvable).then((extraDancers) =>
      ids = (id for {id} in dancers)
      for [dancer],i in extraDancers
        ids.push dancer.id 
        # use a fake dancer to carry the modified address or card
        fake = new Dancer dancer.toJSON()
        if resolved[i] instanceof Address
          # TOREMOVE console.log "use imported address #{resolved[i].id} for fake dancer #{fake.id}"
          fake.address = resolved[i]
        else
          # TOREMOVE console.log "use imported card #{resolved[i].id} for fake dancer #{fake.id}"
          fake.card = resolved[i]
        dancers.push fake
      # for all, get existing dancers
      Dancer.findWhere(_id: $in: ids).then (existings) =>
        # at last, push existing and imported dancers aside with each other
        for existing in existings
          @conflicts.push existing: existing, imported: _.findWhere dancers, id: existing.id
        # get all possible dance classes for registrations
        DanceClass.findAll().then (danceClasses) => 
          @danceClasses = {}
          @danceClasses[danceClass.id] = danceClass for danceClass in danceClasses
          @loadNext()
    ).catch (err) =>
      console.error err

  # **private**
  # Get dance class ids for a given season.
  # Dance classes must have been previously resolved
  #
  # @param dancer [Dancer] dancer for which dance class ids are required
  # @param season [String] expected season
  # @return List (that may be empty) of dance class ids of this season
  _danceClassesForSeason: (dancer, season) =>
    (id for id in dancer.danceClassIds when @danceClasses[id]?.season is season)

  # **private**
  # Translate value into human readable known by if possible
  #
  # @param value [String] knownBy key
  # @return corresponding translation or the key itslef
  _translate: (value) =>
    return i18n.knownByMeanings[value] if value of i18n.knownByMeanings
    value

  # **private**
  # Translate dance class id into human readable label
  # Dance classes must have been previously resolved
  #
  # @param id [String] danceClass id
  # @return corresponding name
  _getClass: (id) =>
    return i18n.lbl.unknown unless @danceClasses[id]?
    "#{@danceClasses[id].kind} #{@danceClasses[id].level}"

  # **private**
  # Display registration for read only usage
  # Dance classes must have been previously resolved
  #
  # @param model [Registration] displayed registration
  # @param dancer [Dancer] concerned dancer, to get classes
  # @return formated registration
  _formatRegistration: (model, dancer) =>
    classes = (@_getClass id for id in dancer.danceClassIds when @danceClasses[id].season is model.season).join ', '
    payments = (@_formatPayment payment for payment in model.payments).join '\n'
    """<div>#{model.season}</div>
       <div>#{i18n.lbl.danceClasses}#{i18n.lbl.fieldSeparator}&nbsp;#{classes}</div>
       <div>#{i18n.lbl.charged}#{i18n.lbl.fieldSeparator}&nbsp;#{model.charged}#{i18n.lbl.currency} (#{i18n.periods[model.period]})</div>
       #{payments}
    """

  # **private**
  # Display payment for read only usage
  #
  # @param model [Payment] displayed payment
  # @return formated payment
  _formatPayment: (model) =>
    "<div>#{model.receipt.format i18n.formats.receipt} - #{model.value}#{i18n.lbl.currency} #{i18n.paymentTypes[model.type]}#{if model.payer then " (#{model.payer})" else ''} #{if model.details? then model.details else ''}</div>"

  # **private**
  # Display address for read only usage
  #
  # @param model [Address] displayed address
  # @return formated address
  _formatAddress: (model) =>
    "<div>#{model.street} #{model.zipcode} #{model.city}</div>"

  # **private**
  # Display card for read only usage
  #
  # @param model [Card] displayed card
  # @param dancer [Dancer] concerned dancer
  # @return formated card
  _formatCard: (model, dancer) =>
    # get dancers
    dancers = []
    registrations = ("""<li>#{@_formatRegistration reg, dancer}</li>""" for reg in model.registrations)
    """
    <div>#{(@_translate knownBy for knownBy in model.knownBy).join ', '}</div>
    <ul>#{registrations.join '\n'}</ul>
    """
  
  # **private**
  # Display certificates for read only usage
  #
  # @param model [Registration] displayed registration
  # @return its number of certificates
  _formatCertificates: (model) =>
    (id for id of model.certificates when model.certificates[id]).length

  # Load the next available conflict
  # For each field that is different between imported and existing models, stores in 'fields' property:
  # - label: field label
  # - existing: existing value
  # - imported: imported value
  # - useImported: boolean indicating which value is selected
  #
  # @return a promise that when fields attribute is ready.
  loadNext: =>
    @rank++
    if @rank is @conflicts.length
      return @_dialog.close()
    # get card
    existing = @conflicts[@rank].existing
    imported = @conflicts[@rank].imported
    @name = "#{existing.title} #{existing.firstname} #{existing.lastname}"
    @fields = []

    # check dancer fields
    for field in ['title', 'firstname', 'lastname', 'cellphone', 'email'] when existing[field] isnt imported[field]
      @fields.push 
        label: field
        path: field
        existing: @sce.trustAsHtml existing[field]?.toString() or ""
        imported: @sce.trustAsHtml imported[field]?.toString() or ""
        useImported: true

    # check address fields
    Promise.all([existing.address, imported.address]).then( ([existingAddress, importedAddress]) =>
      # check if address model has entierly changed
      if existing.addressId isnt imported.addressId
        @fields.push 
          kind: 'address'
          path: 'addressId'
          existing: @sce.trustAsHtml @_formatAddress existingAddress
          imported: @sce.trustAsHtml @_formatAddress importedAddress
          useImported: true
      else
        # otherwise, check individual fields
        for field in ['street', 'zipcode', 'city', 'phone'] when existingAddress[field] isnt importedAddress[field]
          @fields.push 
            label: field
            parentPath: '_address'
            path: field
            existing: @sce.trustAsHtml existingAddress[field]?.toString() or ""
            imported: @sce.trustAsHtml importedAddress[field]?.toString() or ""
            useImported: true

      # check card fields
      Promise.all([existing.card, imported.card]).then( ([existingCard, importedCard]) =>
        # check if card model has entierly changed
        if existing.cardId isnt imported.cardId
          @fields.push 
            kind: 'card'
            path: 'cardId'
            existing: @sce.trustAsHtml @_formatCard existingCard, existing
            imported: @sce.trustAsHtml @_formatCard importedCard, imported
            useImported: true
        else
          # otherwise, check individual fields
          unless _.isEqual existingCard.knownBy, importedCard.knownBy
            @fields.push 
              label: 'knownBy'
              parentPath: '_card'
              path: 'knownBy'
              existing: @sce.trustAsHtml (@_translate knownBy for knownBy in existingCard.knownBy).join ', '
              imported: @sce.trustAsHtml (@_translate knownBy for knownBy in importedCard.knownBy).join ', '
              useImported: true

          # registrations
          checkedRegistrations = []
          for existingReg, i in existingCard.registrations
            season = existingReg.season
            importedReg = _.findWhere importedCard.registrations, season: season
            if importedReg?
              checkedRegistrations.push importedReg 
              for field in ['details', 'period', 'charged'] when existingReg[field] isnt importedReg[field]
                @fields.push 
                  season: season
                  label: field
                  parentPath: '_card'
                  path: "registrations[#{i}].#{field}"
                  existing: @sce.trustAsHtml existingReg[field]?.toString() or ""
                  imported: @sce.trustAsHtml importedReg[field]?.toString() or ""
                  useImported: true

              # certificates
              unless _.isEqual existingReg.certificates, importedReg.certificates
                @fields.push 
                  season: season
                  label: 'certificates'
                  parentPath: '_card'
                  path: "registrations[#{i}].certificates"
                  existing: @sce.trustAsHtml @_formatCertificates existingReg
                  imported: @sce.trustAsHtml @_formatCertificates importedReg
                  useImported: true

              # dance classes
              existingClassIds = @_danceClassesForSeason existing, season
              importedClassIds = @_danceClassesForSeason imported, season
              unless _.isEqual existingClassIds, importedClassIds
                @fields.push 
                  season: season
                  label: 'danceClasses'
                  existing: @sce.trustAsHtml (@_getClass id for id in existingClassIds).join ', '
                  imported: @sce.trustAsHtml (@_getClass id for id in importedClassIds).join ', '
                  useImported: true
                  danceClassAdded: _.difference importedClassIds, existingClassIds
                  danceClassRemoved: _.difference existingClassIds, importedClassIds

              # payments : use indice to compare
              checkedPayments = []
              for existingPayment, j in existingReg.payments when importedReg.payments[j]?
                unless _.isEqual importedReg.payments[j].toJSON(), existingPayment.toJSON()
                  # found modification
                  @fields.push 
                    kind: 'payment'
                    season: season
                    parentPath: '_card'
                    path: "registrations[#{i}].payments[#{j}]"
                    existing: @sce.trustAsHtml @_formatPayment existingPayment
                    imported: @sce.trustAsHtml @_formatPayment importedReg.payments[j]
                    useImported: true

              # removed payments
              for removed, j in existingReg.payments[importedReg.payments.length..]
                @fields.push 
                  kind: 'payment'
                  season: season
                  parentPath: '_card'
                  path: "registrations[#{i}].payments"
                  spliced: importedReg.payments.length+j
                  existing: @sce.trustAsHtml @_formatPayment removed
                  useImported: true

              # added payments    
              for added, j in importedReg.payments[existingReg.payments.length..]
                @fields.push 
                  kind: 'payment'
                  season: season
                  parentPath: '_card'
                  path: "registrations[#{i}].payments[#{existingReg.payments.length + j}]"
                  imported: @sce.trustAsHtml @_formatPayment added
                  useImported: true
            else
              # removed registrations
              @fields.push 
                kind: 'registration'
                season: season
                parentPath: '_card'
                path: "registrations"
                spliced: i
                existing: @sce.trustAsHtml @_formatRegistration existingReg, existing
                useImported: false
                danceClassRemoved: @_danceClassesForSeason existing, existingReg.season

          # entierly add remaining registrations
          for importedReg in _.difference importedCard.registrations, checkedRegistrations
            @fields.push 
              kind: 'registration'
              season: importedReg.season
              parentPath: '_card'
              path: "registrations[#{existingCard.registrations.length}]"
              imported: @sce.trustAsHtml @_formatRegistration importedReg, imported
              useImported: true
              danceClassAdded: @_danceClassesForSeason imported, importedReg.season

        if @fields.length is 0
          # no conflicts detected !
          @loadNext()
        else
          @rootScope.$apply()
      )
    ).catch (err) =>
      console.error err

  # Get all selected values, and save the existing model
  save: =>
    existing = @conflicts[@rank].existing
    imported = @conflicts[@rank].imported
    # array of models that will be saved
    saveable = {}
    saveable[existing.id] = existing
    # for all conflicted fields, get modified parent model
    for field in @fields when field.useImported
      # TOREMOVE console.log 'field path', field.parentPath
      modified = if field.parentPath? then getAttr existing, field.parentPath else existing
      newValue = if field.parentPath? then getAttr imported, field.parentPath else imported
      # TOREMOVE console.log 'modified', modified?.toJSON?() or modified
      # TOREMOVE console.log 'imported', newValue?.toJSON?() or newValue
      # change modified model value
      if field.path
        if field.spliced
          # remove within array
          getAttr(modified, field.path).splice field.spliced, 1
        else
          # or modifies value
          setAttr modified, field.path, getAttr newValue, field.path
      # update dance classes
      if field.danceClassAdded?
        existing.danceClassIds = _.unique existing.danceClassIds.concat field.danceClassAdded
      if field.danceClassRemoved?
        existing.danceClassIds = _.difference existing.danceClassIds, field.danceClassRemoved
      # if modified model is nested store it in saveable if necessary
      saveable[modified.id] = modified if modified.id?

    # save models
    Promise.all((model.save() for id, model of saveable))
    .then(@loadNext)
    .catch (err) => console.error err

  # Dialog cancellation: after confirmation, stop conflict resolution.
  #
  # @param confirmed [Boolean] true if the creation is confirmed
  cancel: =>
    # TODO confirm
    @_dialog.close()