class LayoutDirective

  # Controller dependencies
  @$inject: ['$scope', '$element', '$transclude', '$rootScope', '$state']

  # Angular's state provider
  state: null

  # navigation links, an array of objects containing properties:
  # - label [String] displayed label with i18n filter
  # - icon [String] optionnal icon name (prepended with 'glyphicon-')
  # - action [Function] function invoked (without argument) when clicked
  links: []

  # contextual actions, an array of objects containing properties:
  # - label [String] displayed label with i18n filter
  # - icon [String] optionnal icon name (prepended with 'glyphicon-')
  # - action [Function] function invoked (without argument) when clicked
  actions: []

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive own scope, used to detect destruction
  # @param element [Object] directive own DOM element
  # @param transclude [Function] transclusion function, to get inner content
  # @param rootScope [Object] Angular global scope, for digest triggering
  # @param states [Object] Angular's state provider
  constructor: (scope, element, transclude, rootScope, @state) ->
    innerDom = null
    innerScope = null

    @links = [
      {label: 'btn.newDancer', icon: 'user', action: => @state.go 'list.card', {id:null}, reload: true}
      {label: 'btn.planning', icon: 'calendar', action: => @state.go 'list.planning'}
      {label: 'btn.detailed', icon: 'th-list', action: => @state.go 'detailed'}
      {label: 'btn.lessons', icon: 'education', action: => @state.go 'lessons'}
      {label: 'btn.invoice', icon: 'euro', action: => @state.go 'list.invoice'}
      {label: 'btn.stats', icon: 'dashboard', action: => @state.go 'stats'}
      {label: 'btn.settings', class: 'settings', icon: 'wrench', action: => @state.go 'settings'}
    ]

    unwatch = rootScope.$on '$stateChangeSuccess', @_updateLinks

    @_updateLinks()

    # replace anchor per transcluded element to keep DOM clean
    transclude (clone, scope) =>
      $(element).find('.anchor').replaceWith clone
      innerDom = clone
      innerScope = scope

    # but we need to handle destruction by ourselves
    scope.$on '$destroy', =>
      unwatch?()
      innerDom?.remove()
      innerScope?.$destroy()

  # **private**
  # Update active link to reflext current state
  _updateLinks: =>
    link.active = false for link in @links
    switch @state.current.name
      when 'list.card' then @links[0].active = true
      when 'list.planning' then @links[1].active = true
      when 'detailed' then @links[2].active = true
      when 'lessons' then @links[3].active = true
      when 'list.invoice' then @links[4].active = true
      when 'stats' then @links[5].active = true
      when 'settings' then @links[6].active = true

# The layout directive add general footer, menu and header to all views
module.exports = (app) ->
  app.directive 'layout', ->
    # directive template
    templateUrl: 'layout.html'
    # will replace hosting element
    replace: true
    transclude: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: LayoutDirective
    controllerAs: 'layout'
    bindToController: true
    scope:
      # contextual actions
      actions: '=?'