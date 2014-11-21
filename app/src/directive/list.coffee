_ = require 'lodash'

class ListDirective
                
  # Controller dependencies
  @$inject: ['$scope', '$element', '$filter']
  
  # JQuery enriched element for directive root
  $el: null

  # Angular's filter factory
  filter: null

  # list of displayed columns, containing an object with title and attr.
  # title is an i18n path and attr, either a dancer's attribute or a function (that take rendered dancer as parameter)
  columns: []

  # Displayed list
  list: []

  # **private**
  # Store current sort attribute
  _currentSort: null

  # **private**
  # Store if the current sort is descendant or not
  _isDesc: true

  # **private**
  # Count how many promises are currently in progress
  _waiting: 0

  # **private**
  # Displayed values, stored for sorting. Dancer id is used as key
  _displayedValues: {}
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param filter [Functino] angular's filter factory
  constructor: (scope, element, @filter) ->
    @$el = $(element)
    @$el.on 'click', @_onClick
    @_displayedValues = {}
    @_waiting = 0
    @_onRedrawList = _.debounce @_onRedrawList, 100

    scope.$watch 'ctrl.columns', @_onRedrawList
    scope.$watchCollection 'ctrl.list', @_onRedrawList
    # default sort is last name
    @_currentSort = 'lastname'

  # **private**
  # Entierly redraw the dancer's list
  _onRedrawList: (event) =>
    return unless @columns? and @list? and not @_inProgress
    @_inProgress = true
    @$el.empty().append @_renderHeader()
    body = $('<tbody>').appendTo @$el
    @_waiting = 0
    @_displayedValues = {}
    body.append (@_renderRow dancer, i for dancer, i in @list).join '' 
    @_callbackEnded()

  # **private**
  # Creates the header line for whole list
  _renderHeader: =>
    html = ['<thead><tr>']
    for {title, name} in @columns
      if name is @_currentSort
        if @_isDesc
          html.push '<th data-desc'
        else
          html.push '<th'
        html.push " data-attr='#{name}'><i class='glyphicon glyphicon-sort-by-alphabet", (unless @_isDesc then '-alt'), "'/>"
      else
        html.push "<th data-attr='#{name}'>"
      html.push @filter('i18n')(title), '</th>'
    html.push '</tr></thead>'
    html.join ''

  # **private**
  # Creates line for a single dancer
  #
  # @param dancer [Dancer] concerned dancer
  # @return the rendered string
  _renderRow: (dancer, idx) =>
    html = ['<tr data-row="', idx, '">']
    @_displayedValues[dancer.id] = {_idx: idx}
    @columns.forEach (column, i) =>
      value = ''
      if _.isFunction column.attr
        if column.attr.length is 2
          # model and callback: put an id to cell, and then change the value when available
          id = dancer.id + Math.floor Math.random()*100000
          @_waiting++
          column.attr dancer, (err, value) =>
            @_waiting--
            if err?
              console.error "failed to resolve #{column.name} of dancer #{dancer.id}: ", err
            else
              @$el.find("##{id}").replaceWith @_renderCell dancer, column.name, i, value, true
            @_callbackEnded()
          return html.push "<td id='", id, "'></td>"
        else
          # just model
          value = column.attr dancer
      else
        value = dancer[column.attr or column.name]
      
      html.push @_renderCell dancer, column.name, i, value, column.attr?
    html.push '</tr>'
    html.join ''

  # **private**
  # Render a single cell value
  #
  # @param dancer [Dancer] concerned dancer
  # @param attr [String] attribute for which value is rendered
  # @param col [Number] concerned column index wihin columns array
  # @param value [Any] rendered value
  # @param store [Boolean] store value for sort
  # @return the rendered string
  _renderCell: (dancer, attr, col, value, store) =>
    html = ['<td data-col="', col, '" ']
    if store
      # special case for birth : do not store displayed value
      stored = if attr is 'birth' then dancer.birth?.unix() or 0 else value 
      @_displayedValues[dancer.id][attr] = value
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
      else
        html.push '>', value
    html.push '</td>'
    html.join ''

  # **private**
  # Single click handler, that retrieve row and column.
  # Triggers scope on click handler
  #
  # @param event [Event] click event
  _onClick: (event) =>
    target = $(event.target)
    col = target.closest('td').data 'col'
    row = target.closest('tr').data 'row'
    if col? and row?
      @onClick?(model: @list[row], column: @columns[col].name)
    else 
      header = target.closest 'th'
      sort = header.data 'attr'
      isDesc = header.data('desc')?
      if sort?
        # just reverse sort order
        if @_currentSort is sort
          @_isDesc = not isDesc
          @list.reverse()
        else
          @_currentSort = sort
          @_isDesc = true
          @_sortList sort
        @_onRedrawList()
    true

  # **private**
  # Sort list with a given attribute
  #
  # @param column [String] column name used for sort
  _sortList: (column) =>
    # use model value or rendered value
    for {name, attr} in @columns when column is name
      console.log 'sort by attribute', name
      if attr?
        # sort by displayed values, and get ordered indexes.
        ordered = _.sortBy (model for id, model of @_displayedValues), column
        # order models with these indexes
        @list = (@list[_idx] for {_idx} in ordered)
      else
        # use model value
        @list = _.sortBy @list, column
      return @_onRedrawList()

  # **private**
  # Enable sort when waiting is finished
  _callbackEnded: =>
    return unless @_waiting is 0
    @_inProgress = false 
      
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
      # displayed dancer list
      list: '=src'
      # displayed columns
      columns: '='
      # click handler, invoked with concerned dancer as 'model' parameter, and column as 'column' parameter
      onClick: '&?'