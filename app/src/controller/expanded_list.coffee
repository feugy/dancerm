_ = require 'lodash'
{join} = require 'path'
moment = require 'moment'
i18n = require '../labels/common'
ListController = require './tools/list'

module.exports = class ExpandedListController extends ListController

  # Controller dependencies
  @$inject: ['$scope', 'cardList', 'invoiceList', 'lessonList', '$state', 'export', 'dialog']

  @declaration:
    controller: ExpandedListController
    controllerAs: 'ctrl'
    templateUrl: 'expanded_list.html'

  # Columns used depending on the selected service
  @colSpec:
    card: [
      {name: 'title', title: 'lbl.title'}
      {name: 'firstname', title: 'lbl.firstname'}
      {name: 'lastname', title: 'lbl.lastname'}
      {name: 'certified', title: 'lbl.certified', attr: (dancer, done) ->
        dancer.getLastRegistration (err, registration) -> done err, registration?.certified(dancer) or false
      }
      {name: 'due', title: 'lbl.due', attr: (dancer, done) ->
        dancer.getLastRegistration (err, registration) -> done err, registration?.due() or 0}
      {name: 'age', title: 'lbl.age', attr: (dancer) ->
        if dancer.birth? then moment().diff dancer.birth, 'years' else ''}
      {name: 'birth', title: 'lbl.birth', attr: (dancer) ->
        if dancer.birth? then dancer.birth.format i18n.formats.birth else ''}
      {name: 'knownBy', title: 'lbl.knownBy', attr: (dancer, done) ->
        dancer.getCard (err, card) ->
          return done err, "" if err? or not card.knownBy
          done null, ("<span class='known-by'>#{i18n.knownByMeanings[knownBy] or knownBy}</span>" for knownBy in card.knownBy).join ''}
      {name: 'phone', title: 'lbl.phone', attr: (dancer, done) ->
        dancer.getAddress (err, address) -> done err, address?.phone}
      {name: 'cellphone', title: 'lbl.cellphone'}
      {name: 'email', title: 'lbl.email'}
      {name: 'address', title: 'lbl.address', attr: (dancer, done) ->
        dancer.getAddress (err, address) -> done err, "#{address?.street} #{address?.zipcode} #{address?.city}"}
    ]
    invoice: [
      {name: 'school', title: 'lbl.school', attr: ({selectedSchool}) -> i18n.lbl.schools[selectedSchool].owner}
      {name: 'ref', title: 'lbl.ref'}
      {name: 'date', title: 'lbl.invoiceDate', attr: ({date}) -> date.format i18n.formats.invoice}
      {name: 'sent', title: 'lbl.sent', attr: ({sent}) -> sent?}
      {name: 'total', title: 'lbl.invoiceTotal', attr: ({total}) -> "#{total} #{i18n.lbl.currency}"}
      {name: 'dutyFreeTotal', title: 'lbl.dutyFreeTotal', attr: ({dutyFreeTotal}) -> "#{dutyFreeTotal} #{i18n.lbl.currency}"}
      {name: 'taxTotal', title: 'lbl.taxTotal', attr: ({taxTotal}) -> "#{taxTotal} #{i18n.lbl.currency}"}
      {name: 'discount', title: 'lbl.discount', attr: ({discount}) -> "#{discount} %"}
      {name: 'customer.name', title: 'lbl.customer', attr: ({customer}) -> customer.name}
      {name: 'customer.address', title: 'lbl.address', attr: ({customer: {street, zipcode, city}}) -> "#{street} #{zipcode} #{city}"}
    ]
    lesson: [
      {noSort: true, selectable: (model) -> not model.invoiceId?}
      {name: 'teacher', title: 'lbl.teacherColumn'}
      {name: 'date', title: 'lbl.hours', attr: ({date}) -> date?.format i18n.formats.lesson}
      {name: 'invoiced', title: 'lbl.lessonInvoiced', attr: ({invoiceId}) -> invoiceId?}
      {name: 'duration', title: 'lbl.duration', attr: ({duration}) -> "#{duration} #{i18n.lbl.durationUnit}"}
      {name: 'price', title: 'lbl.price', attr: ({price}) -> "#{price} #{i18n.lbl.currency}"}
      {name: 'details', title: 'lbl.details'}
    ]

  # Link to Angular's dialog service
  dialog: null

  # Link to export service
  exporter: null

  # Displayed columns
  columns: []

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] controller's own scope, for event listening
  # @param cardList [Object] Card list service
  # @param invoiceList [InvoiceListService] service responsible for invoice list
  # @param lessonList [LessonListService] service responsible for lesson list
  # @param state [Object] Angular's state provider
  # @param export [Object] Export service
  # @param dialog [Object] Angular's dialog service
  constructor: (scope, cardList, invoiceList, lessonList, state, @exporter, @dialog) ->
    super scope, cardList, invoiceList, lessonList, state
    service.on 'search-end', @_updateActions for service in [@cardList, @invoiceList, @lessonList]
    # update actions on search end
    @scope.$on '$destroy', =>
      service.removeListener 'search-end', @_updateActions for service in [@cardList, @invoiceList, @lessonList]

    @_updateActions()

  # Choose a target file and export list as xlsx
  export: =>
    return unless @service.list?.length > 0
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
      @exporter.toFile filePath, @service.list, (err) =>
        waitingDialog.close()
        if err?
          console.error "Export failed: #{err}"
          # displays an error dialog
          @dialog.messageBox i18n.ttl.export, _.template(i18n.err.exportFailed)(err), [label: i18n.btn.ok]
        @scope.$apply()

    dialog.trigger 'click'
    # to avoid isSecDom error https://docs.angularjs.org/error/$parse/isecdom?p0=ctrl.export%28%29
    null

  # Export email as string
  exportEmails: =>
    return unless @service.list?.length > 0
    emails = _.uniq(dancer.email.trim() for dancer in @service.list when dancer.email?.trim().length > 0).sort().join ', '
    # put in the system clipboard
    clipboard = nw.Clipboard.get()
    clipboard.set emails, 'text'
    # display a popup with string to copy
    @dialog.messageBox i18n.ttl.export, _.template(i18n.msg.exportEmails)(emails:emails), [label: i18n.btn.ok]

  # **private**
  # When search is finished, update actions regarding the number of results
  _updateActions: =>
    @actions = []
    if @service.list.length > 0 and @service is @cardList
      @actions.push {label: 'btn.export', icon: 'export', action: @export},
        {label: 'btn.printAddresses', icon: 'envelope', action: @service.printAddresses},
        {label: 'btn.exportEmails', icon: 'tags', action: @exportEmails}