_ = require 'underscore'

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
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  # @param filter [Functino] angular's filter factory
  constructor: (scope, element, @filter) ->
    @$el = $(element)
    @$el.on 'click', @_onClick

    scope.$watch 'ctrl.columns', @_onRedrawList
    scope.$watchCollection 'ctrl.list', @_onRedrawList
    @_onRedrawList()

  # **private**
  # Entierly redraw the dancer's list
  _onRedrawList: (event) =>
    return unless @columns? and @list?
    @$el.empty().append @_renderHeader()
    body = $('<tbody>').appendTo @$el
    body.append @_renderRow dancer, i for dancer, i in @list
      

  # **private**
  # Creates the header line for whole list
  _renderHeader: =>
    html = ['<thead><tr>']
    for {title} in @columns
      html.push '<th>', @filter('i18n')(title), '</th>'
    html.push '</tr></thead>'
    html.join ''

  # **private**
  # Creates line for a single dancer
  #
  # @param dancer [Dancer] concerned dancer
  # @return the rendered string
  _renderRow: (dancer, idx) =>
    html = ['<tr data-row="', idx, '">']
    @columns.forEach (column, i) =>
      value = ''
      id = null
      if _.isFunction column.attr
        value = column.attr dancer
      else
        value = dancer[column.attr or column.name]

      if _.isObject(value) and _.isFunction value.then
        # in case of a promise, put an id to cell, and then change the value when available
        id = Math.floor Math.random()*100000
        value.then( (value) =>
          @$el.find("##{id}").replaceWith @_renderCell dancer, i, value
        ).catch (err) => console.error "failed to resolve #{column.name} of dancer #{dancer.id}: ", err
        html.push "<td id='", id, "'></td>"
      else
        html.push @_renderCell dancer, i, value
    html.push '</tr>'
    html.join ''

  # **private**
  # Render a single cell value
  #
  # @param dancer [Dancer] concerned dancer
  # @param col [Number] concerned column index wihin columns array
  # @param value [Any] rendered value
  # @return the rendered string
  _renderCell: (dancer, col, value) =>
    html = ['<td data-col="', col, '" ']
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
    true
    
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