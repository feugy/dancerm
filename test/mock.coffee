module.exports = (electron, webContents) ->
  # mock electron dialogs
  electron.dialog.showOpenDialog = (opts, cb) ->
    console.log ">> invoke mock", opts
    process.on 'mock.showOpenDialog.cb', (result) ->
      console.log "mock !!", result
      cb result
    process.emit 'mock.showOpenDialog', opts
