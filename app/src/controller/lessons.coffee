_ = require 'lodash'
moment = require 'moment'
i18n = require '../labels/common'
Lesson = require '../model/invoice'

# Display lesson planning, and allows to add/edit/remove lessons
class LessonsController

  # Controller dependencies
  @$inject: ['$scope', '$rootScope']

  # Route declaration
  @declaration:
    controller: LessonsController
    controllerAs: 'ctrl'
    templateUrl: 'lessons.html'

  # for rendering
  i18n: i18n

  # Controller's own scope, for change detection
  scope: null

  # Angular's global scope, for digest triggering
  rootScope: null

  # Controller constructor: bind methods and attributes to current scope
  #
  # @param scope [Object] Controller's own scope, for change detection
  # @param rootscope [Object] Angular global scope for digest triggering
  constructor: (@scope, @rootScope) ->

module.exports = LessonsController