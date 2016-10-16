{fixConsole} = require '../script/util/common'
ConfService = require '../script/service/conf'

# on DOM loaded
fixConsole()
win = nw.Window.get()
window.win = win

angular.element(win.window).on 'load', ->
  doc = angular.element(document)
  # adds dynamic styles
  doc.find('head').append "<style type='text/css'>#{global.styles['print']}</style>"

  # requires and registers custom class
  app = angular.module('printPreview', []).controller 'Print', window.customClass

  app.service 'conf', ConfService

  # Simple directive that whill replace current element with HTML raw text
  app.directive 'placeholder', ->
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # replace element with specified HTML
    link: (scope, elm, attrs) ->
      angular.element(elm).replaceWith attrs.placeholder

  # get filters
  require('../script/util/filters')(app)
  require('../script/directive/invoice_item')(app)

  angular.bootstrap doc.find('body'), ['printPreview', 'ngSanitize']
