
class LayoutDirective
                
  # Controller dependencies
  @$inject: ['$scope', '$element', '$transclude']

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive own scope, used to detect destruction
  # @param element [Object] directive own DOM element
  # @param transclude [Function] transclusion function, to get inner content
  constructor: (scope, element, transclude) ->
    innerDom = null
    innerScope = null
    # replace anchor per transcluded element to keep DOM clean
    transclude (clone, scope) =>
      $(element).find('.anchor').replaceWith clone
      innerDom = clone
      innerScope = scope
    # but we need to handle destruction by ourselves
    scope.$on '$destroy', =>
      innerDom?.remove()
      innerScope?.$destroy()

# The layout directive add general footer, menu and header to all views
module.exports = (app) ->
  app.directive 'layout', ->
    # directive template
    template: '<div class="column-and-main"><div class="anchor"></div></div>'
    # will replace hosting element
    replace: true
    transclude: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: LayoutDirective
    controllerAs: 'ctrl'
    bindToController: true
    scope: {}