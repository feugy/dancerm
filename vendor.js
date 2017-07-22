const download = require('download')
const fs = require('fs')
const mkdirp = require('mkdirp')
const {dirname} = require('path')
const {frontDependencies} = require('./package.json')

// download frontend files
Promise.all(Object.keys(frontDependencies).map(file => {
  const url = frontDependencies[file]
  return download(url)
    .then(data => new Promise((resolve, reject) => {
      mkdirp(dirname(file), err => {
        if (err) return reject(new Error(`failed to create folder for ${file}: ${err}`))
        fs.writeFile(file, data, err => {
          if (err) return reject(new Error(`failed to write ${file}: ${err}`))
          resolve()
        })
      })
    }))
    .catch(err => {
      throw new Error(`Failed to download ${url}: ${err.message || err}`)
    })
}))
