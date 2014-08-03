_ = require 'underscore'
ListController = require './list' 
i18n = require '../labels/common'

module.exports = class ExpandedListController extends ListController

  # Controller dependencies
  @$inject: ['$scope', '$state', 'dialog', 'export']

  # Link to export service
  export: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Angular current scope
  # @param state [Object] Angular state provider
  # @param dialog [Object] Angular dialog service
  # @param export [Export] Export service
  constructor: (scope, state, @dialog, @export) -> 
    super scope, state
    @scope.i18n = i18n
    # keeps current sort for inversion
    @scope.sort = null
    @scope.sortAsc = true

  # Sort list by given attribute and order
  #
  # @param attr [String] sort attribute
  onSort: (attr) =>
    # invert if using same sort.
    if attr is @scope.sort
      @scope.list.reverse()
      @scope.sortAsc = !@scope.sortAsc
    else
      @scope.sortAsc = true
      @scope.sort = attr
      # specific attributes
      if attr is 'due'
        attr = (model) -> model?.registrations?[0]?.due() 
      else if attr is 'address'
        attr = (model) -> model?.address?.zipcode
      @scope.list = _.sortBy @scope.list, attr

  # Choose a target file and export list as xlsx
  onExport: =>
    return unless @scope.list?.length > 0
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
      @export.toFile filePath, @scope.list, (err) =>
        waitingDialog.close()
        if err?
          console.error "Export failed: #{err}"
          # displays an error dialog
          @scope.$apply =>
            @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.err.exportFailed, err.message), [label: i18n.btn.ok]

    dialog.trigger 'click'

  # Export email as string
  onExportEmails: =>
    return unless @scope.list?.length > 0
    emails = _.uniq(dancer.email.trim() for dancer in @scope.list when dancer.email?.trim().length > 0).sort().join ', '
    # put in the system clipboard
    clipboard = gui.Clipboard.get()
    clipboard.set emails, 'text'
    # display a popup with string to copy
    @dialog.messageBox i18n.ttl.export, _.sprintf(i18n.msg.exportEmails, emails), [label: i18n.btn.ok]