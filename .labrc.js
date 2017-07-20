module.exports = {
  coverage: true,
  leaks: true,
  globals: '__core-js_shared__', // came from power-assert
  lint: false,
  'context-timeout': 5e3,
  transform: 'test/transform',
  verbose: true,
  reporter: ['html', 'console'],
  output: ['coverage/index.html', 'stdout']
}
