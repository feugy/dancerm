const rimraf = require('rimraf')

process.argv.slice(2).forEach(file =>
  rimraf(file, err => {
    if (err && err.code !== 'EBUSY') throw err
  })
)
