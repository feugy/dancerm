
# Controller class used for message boxes
class MessageBox

  @$inject: ['model', '$scope', '$modalInstance']

  # Dialog instance
  @_modal: null

  # Build Messagebox controller from given model
  # @param model [Object] attributes passed from upper
  # @param scope [Object] controller's scope
  # @param _modal [Object] current modal instance
  constructor: (model, scope, @_modal) ->
    scope[attr] = val for attr, val of model
    scope.close = @_modal.close

# Dialog service, based on angular ui bootstrap.
module.exports = class DialogProvider

  # **static**
  # DialogProvider's dependencies
  @$inject: ['$modal']

  # **private**
  # Angular UI's modal factory
  _modal: null

  # Build service singletong
  # @param modal [Function] Angular UI's modal factory
  constructor: (modal) ->
    @_modal = modal

  # opens a dialog fully configurable according to 
  # http://angular-ui.github.io/bootstrap/
  #
  # @param args [Object] Angular UI's modal arguments
  # @return a modal instance with its 'result' promise
  modal: (args) =>
    @_modal.open args

  # opens a message box
  #
  # @param title [String] dialog box title
  # @param message [String] dialog content message
  # @param buttons [Array<Object>] array of displayed buttons, containing
  # @option buttons label [String] button label
  # @option buttons result [Any] result used as dialog's close method parameter
  # @option buttons css [String] optionnal CSS class added to button
  # @return a modal instance with its 'result' promise
  messageBox: (title, message, buttons = []) =>
    @_modal.open 
      templateUrl: 'dialog_message.html'
      # TODO waiting for version angular-ui-bootstrap@0.12.0
      # https://github.com/angular-ui/bootstrap/commit/7b7cdf842278e86a677980d29bd74a1afd467ff1
      controllerAs: 'ctrl'
      controller: MessageBox
      resolve: model: -> {title: title, message: message, buttons: buttons}