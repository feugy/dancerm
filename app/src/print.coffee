{remote} = require 'electron'
windowManager = remote.require 'electron-window-manager'
{fixConsole, dumpError} = require '../script/util/common'
ConfService = require '../script/service/conf'
require('moment').locale 'fr'

# on DOM loaded
process.on 'uncaughtException', dumpError()
fixConsole()

angular.element(window).on 'load', ->
  doc = angular.element(document)
  # adds dynamic styles
  doc.find('head').append "<style type='text/css'>#{windowManager.sharedData.fetch 'styles'}</style>"

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

  angular.bootstrap doc.find('body'), ['printPreview', 'ngSanitize', 'monospaced.elastic']
