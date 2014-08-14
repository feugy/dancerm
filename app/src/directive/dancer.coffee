_ = require 'underscore'
moment = require 'moment'
i18n = require '../labels/common'
Dancer = require '../model/dancer'

class DancerDirective
                
  # Controller dependencies
  @$inject: ['$scope']

  # Labels for rendering
  i18n: i18n

  # Indicates whether the edited dancer has never been saved
  isNew: false

  # temporary stores known-by values
  knownBy: {}

  # temporary stores known by other value
  knownByOther: null

  # Option used to configure birth selection popup
  birthOpts: 
    value: null
    open: false
    showWeeks: false
    startingDay: 1
    showButtonBar: false

  # **private**
  # Dancers's search request in progress
  _reqInProgress: false

  # **private**
  # stores previous values for changes detections
  _previous: {}

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive own scope, used to detect changes
  constructor: (@scope) ->
    @_reqInProgress = false

    @birthOpts =
      showWeeks: false
      startingDay: 1
      showButtonBar: false

    # TODO waiting for https://github.com/angular/angular.js/pull/7645
    #@scope.$watchGroup ['src._v', 'src.id'], => @_updateRendering @scope.src
    @_updateRendering @scope.src

  # Invoked by view to update dancer's title according to selected item
  #
  # @param selected [String] the new dancer's title
  setTitle: (selected) =>
    unless selected is i18n.lbl.choose
      @src?.title = selected 

  # Search within existing models a match on given attribute
  # Only available when dancer is not saved yet.
  #
  # @param attr [String] matching attribute name
  # @param typed [String] typed string
  # @return a promise of mathcing dancers
  findByAttr: (attr, typed) =>
    # disable if request in progress
    return [] if @_reqInProgress
    @_reqInProgress = true
    # prepare search conditions
    typed = typed.toLowerCase()
    condition = {}
    condition[attr] = new RegExp "^#{typed}", 'i'
    new Promise (resolve, reject) =>
      # find matching dancers
      Dancer.findWhere(condition).then((models) => 
        @_reqInProgress = false
        resolve models
      ).catch (err) ->
        @_reqInProgress = false
        console.error err
        reject err

  # Invoked when date change in the date picker
  # Updates the dancer's birth date
  setBirth: =>
    @src?.birth = moment @birthOpts.value
    @_onChange()

  # Invoked when the list of known-by meanings has changed.
  # Updates the model corresponding array.
  setKnownBy: =>
    @src?.knownBy = (value for value of @i18n.knownByMeanings when @knownBy[value])
    @src?.knownBy.push @knownByOther if @knownByOther
    @_onChange()

  # Opens the birth selection popup
  #
  # @param event [Event] click event, prevented.
  toggleBirth: (event) =>
    # prevent, or popup won't show
    event?.preventDefault()
    event?.stopPropagation()
    @birthOpts.open = not @birthOpts.open

  # **private**
  # Update internal state when displayed dancer has changed.
  #
  # @param value [Dancer] new dancer's value
  _updateRendering: (value) =>
    @src?.removeListener 'change', @_onChange
    @src = value
    @src?.on 'change', @_onChange
    @_previous = @src?.toJSON()
    @isNew = not @src?.id?

    # reset birth date to dancer's one
    @birthOpts.open = false
    @birthOpts.value = if moment.isMoment @src?.birth then @src?.birth.toDate() else null

    # translate the "known by" possibilities into a list of boolean
    @knownBy = {}
    for value of i18n.knownByMeanings 
      @knownBy[value] = _.contains @src?.knownBy, value
    @knownByOther = _.find @src?.knownBy, (value) -> not(value of i18n.knownByMeanings)
    
    @_onChange()

  # **private**
  # Value change handler: check if dancer has changed from its previous values
  _onChange: =>
    # TODO waiting for https://github.com/angular/angular.js/pull/7645
    @scope.onChange?(model: @src, hasChanged: @src?._v is -1 or not _.isEqual @_previous, @src?.toJSON())

# The payment directive displays and edit dancer's payment
app.directive 'dancer', ->
  # directive template
  templateUrl: "dancer.html"
  # will replace hosting element
  replace: true
  # transclusion is needed to be properly used within ngRepeat
  transclude: true
  # applicable as element and attribute
  restrict: 'EA'
  # controller
  controller: DancerDirective
  controllerAs: 'ctrl'
  bindToController: true
  # parent scope binding.
  scope: 
    # displayed dancer
    src: '='
    # loading handler. Invoked when a dancer was retrieve by typahead, to be changed. 'model' parameters hold the selected value
    onLoad: '&'
    # change handler. Concerned dancer is a 'model' parameter, change status is a 'hasChagned' parameter
    onChange: '&?'
