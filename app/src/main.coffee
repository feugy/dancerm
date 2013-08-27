# Create the main window application
chrome.app.runtime.onLaunched.addListener ->
  chrome.app.window.create '../template/app.html', 
    bounds:
      width: 1250
      height: 700