_ = require 'lodash'
moment = require 'moment'
async = require 'async'
{join} = require 'path'
windowManager = require('electron').remote.require 'electron-window-manager'
i18n = require '../labels/common'
{generateId, makeInvoice} = require '../util/common'
Dancer = require '../model/dancer'
Card = require '../model/card'
Address = require '../model/address'
Registration = require '../model/registration'
Invoice = require '../model/invoice'
RegisterController = require './register'
SearchDancerController = require './search_dancer'
{currentSeason} = require '../util/common'

# Displays and edits a a dancer card, that is a bunch of dancers, their registrations and their classes
# New registration may be added, and the corresponding directive will be consequently used.
module.exports = class CardController

  # Controller dependencies
  @$inject: ['$scope', '$rootScope', 'cardList', 'conf', 'dialog', '$q', '$state', '$filter', '$stateParams']

  # Route declaration
  @declaration:
    controller: CardController
    controllerAs: 'ctrl'
    templateUrl: 'card.html'

  # for rendering
  i18n: i18n

  # Controller's own scope, for change detection
  scope: null

  # Angular's global scope, for digest triggering
  rootScope: null

  # Angular's state service
  state: null

  # Angular's filters factory
  filter: null

  # Link to modal popup service
  dialog: null

  # Angular's promise factory
  q: null

  # Configuration service
  conf: null

  # displayed card
  card: null

  # Array of dancers displaced on this card
  dancers: []

  # Corresponding array of dancers's address, to ensure model reuse
  addresses: []

  # temporary stores known-by values
  knownBy: {}

  # temporary stores known by other value
  knownByOther: null

  # for edited models (id used as key), contains an array of required fields
  required: {}

  # flag indicating wether the card has changed or not
  hasChanged: false

  # for each registration, contains a sorted array of invoices
  invoices: []

  # **private**
  # Store if a modal is currently opened
  _modalOpened: false

  # **private**
  # Stores previous models values (model id used as key) for change detection
  _previous: {}

  # **private**
  # Models that must be removed on save
  _removable: []

  # **private**
  # Registration print preview window
  _preview: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Controller's own scope, for change detection
  # @param rootscope [Object] Angular global scope for digest triggering
  # @param cardList [CardListService] service responsible for card list
  # @param conf [Object] configuration service
  # @param dialog [Object] Angular dialog service
  # @param q [Object] Angular's promise factory
  # @param state [Object] Angular state provider
  # @param filter [Function] Angular's filter factory
  # @param stateParams [Object] invokation route parameters
  constructor: (@scope, @rootScope, @cardList, @conf, @dialog, @q, @state, @filter, stateParams) ->
    # initialize global change status
    @dancers = []
    @addresses = []
    @required = {}
    @invoices = []
    @allInvoices = []
    @_modalOpened = false
    @_previous = {}
    @_removable = []
    @_preview = null

    @_actions =
      cancel: label: 'btn.cancel', icon: 'ban-circle', action: @cancel
      save: label: 'btn.save', icon: 'floppy-disk', action: @save

    # set context actions for planning
    @scope.listCtrl.actions = []
    @_setChanged false

    if stateParams.id
      # load edited dancer
      @_loadCard stateParams.id
    else
      @_reset()

    # focus to first field
    _.delay =>
      $('.dancer.focusable .btn.dropdown-toggle').focus()
    , 200

    @rootScope.$on '$stateChangeStart', (event, toState, toParams) =>
      return unless @hasChanged
      # stop state change until user choose what to do with pending changes
      event.preventDefault()
      # confirm if dancer changed
      @dialog.messageBox(@i18n.ttl.confirm, i18n.msg.confirmGoBack, [
          {label: @i18n.btn.no, cssClass: 'btn-warning'}
          {label: @i18n.btn.yes, result: true}
        ]
      ).result.then (confirmed) =>
        return unless confirmed
        # if confirmed, effectively go on desired state
        @_setChanged false
        @state.go toState.name, toParams

  # Goes back to list, after a confirmation if dancer has changed
  back: => @state.go 'list.planning'

  # restore previous values
  cancel: =>
    return unless @hasChanged and not @_modalOpened
    names = ("#{dancer.firstname or ''} #{dancer.lastname or ''}" for dancer in @dancers when dancer.firstname or dancer.lastname)
    @_modalOpened = true
    @dialog.messageBox(@i18n.ttl.confirm,
      @filter('i18n')('msg.cancelEdition', args: names: names.join ', '), [
        {label: @i18n.btn.no, cssClass: 'btn-warning'}
        {label: @i18n.btn.yes, result: true}
      ]
    ).result.then (confirmed) =>
      @_modalOpened = false
      return unless confirmed
      if @dancers[0]?.cardId?
        # cancel payment
        @rootScope.$broadcast 'cancel-edit'
        # restore values by reloading first dancer from storage
        @loadCard @dancers[0].cardId
      else
        # or recreate a brand new dancer if it was an empty card
        @_reset()

  # Save the current values inside storage
  #
  # @param force [Boolean] true to ignore required fields. Default to false.
  # @param done [Function] completion callback, invoked with arguments:
  # @option done err [Error] an error object or null if no problem occured
  save: (force = false, done = ->) =>
    return done null unless @hasChanged
    # check required fields
    if not force and @_checkRequired()
      return @dialog.messageBox(@i18n.ttl.confirm, i18n.msg.requiredFields, [
          {label: @i18n.btn.no, cssClass: 'btn-warning'}
          {label: @i18n.btn.yes, result: true}
        ]
      ).result.then (confirmed) =>
        return unless confirmed
        @save true

    # first, resolve addresses and card
    async.map @dancers, (dancer, next) ->
      dancer.getAddress next
    , (err, models) =>
      if err?
        console.error err
        return done err
      models.push @card
      saved = []

      async.eachSeries models, (model, next) =>
        return next() if model._v > 0 and (model.id? and ((model.id in saved) or _.isEqual model.toJSON(), @_previous[model.id]))
        if model.constructor.name is 'Address'
          console.log "save addresss #{model.street} #{model.zipcode} (#{model.id})"
        else
          console.log "save card #{model.id}"
        model.save (err) =>
          unless err?
            @_previous[model.id] = model.toJSON()
            # to avoid saving the same address multiple times
            saved.push model.id
          next err
      , (err) =>
        if err?
          console.error err
          return done err
        console.log "addresses and card saved"
        async.eachSeries @dancers, (dancer, next) =>
          return next() unless dancer.id? and not _.isEqual dancer.toJSON(), @_previous[dancer.id]
          console.log "save #{dancer.firstname} #{dancer.lastname} (#{dancer.id})"
          dancer.save (err) =>
            @_previous[dancer.id] = dancer.toJSON() unless err?
            next err
        , (err) =>
          if err?
            console.error err
            return done err
          console.log "dancers saved"

          # at last removes old models
          async.each @_removable, (model, next) ->
            model.remove next
          , (err) =>
            if err?
              console.error err
              return done err
            # reset change state and refresh search
            @_onChange()
            @_resetRequired()
            @_removable = []
            @cardList.performSearch()
            console.log "models removed" if @_removable.length
            @scope.$apply() unless @scope.$$phase
            done()

  # Navigate to the state displaying a given card
  #
  # @param cardId [String] loaded card id.
  loadCard: (cardId) =>
    # to avoid displaying confirmation
    @_setChanged false
    @state.go 'list.card', {id: cardId}, reload: true

  # Add a new dancer to this card.
  # Reuse address of last dancer
  addDancer: =>
    added = new Dancer id: generateId()
    # get the existing address and card
    address = @addresses[-1..][0]
    added.setAddress address
    @addresses.push address
    added.setCard @card
    # adds this new dancer to the list
    @dancers.push added
    @required[added.id] = []
    @required[address.id] = []
    @_previous[added.id] = added.toJSON()
    @_previous[address.id] = address.toJSON()
    @_onChange 'dancers'
    # scroll to last
    _.defer =>
      $('.card-dancer > .dropup > a').focus()

  # When a dancer that share an address with another one want to separate,
  # we affect him a brand new address
  # Only for dancers that share address with another one
  #
  # @param dancer [Dancer] the concerned dancer
  addAddress: (dancer) =>
    return unless @isAddressReadOnly dancer
    address = new Address id: generateId()
    @addresses[@dancers.indexOf dancer] = address
    @required[address.id] = []
    @_previous[address.id] = address.toJSON()
    dancer.setAddress address
    @_onChange 'addresses'

  # Add a new registration for the current season to the edited dancer, or edit an existing one
  # Displays the registration dialog
  #
  # @param dancer [Dancer] dancer for whom a registration is added
  addRegistration: (dancer) =>
    # display dialog to choose registration season and dance classes
    @dialog.modal(_.extend {
        size: 'lg'
        keyboard: false
        resolve:
          danceClasses: =>
            deffered = @q.defer()
            dancer.getClasses (err, classes) ->
              return deffered.reject err if err?
              deffered.resolve classes
            deffered.promise
          isEdit: -> dancer.danceClassIds.length > 0
      }, RegisterController.declaration
    ).result.then ({confirmed, season, danceClasses}) =>
      return unless confirmed
      registration = null
      # search for existing registration
      for candidate in @card.registrations when candidate.season is season
        registration = candidate
        break
      # or add a new registration on top
      unless registration?
        registration = new Registration season: season
        @card.registrations.splice 0, 0, registration
        @_previous[registration.id] = registration.toJSON()
        @required.regs.push []
        @required.regClasses.push ''

      # add selected class ids to dancer
      dancer.setClasses danceClasses
      @scope.$broadcast 'dance-classes-changed', dancer
      @_onChange "dancer[#{@dancers.indexOf dancer}].danceClassIds"

  # Indicates whether this dancer's address was reused or not
  #
  # @param dancer [Dancer] tested dancer
  # @return false if his address is editable, true if not
  isAddressReadOnly: (dancer) =>
    used = {}
    for candidate in @dancers
      if candidate is dancer
        return dancer.addressId of used
      else
        used[candidate.addressId] = true

  # Indicate whether the dancer's address can be removed or not.
  # Only for dancers that do not share their address and that are not the first
  #
  # @param dancer [Dancer] tested dancer
  # @return true if his address is removable, false if not
  isAddressRemovable: (dancer) =>
    used = []
    for candidate in @dancers
      return used.length > 0 and not(dancer.addressId in used) if candidate is dancer
      used.push candidate.addressId unless candidate.addressId in used
    false

  # Invoked when the list of known-by meanings has changed.
  # Updates the model corresponding array.
  setKnownBy: =>
    @card?.knownBy = (value for value of @i18n.knownByMeanings when @knownBy[value])
    @card?.knownBy.push @knownByOther if @knownByOther
    @_onChange 'knownBy'

  # Displays a popup to search a dancer for merging it's card with the current card
  searchCard: =>
    # display dialog to choose registration season and dance classes
    @dialog.modal(_.extend {
        resolve:
          existing: => @dancers[0]
      }, SearchDancerController.declaration
    ).result.then (dancer) =>
      return unless dancer?
      # merge both card and save
      dancer.getCard (err, card) =>
        return console.error err if err?
        @card.merge card, (err) =>
          return console.error err if err?
          @save true, (err) =>
            return console.error err if err?
            @loadCard @card.id

  # Print the settlement for a given year
  #
  # @param registration [Registration] the concerned registration
  # @param selectedTeacher [Number] index of the selected teacher
  printSettlement: (registration, selectedTeacher) =>
    return @_preview.focus() if @_preview?
    @save true, (err) =>
      return console.error err if err?

      windowManager.sharedData.set 'styles', global.styles.print
      windowManager.sharedData.set 'card', @card
      windowManager.sharedData.set 'selectedTeacher', selectedTeacher
      windowManager.sharedData.set 'season', registration.season

      # open hidden print window
      @_preview = windowManager.createNew 'settlement', window.document.title, null, 'print'
      @_preview.open '/settlement_print.html', true
      @_preview.focus()

      @_preview.object.on 'closed', =>
        # dereference the window object, to destroy it
        @_preview = null

  # Invoked when dancer needs to be removed.
  # First display a confirmation dialog, and then dissociate the dancer from this card
  #
  # @param dancer [Dancer] dancer that needs to be removed
  removeDancer: (dancer) =>
    isLast = @dancers.length is 1
    msg = if isLast then 'msg.removeLastDancer' else 'msg.removeDancer'
    @dialog.messageBox(@i18n.ttl.confirm, @filter('i18n')(msg, args: dancer), [
      {label: @i18n.btn.no}
      {label: @i18n.btn.yes, result: true, cssClass: 'btn-warning'}
    ]).result.then (confirm) =>
      return unless confirm
      # remove everything and goes to list
      if isLast
        return async.parallel [
          (done) => @addresses[0].remove done
          (done) => @dancers[0].remove done
          (done) => @card.remove done
        ], (err) =>
          return console.error err if err?
          @scope.$apply =>
            @cardList.performSearch()
            @back()

      # mark for a change
      @_previous[dancer.id] = {}
      @_setChanged true

      idx = @dancers.indexOf dancer
      # mark dancer to be removed, and its address if necessary
      @_removable.push dancer
      @_removable.push @addresses[idx] if @isAddressRemovable dancer

      # removes from displayed objects
      @dancers.splice idx, 1
      @addresses.splice idx, 1
      @_onChange 'dancers'

  # Invoked when registration needs to be removed.
  # First display a confirmation dialog, and then removes it
  #
  # @param registration [Registration] the removed registration
  removeRegistration: (registration) =>
    @dialog.messageBox(@i18n.ttl.confirm, @filter('i18n')('msg.removeRegistration', args: registration), [
      {result: false, label: @i18n.btn.no}
      {result: true, label: @i18n.btn.yes, cssClass: 'btn-warning'}
    ]).result.then (confirm) =>
      return unless confirm
      @card.registrations.splice @card.registrations.indexOf(registration), 1
      @_onChange 'registrations'

  # Invoked when address needs to be removed.
  # First display a confirmation dialog, and then reuse the first dancer's address
  #
  # @param dancer [Dancer] dancer for which address is removed
  removeAddress: (dancer) =>
    @dialog.messageBox(@i18n.ttl.confirm, @filter('i18n')('msg.removeAddress', args: dancer: dancer, address: @addresses[0]), [
      {result: false, label: @i18n.btn.no}
      {result: true, label: @i18n.btn.yes, cssClass: 'btn-warning'}
    ]).result.then (confirm) =>
      return unless confirm
      for addr in @addresses when addr.id is dancer.addressId
        @_removable.push addr
        break
      dancer.setAddress @addresses[0]
      @addresses[@dancers.indexOf dancer] = @addresses[0]
      @_onChange 'addresses'

  # Display a sent invoice (and save card before)
  #
  # @param invoice [Invoice] invoice to be displayed
  displayInvoice: (invoice) =>
    return unless invoice?.id?
    # save pending modifications
    @save true, (err) =>
      return console.error err if err?
      @state.go 'list.invoice', {invoice}

  # Creates a new invoice for that registration, or updates the last one which is not sent
  # Save the card before
  #
  # @param registration [Registration] for which invoice is edited
  # @param teacher [Number] index of the selected teacher
  editInvoice: (teacher, registration = null) =>
    # save pending modifications
    @save true, (err) =>
      return console.error err if err?
      # new invoice date
      date = registration?.created or registration?.payments[0]?.receipt or moment()
      # search for unsent invoices related to that card, and create a new one if needed
      makeInvoice @dancers, date, registration?.season or currentSeason(), teacher, (err, invoice) =>
        # there could be an error if invoice already exists, and invoice will be populated.
        return @state.go 'list.invoice', {invoice} if invoice?
        # or just an error
        console.error err

  # **private**
  # Update hasChanged flag and contextual actions
  #
  # @param changed [Boolean] new has changed flag value
  _setChanged: (changed) =>
    next = []
    if changed
      # can cancel only if already saved once
      next.unshift @_actions.cancel if @card?._v > 0
      next.unshift @_actions.save
    @hasChanged = changed
    # only update actions if they have changed
    @scope.listCtrl.actions = next unless _.isEqual next, @scope.listCtrl.actions

  # **private**
  # Reset displayed card and its relative models
  _reset: =>
    @knownBy = {}
    @required = {}
    @_resetRequired()
    @knownByOther = null
    # creates an empty dancer with empty address and card
    dancer = new Dancer id: generateId()
    # set an id to address to allow sharing with other dancers
    address = new Address id: generateId()
    # set an id to card to allow change detection
    @card = new Card id: generateId()
    dancer.setAddress address
    dancer.setCard @card
    @dancers = [dancer]
    @addresses = [address]
    @_previous = {}
    # store previous values
    @_previous[@card.id] = @card.toJSON()
    @_previous[dancer.id] = dancer.toJSON()
    @_previous[address.id] = address.toJSON()
    @_onChange()
    console.log "reset card controller"

  # **private**
  # Effectively loads a card, and get all other dancers of this card.
  #
  # @param cardId [String] loaded card id.
  _loadCard: (cardId) =>
    # get other dancers, load card to display registrations, and get invoices
    async.parallel [
      (done) -> Dancer.findWhere cardId: cardId, done
      (done) -> Card.find cardId, done
      (done) -> Invoice.findWhere cardId: cardId, done
    ], (err, [dancers, card, invoices]) =>
      # TODO no dancer nor card, what do we do ?
      return console.error err if err?
      @card = card
      @_previous = {}
      @_previous[@card.id] = @card.toJSON()
      console.log "load dancer #{dancer.lastname} #{dancer.firstname} (#{dancer.id})" for dancer in dancers
      @required = {}
      @dancers = _.sortBy dancers, "firstname"
      for dancer in @dancers
        @required[dancer.id] = []
        @_previous[dancer.id] = dancer.toJSON()
      # updates registrations and their invoices, order registration here rather than in code
      @card.registrations.sort (a, b) -> a.season < b.season ? -1 : 1
      @required.regs = ([] for registration in @card.registrations)
      @required.regClasses = ('' for registration in @card.registrations)
      @invoices = (for registration in @card.registrations
        invoices.filter(({season, sent}) -> season is registration.season).sort (a, b) -> a.sent?.diff b.sent)
      @allInvoices = invoices.sort (a, b) -> a.sent?.diff b.sent

      # get dance classes
      async.map @dancers, (dancer, next) ->
        dancer.getClasses next
      , (err, danceClasses) =>
        # TODO no dance classes, what do we do ?
        return console.error err if err?
        # get addresses
        async.map @dancers, (dancer, next) ->
          dancer.getAddress (err, address) ->
            if err?
              # do not fail on unknown address: instead, put new address with error message
              address = new Address id: generateId(), zipcode: 0, street: i18n.err.missingAddress
              dancer.setAddress address
              console.error "failed to get address of dancer #{dancer.id}: #{err}"
            next null, address
        , (err, addresses) =>
          console.error err if err?
          unic = {}
          @addresses = []
          for address in addresses
            @required[address.id] = []
            unless address.id of unic
              # found a new model
              unic[address.id] = address
              @addresses.push address
              @_previous[address.id] = address.toJSON()
            else
              # reuse existing model
              @addresses.push unic[address.id]
          # translate the "known by" possibilities into a list of boolean
          @knownBy = {}
          for value of @i18n.knownByMeanings
            @knownBy[value] = @card.knownBy?.includes value
          @knownByOther = _.find @card.knownBy, (value) => not(value of @i18n.knownByMeanings)

          # reset changes and displays everything
          @_setChanged false
          @scope.$apply()

  # **private**
  # Change handler: check if any displayed model has changed from its previous values
  #
  # @param field [String] modified field
  _onChange: (field) =>
    # performs comparison between current and old values
    @_setChanged false
    for model in [@card].concat @dancers, @addresses when not _.isEqual @_previous[model.id], model.toJSON()
      # console.log "model #{model.id} (#{model.constructor.name}) has changed on #{field}"
      # quit at first modification
      return @_setChanged true

  # **private**
  # Check required fields when saving models
  #
  # @return true if a required field is missing
  _checkRequired: =>
    missing = false
    for dancer in @dancers
      @required[dancer.id] = (
        for field in ['title', 'firstname', 'lastname'] when not(dancer[field]?) or dancer[field].trim?()?.length is 0
          missing = true
          field
      )
    for address in @addresses
      @required[address.id] = (
        for field in ['street', 'zipcode', 'city'] when not(address[field]?) or address[field].trim?()?.length is 0
          missing = true
          field
      )
    for registration, i in @card.registrations
      @required.regs[i] = (
        for payment in registration.payments
          requiredFields = ['type']
          requiredFields.push 'payer', 'bank' if payment.type is 'check'
          tmp = (
            for field in requiredFields when not(payment[field]?) or payment[field].trim?()?.length is 0
              missing = true
              field
          )
          tmp
      )
      @required.regClasses[i] = if @required.regs[i].find((fields) => fields.length) then 'invalid' else ''
    missing

  # **private**
  # Reset required fields
  _resetRequired: =>
    @required[dancer.id] = [] for dancer in @dancers
    @required[address.id] = [] for address in @addresses
    @required.regClasses = ('' for registration in @card?.registrations or [])
    @required.regs = (([] for payment in registration.payments) for registration, i in @card?.registrations or [])