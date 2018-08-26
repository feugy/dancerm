const coffee = require('coffeescript')
const originalCompileFile = coffee._compileFile
const minimatch = require('minimatch')
const convert = require('convert-source-map')
const espowerSource = require('espower-source')

function espowerCoffee (options) {
  const patternStartsWithSlash = (options.pattern.lastIndexOf('/', 0) === 0)
  const pattern = `${options.cwd}${patternStartsWithSlash ? '' : '/'}${options.pattern}`

  coffee._compileFile = function (filepath, opts = {}) {
    if (!minimatch(filepath, pattern)) {
      return originalCompileFile(filepath, opts)
    }
    var withMap = originalCompileFile(filepath, {...opts, sourceMap: true}) // enable sourcemaps
    var conv = convert.fromJSON(withMap.v3SourceMap)
    // restore filepath since coffeescript compiler drops it
    conv.setProperty('sources', [filepath])
    withMap.js = espowerSource(
        withMap.js,
        filepath,
        {...options.espowerOptions, sourceMap: conv.toObject(), sourceRoot: options.cwd }
    )
    return opts.sourceMap ? withMap : withMap.js
  }
  coffee.register()
}

espowerCoffee({
  cwd: process.cwd(),
  pattern: 'test/**/*.coffee'
})