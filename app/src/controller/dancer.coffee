define [
  'underscore'
  'i18n!nls/common'
  '../model/dancer/dancer'
  '../model/dancer/registration'
  '../model/planning/planning'
  './register'
], (_, i18n, Dancer, Registration, Planning, RegisterController) ->
  
  # Displays and edits a given dancer.
  # New registration may be added, and the corresponding directive will be consequently used.
  #
  # Associated with the `template/dancer.html` view.
  class DancerController
              
    # Controller dependencies
    @$inject: ['$scope', 'storage', '$dialog']
    
    # Controller scope, injected within constructor
    scope: null

    # Storage service
    storage: null
        
    # Link to Angular dialog service
    dialog: null

    # Controller constructor: bind methods and attributes to current scope
    #
    # @param scope [Object] Angular current scope
    # @param storage [Storage] Storage service
    # @param dialog [Object] Angular dialog service
    constructor: (@scope, storage, @dialog) -> 
      # creates an empty dancer
      @_displayDancer new Dancer i18n.defaultDancer

      # fill the scope and bind public methods
      @scope.i18n = i18n
      @scope[attr] = value for attr, value of @ when _.isFunction(value) and not _.startsWith attr, '_'

    # TODO
    onNewDancer: =>
      # TODO check modifications, allow saving, get birth value
      console.log "previous", @scope.dancer?.toJSON()
      @_displayDancer new Dancer()

    # Save the current values inside storage
    onSave: =>
      console.log @scope.dancer.toJSON()
      #@scope.dancer.save (err) =>
      #  throw err if err?
      #  console.log 'save done !'

    # Invoked by view to update dancer's title according to selected item
    #
    # @param selected [String] the new dancer's title
    onUpdateTitle: (selected) =>
      @scope.dancer?.title = selected

    # Add a new registration for the current year to the edited dancer, or edit an existing one
    # Displays the registration dialog
    #
    # @param registration [Registration] the edited registration, null to create a new one 
    onRegister: (registration = null) =>
      handled = new Registration()
      # display dialog to choose registration year and dance classes
      @dialog.dialog(
        keyboard: false
        backdropClick: false
        dialogFade: true
        backdropFade: true
        controller: RegisterController
        templateUrl: 'register.html'
        resolve: registration: -> registration or handled
      ).open().then (confirmed) =>
        return if !confirmed or registration?
        # add the created registration to current dancer at the first position
        @scope.dancer.registrations.splice 0, 0, handled

    # Invoked when registration needs to be removed.
    # First display a confirmation dialog, and then removes it
    #
    # @param removed [Registration] the removed registration
    onRemoveRegistration: (removed) =>
      Planning.find removed.planningId, (err, planning) =>
        throw err if err?
        @scope.$apply =>
          @dialog.messageBox(i18n.ttl.confirmRemove, _.sprintf(i18n.msg.removeRegistration, planning.year), [
            {result: false, label: i18n.btn.no}
            {result: true, label: i18n.btn.yes, cssClass: 'btn-warning'}
          ]).open().then (confirm) =>
            return unless confirm
            @scope.dancer.registrations.splice @scope.dancer.registrations.indexOf(removed), 1

    # **private**
    # Update rendering with a given dancer
    #
    # @param dancer [Dancer] the new displayed dancer
    _displayDancer: (dancer) =>
      @scope.dancer = dancer
      @scope.birth = dancer.birth?.toDate()
      @scope.showBirthPicker = false