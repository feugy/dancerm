# Create the main window application
chrome.app.runtime.onLaunched.addListener ->
  chrome.app.window.create '../template/app.html', 
    bounds:
      width: 800,
      height: 600