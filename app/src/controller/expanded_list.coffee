_ = require 'lodash'
{join} = require 'path'
moment = require 'moment'
i18n = require '../labels/common'

module.exports = class ExpandedListController

  # Controller dependencies
  @$inject: ['$scope', 'cardList', 'export', 'dialog']

  @declaration:
    controller: ExpandedListController
    controllerAs: 'ctrl'
    templateUrl: 'expanded_list.html'

  # Controller's own scope, for event listening
  scope: null
  
  # Link to card list service
  cardList: null
      
  # Link to Angular's dialog service
  dialog: null

  # Link to export service
  exporter: null

  # Sort column
  sort: null

  # Sort order: ascending if true
  sortAsc: true

  # contextual actions, an array of objects containing properties:
  # - label [String] displayed label with i18n filter
  # - icon [String] optionnal icon name (prepended with 'glyphicon-')
  # - action [Function] function invoked (without argument) when clicked
  # modified by main view's controller
  actions: []

  # Displayed columns
  columns: [
    {name: 'title', title: 'lbl.title'}
    {name: 'firstname', title: 'lbl.firstname'}
    {name: 'lastname', title: 'lbl.lastname'}
    {name: 'certified', title: 'lbl.certified', attr: (dancer, done) -> 
      dancer.getLastRegistration (err, registration) -> done err, registration?.certified(dancer) or false
    }, {name: 'due', title: 'lbl.due', attr: (dancer, done) -> 
      dancer.getLastRegistration (err, registration) -> done err, registration?.due() or 0
    }, {name: 'age', title: 'lbl.age', attr: (dancer) -> 
      if dancer.birth? then moment().diff dancer.birth, 'years' else ''
    }, {name: 'birth', title: 'lbl.birth', attr: (dancer) ->  
      if dancer.birth? then dancer.birth.format i18n.formats.birth else ''
    }, {name: 'knownBy', title: 'lbl.knownBy', attr: (dancer, done) -> 
      dancer.getCard (err, card) ->
        return done err, "" if err? or not card.knownBy
        done null, ("<span class='known-by'>#{i18n.knownByMeanings[knownBy] or knownBy}</span>" for knownBy in card.knownBy).join ''
    }, {name: 'phone', title: 'lbl.phone', attr: (dancer, done) -> 
      dancer.getAddress (err, address) -> done err, address?.phone
    }, {name: 'cellphone', title: 'lbl.cellphone'}
    {name: 'email', title: 'lbl.email'}
    {name: 'address', title: 'lbl.address', attr: (dancer, done) ->
      dancer.getAddress (err, address) -> done err, "#{address?.street} #{address?.zipcode} #{address?.city}"
    }]

  # **private**
  # single print preview insance
  _preview: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] controller's own scope, for event listening
  # @param cardList [Object] Card list service
  # @param export [Object] Export service
  # @param dialog [Object] Angular's dialog service
  constructor: (@scope, cardList, @exporter, @dialog) -> 
    # keeps current sort for inversion
    @sort = null
    @sortAsc = true
    @_preview = null

    # update actions on search end
    @scope.$on '$destroy', => @cardList.removeListener 'search-end', @_updateActions

    _.delay =>
      # defer affectation to avoid building list while animating view transition
      @cardList = cardList
      @cardList.on 'search-end', @_updateActions
      @_updateActions()
      @scope.$apply()
    , 500

  # Sort list by given attribute and order
  #
  # @param attr [String] sort attribute
  onSort: (attr) =>
    # invert if using same sort.
    if attr is @sort
      @cardList.list.reverse()
      @sortAsc = !@sortAsc
    else
      @sortAsc = true
      @sort = attr
      # TODO specific attributes
      ###if attr is 'due'
        attr = (model) -> model?.registrations?[0]?.due() 
      else if attr is 'address'
        attr = (model) -> model?.address?.zipcode###
      @cardList.list = _.sortBy @cardList.list, attr

  # Choose a target file and export list as xlsx
  export: =>
    return unless @cardList.list?.length > 0
    dialog = $('<input style="display:none;" type="file" nwsaveas accept="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>')
    dialog.change (evt) =>
      filePath = dialog.val()
      dialog.remove()
      # dialog cancellation
      return unless filePath

      # waiting message box
      waitingDialog = null
      @scope.$apply => 
        waitingDialog = @dialog.messageBox i18n.ttl.export, i18n.msg.exporting

      # Perform export
      @exporter.toFile filePath, @cardList.list, (err) =>
        waitingDialog.close()
        if err?
          console.error "Export failed: #{err}"
          # displays an error dialog
          @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.err.exportFailed, err.message), [label: i18n.btn.ok]
        @scope.$apply()

    dialog.trigger 'click'
    # to avoid isSecDom error https://docs.angularjs.org/error/$parse/isecdom?p0=ctrl.export%28%29
    null

  # Displays addresses printing window
  printAddresses: =>
    return @_preview.focus() if @_preview?
    return unless @cardList.list?.length > 0
    _console = global.console 
    try
      @_preview = gui.Window.open "file://#{join(__dirname, '..', '..', 'template', 'addresses_print.html').replace(/\\/g, '/')}",
        frame: true
        toolbar: false
        title: window.document.title
        icon: require('../../../package.json')?.window?.icon
        focus: true
        # size to A4 format, 3/4 height
        width: 790
        height: 400

      # obviously, a bug !
      global.console = _console
        
      # set displayed list and wait for closure
      @_preview.list = @cardList.list
      @_preview.on 'closed', => @_preview = null
    catch err
      console.error err
    # to avoid isSecDom error https://docs.angularjs.org/error/$parse/isecdom?p0=ctrl.export%28%29
    null


  # Export email as string
  exportEmails: =>
    return unless @cardList.list?.length > 0
    emails = _.uniq(dancer.email.trim() for dancer in @cardList.list when dancer.email?.trim().length > 0).sort().join ', '
    # put in the system clipboard
    clipboard = gui.Clipboard.get()
    clipboard.set emails, 'text'
    # display a popup with string to copy
    @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.msg.exportEmails, emails), [label: i18n.btn.ok]

  # **private**
  # When search is finished, update actions regarding the number of results
  _updateActions: =>
    if @cardList.list.length > 0
      @actions = [
        {label: 'btn.export', icon: 'export', action: @export},
        {label: 'btn.printAddresses', icon: 'envelope', action: @printAddresses}
        {label: 'btn.exportEmails', icon: 'tags', action: @exportEmails}
      ]
    else
      @actions = []