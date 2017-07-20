const coffee = require('coffee-script')
const espowerSource = require('espower-source')
const convert = require('convert-source-map')

// Lab transformer: on-the-fly coffee-script compilation + espower instrumentation
module.exports = [{
  ext: '.coffee',
  transform: (content, filename) => {
    if (filename.indexOf('node_modules') !== -1) return content
    const result = coffee.compile(content, {
      sourceMap: true,
      inlineMap: true,
      bare: true,
      header: false,
      sourceRoot: '/',
      sourceFiles: [filename]
    })
    var conv = convert.fromJSON(result.v3SourceMap)
    conv.setProperty('sources', [filename])
    if (content.indexOf('power-assert') === -1) {
      result.js = espowerSource(
        result.js,
        filename,
        { sourceMap: conv.toObject(), sourceRoot: process.cwd() }
      )
    }
    return `${result.js}\n${conv.toComment()}`
  }
}]
