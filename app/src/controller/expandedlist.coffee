_ = require 'underscore'
moment = require 'moment'
ListController = require './list' 
i18n = require '../labels/common'

module.exports = class ExpandedListController extends ListController

  # Controller dependencies
  @$inject: ['export'].concat ListController.$inject

  # Link to export service
  exporter: null

  # Sort column
  sort: null

  # Sort order: ascending if true
  sortAsc: true

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param state [Object] Angular state provider
  # @param dialog [Object] Angular dialog service
  # @param export [Export] Export service
  constructor: (@exporter, parentArgs...) -> 
    super parentArgs...
    # keeps current sort for inversion
    @sort = null
    @sortAsc = true

  # Return age of dancer from the current date
  #
  # @param dancer [Dancer] the concerned dancer
  # @return the age in years
  getAge: (dancer) => 
    moment().diff dancer.birth, 'years'

  # Return birth of dancer properly formatted
  #
  # @param dancer [Dancer] the concerned dancer
  # @return the dancer's date of birth
  getBirth: (dancer) =>
    dancer.birth.format i18n.formats.birth

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
      # specific attributes
      if attr is 'due'
        attr = (model) -> model?.registrations?[0]?.due() 
      else if attr is 'address'
        attr = (model) -> model?.address?.zipcode
      @list = _.sortBy @list, attr

  # Choose a target file and export list as xlsx
  onExport: =>
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
      @exporter.toFile filePath, @list, (err) =>
        waitingDialog.close()
        if err?
          console.error "Export failed: #{err}"
          # displays an error dialog
          @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.err.exportFailed, err.message), [label: i18n.btn.ok]
          @rootScope.$digest()

    dialog.trigger 'click'

  # Export email as string
  onExportEmails: =>
    return unless @list?.length > 0
    emails = _.uniq(dancer.email.trim() for dancer in @list when dancer.email?.trim().length > 0).sort().join ', '
    # put in the system clipboard
    clipboard = gui.Clipboard.get()
    clipboard.set emails, 'text'
    # display a popup with string to copy
    @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.msg.exportEmails, emails), [label: i18n.btn.ok]