_ = require 'lodash'
moment = require 'moment'
i18n = require '../labels/common'

class AppMenuDirective
                
  # Controller dependencies
  @$inject: []
  
  # true if application is maximized
  isMaximized: false

  # global version, injected for template
  version: version

  # **private**
  # application window (nodeWebkit)
  _win: null
  
  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] directive scope
  # @param element [DOM] directive root element
  constructor: () ->
    @_win = gui.Window.get()
    @isMaximized = @_win.isMaximized

  # Application closure
  close: =>
    @_win.close()

  # Iconifiy application
  iconize: =>
    @_win.minimize()

  # Depending on maximized flag, restore or maximize application
  maximizeOrRestore: => 
    if @isMaximized
      @_win.unmaximize()
    else 
      @_win.maximize()
    @isMaximized = not @isMaximized

# The menu directive displays application main menu buttons
module.exports = (app) ->
  app.directive 'appMenu', ->
    # directive template
    templateUrl: "app_menu.html"
    # will replace hosting element
    replace: true
    # applicable as element and attribute
    restrict: 'EA'
    # controller
    controller: AppMenuDirective
    controllerAs: 'ctrl'
    bindToController: true