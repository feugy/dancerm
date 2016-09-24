_ = require 'lodash'

class ListDirective

  # Controller dependencies
  @$inject: ['$scope', '$element', '$filter']

  # JQuery enriched element for directive root
  $el: null

  # Angular's filter factory
  filter: null

  # list of displayed columns, containing an object with following properties:
  # - name [String] is the model property name that holds displayed value, also use as sorting key
  # - title [Sting] is an i18n path used as column header
  # - attr [String|Function], either a string or a function:
  # If attr not provided, name will be used to get value from model.
  # If attr is a string, it will be considered as the model's property name which holds displayed value
  # If attr is a function with a single parameter, it is invoked with the model as parameter, and return is used as displayed value
  # If attr is a function with two parameters, it is invoked with the model and a callback, expected to be called with an
  # optional error as first parameter, and the displayed value as second parameter.
  # - sorter [Function] if provided, this function is invoked with model and displayed value as parameter. Its return is used for sorting
  columns: []

  # Displayed list
  list: []

  # Store current sort attribute
  currentSort: null

  # **private**
  # Store if the current sort is descendant or not
  _isDesc: true

  # **private**
  # Count how many promises are currently in progress
  _waiting: 0

  # **private**
  # Displayed values, stored for sorting. Model id is used as key
  _sortedValues: {}

  # **private**
  # Flag to avoid concurrent renderings
  _inProgress: false

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param filter [Function] angular's filter factory
  constructor: (scope, element, @filter) ->
    @$el = $(element)
    @$el.on 'click', @_onClick
    @$el.on 'change', @_onToggle
    @_sortedValues = {}
    @_waiting = 0
    @_onRedrawList = _.debounce @_onRedrawList, 100

    unwatchs = [
      scope.$watch 'ctrl.columns', @_onRedrawList
      scope.$watchCollection 'ctrl.list', @_onRedrawList
    ]

    # free listeners
    scope.$on '$destroy', =>
      unwatch?() for unwatch in unwatchs
      @$el.off()

  # **private**
  # Entierly redraw the model's list
  _onRedrawList: (event) =>
    return unless @columns? and @list? and not @_inProgress
    @_inProgress = true
    @$el.empty().append @_renderHeader()
    body = $('<tbody class="hideable">').appendTo @$el
    @_waiting = 0
    @_sortedValues = {}
    body.append (@_renderRow model, i for model, i in @list).join ''
    @_allValuesRendered()

  # **private**
  # Creates the header line for whole list
  _renderHeader: =>
    html = ['<thead><tr>']
    for {title, name, selectable} in @columns
      if name is @currentSort
        if @_isDesc
          html.push '<th data-desc'
        else
          html.push '<th'
        html.push " data-attr='#{name}'><i class='glyphicon glyphicon-sort-by-alphabet", (unless @_isDesc then '-alt'), "'/>"
      else
        html.push "<th #{if name? then "data-attr='#{name}'" else ''}>"

      if title
        html.push @filter('i18n')(title)
      else if selectable
        html.push '<input type="checkbox"/>'
      html.push '</th>'
    html.push '</tr></thead>'
    html.join ''

  # **private**
  # Creates line for a single model
  #
  # @param model [Persisted] concerned model
  # @param idx [Number] model index in the entire list
  # @return the rendered string
  _renderRow: (model, idx) =>
    html = ["<tr data-row='#{idx}' data-id='#{model.id}'>"]
    @_sortedValues[model.id] = {_idx: idx}
    @columns.forEach (column, i) =>
      value = ''
      if _.isFunction column.attr
        if column.attr.length is 2
          # model and callback: put an id to cell, and then change the value when available
          id = model.id + Math.floor Math.random()*100000
          @_waiting++
          column.attr model, (err, value) =>
            @_waiting--
            if err?
              console.error "failed to resolve #{column.name} of model #{model.id}: ", err
            else
              @$el.find("##{id}").replaceWith @_renderCell model, column.name, i, value, column.sorter, true
            @_allValuesRendered()
          return html.push "<td id='", id, "'></td>"
        else
          # just model
          value = column.attr model
      else
        value = model[column.attr or column.name]

      html.push @_renderCell model, column.name, i, value, column.sorter, column.attr?
    html.push '</tr>'
    html.join ''

  # **private**
  # Render a single cell value
  #
  # @param model [Persisted] concerned model
  # @param attr [String] attribute for which value is rendered
  # @param col [Number] concerned column index wihin columns array
  # @param value [Any] rendered value
  # @param sorter [Function] optional sorter function applied to displayed value
  # @param store [Boolean] store value for sort
  # @return the rendered string
  _renderCell: (model, attr, col, value, sorter, store) =>
    html = ['<td data-col="', col, '" ']
    # sortable value might be different from displayed value
    unless @columns[col].selectable?
      sortableValue = value
      if sorter?
        sortableValue = sorter model, value
      else if _.isString value
        sortableValue = value.trim().toLowerCase()
      @_sortedValues[model.id][attr] = sortableValue

    # Avoid displaying nulls
    value = '' unless value?

    # TODO find a way to externalize this code
    # column specific rendering
    switch @columns[col].name
      when 'due'
        if value > 0
          html.push 'class="text-error"><span>', value, @filter('i18n')('lbl.currency'), '</span>'
        else
          html.push '><i class="glyphicon glyphicon-ok"/>'
      when 'certified'
        html.push '><i class="glyphicon glyphicon-'
        html.push if value then 'ok' else 'exclamation-sign'
        html.push '"/>'
      when 'sent', 'invoiced'
        if value then html.push '><i class="glyphicon glyphicon-ok"/>' else '/>'
      else
        html.push unless @columns[col].selectable? then ">#{value}" else
          if @columns[col].selectable model then 'data-selectable="true"><input type="checkbox"/>' else ''

    html.push '</td>'
    html.join ''

  # **private**
  # Reorder rows to reflect @list order, and also redraw header
  _updateRowOrder: () =>
    @$el.find('thead').replaceWith @_renderHeader()
    body = @$el.find 'tbody'
    # list has the new order @_sortedValues[id]._idx is the old position
    rows = (for {id}, i in @list
      @_sortedValues[id]._idx = i
      body.find "tr[data-id='#{id}']"
    )
    body.empty().append rows

  # **private**
  # Single click handler, that retrieve row and column.
  # Triggers scope on click handler
  #
  # @param event [Event] click event
  _onClick: (event) =>
    target = $(event.target)
    # selectable cell should not trigger clicks
    return if target.closest('td').data 'selectable'
    col = target.closest('td').data 'col'
    row = target.closest('tr').data 'row'
    if col? and row?
      @onClick?(model: @list[row], column: @columns[col].name)
    else
      header = target.closest 'th'
      sort = header.data 'attr'
      isDesc = header.data('desc')?
      if sort?
        if @currentSort is sort
          @_sortList @currentSort, not @_isDesc
        else
          @_sortList sort, true
        @_updateRowOrder()
    true

  # **private**
  # Checkbox toggle handler. If modified checkbox is in header, toggle all other checkbox
  #
  # @param event [Event] click event
  _onToggle: (event) =>
    target = $(event.target)
    selected = target.closest('input').prop 'checked'
    if target.closest('th').length > 0
      # toggle checkbox from the header row: change status of all other checkboxes
      for input in @$el.find 'td > input'
        $(input).prop 'checked', selected
        model = @list[$(input).closest('tr').data 'row']
        @onToggle?(model: model, selected: selected)
    else
      # fire event with proper model
      col = target.closest('td').data 'col'
      row = target.closest('tr').data 'row'
      @onToggle?(model: @list[row], selected: selected)

  # **private**
  # Sort list with a given attribute.
  # @_sortedValues must have been populated
  # @list, @currentSort and @_isDesc are modified
  # No redraw is performed
  #
  # @param column [String] column name used for sort
  # @param isDesc [Boolean] true for descending sort, false for ascending
  _sortList: (column, isDesc) =>
    @currentSort = column
    @_isDesc = isDesc
    console.log ">> sort by #{@currentSort} #{@_isDesc}", (values for id, values of @_sortedValues)
    # sort by displayed values, and get ordered indexes.
    ordered = _.sortBy (values for id, values of @_sortedValues), column
    # order models with these indexes
    @list = (@list[_idx] for {_idx} in ordered)
    @list.reverse() unless @_isDesc

  # **private**
  # Enable sort when waiting is finished
  _allValuesRendered: =>
    return unless @_waiting is 0
    @_inProgress = false
    # sorting
    @_sortList @currentSort, @_isDesc
    @_updateRowOrder()

# The tags directive displays tags relative at search criteria
module.exports = (app) ->
  app.directive 'list', ->
    # directive template
    template: "<table class='table'></table>"
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: ListDirective
    controllerAs: 'ctrl'
    bindToController: true
    # parent scope binding.
    scope:
      # displayed model list
      list: '=src'
      # displayed columns
      columns: '='
      # current sort column name
      currentSort: '='
      # click handler, invoked with concerned model as 'model' parameter, and column as 'column' parameter
      onClick: '&?'
      # selection toggle handler, invoked with concerned model as 'model' parameter, selection status as 'selected' parameter
      onToggle: '&?'