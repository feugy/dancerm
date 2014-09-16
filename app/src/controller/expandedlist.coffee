_ = require 'underscore'
moment = require 'moment'
ListController = require './list' 
i18n = require '../labels/common'

module.exports = class ExpandedListController extends ListController

  # Controller dependencies
  @$inject: ['export', '$list', '$search'].concat ListController.$inject

  @declaration:
    controller: ExpandedListController
    controllerAs: 'ctrl'
    templateUrl: 'expandedlist.html'
  
  # Link to export service
  exporter: null

  # Sort column
  sort: null

  # Sort order: ascending if true
  sortAsc: true

  # Displayed columns
  columns: [
    {name: 'title', title: 'lbl.title'}
    {name: 'firstname', title: 'lbl.firstname'}
    {name: 'lastname', title: 'lbl.lastname'}
    {name: 'certified', title: 'lbl.certified', attr: (dancer) -> 
      dancer.lastRegistration().then (registration) -> registration?.certified(dancer) or false
    }, {name: 'due', title: 'lbl.due', attr: (dancer) -> 
      dancer.lastRegistration().then (registration) -> registration?.due() or 0
    }, {name: 'age', title: 'lbl.age', attr: (dancer) -> 
      if dancer.birth? then moment().diff dancer.birth, 'years' else ''
    }, {name: 'birth', title: 'lbl.birth', attr: (dancer) ->  
      if dancer.birth? then dancer.birth.format i18n.formats.birth else ''
    }, {name: 'knownBy', title: 'lbl.knownBy', attr: (dancer) -> 
      dancer.card.then (card) ->
        if card.knownBy
          ("<span class='known-by'>#{i18n.knownByMeanings[knownBy] or knownBy}</span>" for knownBy in card.knownBy).join ''
        else
          ''
    }, {name: 'phone', title: 'lbl.phone', attr: (dancer) -> 
      dancer.address.then (address) -> address?.phone
    }, {name: 'cellphone', title: 'lbl.cellphone'}
    {name: 'email', title: 'lbl.email'}
    {name: 'address', title: 'lbl.address', attr: (dancer) ->
      dancer.address.then (address) -> "#{address?.street} #{address?.zipcode} #{address?.city}"
    }]

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param state [Object] Angular state provider
  # @param dialog [Object] Angular dialog service
  # @param export [Export] Export service
  constructor: (@exporter, @list, @search, parentArgs...) -> 
    super parentArgs...
    # keeps current sort for inversion
    @sort = null
    @sortAsc = true
   
  # Sort list by given attribute and order
  #
  # @param attr [String] sort attribute
  onSort: (attr) =>
    # invert if using same sort.
    if attr is @sort
      @list.reverse()
      @sortAsc = !@sortAsc
    else
      @sortAsc = true
      @sort = attr
      # TODO specific attributes
      ###if attr is 'due'
        attr = (model) -> model?.registrations?[0]?.due() 
      else if attr is 'address'
        attr = (model) -> model?.address?.zipcode###
      @list = _.sortBy @list, attr

  # Choose a target file and export list as xlsx
  export: =>
    return unless @list?.length > 0
    dialog = $('<input style="display:none;" type="file" nwsaveas accept="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>')
    dialog.change (evt) =>
      filePath = dialog.val()
      dialog.remove()
      # dialog cancellation
      return unless filePath

      # waiting message box
      waitingDialog = null
      @rootScope.$apply => 
        waitingDialog = @dialog.messageBox i18n.ttl.export, i18n.msg.exporting

      # Perform export
      @exporter.toFile(filePath, @list).then( =>
        waitingDialog.close()
        @rootScope.$apply()
      ).catch (err) =>
        waitingDialog.close()
        console.error "Export failed: #{err}"
        # displays an error dialog
        @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.err.exportFailed, err.message), [label: i18n.btn.ok]
        @rootScope.$apply()

    dialog.trigger 'click'
    # to avoid isSecDom error https://docs.angularjs.org/error/$parse/isecdom?p0=ctrl.export%28%29
    null

  # Export email as string
  exportEmails: =>
    return unless @list?.length > 0
    emails = _.uniq(dancer.email.trim() for dancer in @list when dancer.email?.trim().length > 0).sort().join ', '
    # put in the system clipboard
    clipboard = gui.Clipboard.get()
    clipboard.set emails, 'text'
    # display a popup with string to copy
    @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.msg.exportEmails, emails), [label: i18n.btn.ok]