// Create the test window application
chrome.app.runtime.onLaunched.addListener(function() {
  chrome.app.window.create('test.html', {
    bounds: {
      width: 1200,
      height: 600
    }
  });
});