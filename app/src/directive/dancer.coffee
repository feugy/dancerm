_ = require 'lodash'
moment = require 'moment'
i18n = require '../labels/common'
Dancer = require '../model/dancer'

class DancerDirective
                
  # Controller dependencies
  @$inject: ['$q']

  # Labels for rendering
  i18n: i18n

  # Indicates whether the edited dancer has never been saved
  isNew: false

  # Option used to configure birth selection popup
  birthOpts: 
    value: null
    open: false
    showWeeks: false
    startingDay: 1
    showButtonBar: false

  # Angular's promise factory
  q: null

  # **private**
  # Dancers's search request in progress
  _reqInProgress: false

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param q [Object] Angular's promise factory
  constructor: (@q) ->
    @_reqInProgress = false

    @birthOpts =
      showWeeks: false
      startingDay: 1
      showButtonBar: false

    @isNew = @src?._v is -1 and @canLoad

    # reset birth date to dancer's one
    @birthOpts.open = false
    @birthOpts.value = if moment.isMoment @src?.birth then @src?.birth.format i18n.formats.birth else null

  # Invoked by view to update dancer's title according to selected item
  #
  # @param selected [String] the new dancer's title
  setTitle: (selected) =>
    unless selected is i18n.lbl.choose
      @src?.title = selected 
    @onChange?($field: 'title')

  # Search within existing models a match on given attribute
  # Only available when dancer is not saved yet.
  #
  # @param attr [String] matching attribute name
  # @param typed [String] typed string
  # @return a promise resolved with relevant models
  findByAttr: (attr, typed, done) =>
    # disable if request in progress
    return [] if @_reqInProgress
    deffered = @q.defer()
    @_reqInProgress = true
    # prepare search conditions
    typed = typed.toLowerCase()
    condition = {}
    condition[attr] = new RegExp "^#{typed}", 'i'
    # find matching dancers
    Dancer.findWhere condition, (err, models) => 
      @_reqInProgress = false
      if err?
        console.error err
        return deffered.reject err
      deffered.resolve models
    deffered.promise

  # Invoked when date change in the date picker
  # Updates the dancer's birth date
  setBirth: =>
    @src?.birth = moment @birthOpts.value
    @onChange?($field: 'birth')
    
  # Opens the birth selection popup
  #
  # @param event [Event] click event, prevented.
  toggleBirth: (event) =>
    # prevent, or popup won't show
    event?.preventDefault()
    event?.stopPropagation()
    @birthOpts.open = not @birthOpts.open

  # check if field is missing or not
  #
  # @param field [String] field that is tested
  # @return a css class
  isRequired: (field) => 
    return 'invalid' if @requiredFields? and field in @requiredFields
    ''

# The payment directive displays and edit dancer's payment
module.exports = (app) ->
  app.directive 'dancer', ->
    # directive template
    templateUrl: 'dancer.html'
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
      # True to enable loading capabilities
      canLoad: '='
      # array of missing fields
      requiredFields: '='
      # loading handler. Invoked when a dancer was retrieve by typeahead, 'model' parameter containing loaded dancer
      onLoad: '&'
      # registration addition handler. Concerned dancer is a 'model' parameter
      onRegister: '&?'
      # dancer removal handler. Concerned dancer is a 'model' parameter
      onRemove: '&?'
      # used to propagate model modifications, invoked with $field as parameter
      onChange: '&?'