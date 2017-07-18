/**
 * Equivalent to makefile, with gulp.
 * The only requirement is to have gulp globally installed `npm install -g gulp`,
 * and to have retrieved the npm dependencies with `npm install`
 *
 * Available tasks:
 *   clean - removed compiled folders
 *   build - compiles coffee-script, stylus, copy assets
 *   vendor - get vendor libraries from the net
 *   watch (default) - clean, build, and use watcher to recompile on the fly when sources or scripts file changes
 */
const _ = require('lodash')
const async = require('async')
const gulp = require('gulp')
const gutil = require('gulp-util')
const rimraf = require('rimraf')
const coffee = require('gulp-coffee')
const sourcemaps = require('gulp-sourcemaps')
const download = require('gulp-downloader')
const {frontDependencies} = require('./package.json')


const paths = {
  assetsSrc: ['app/src/style/{css,img,fonts}/**/*'],
  assetsDest: 'app/style',
  scriptsSrc: 'app/src/**/*.coffee',
  scriptsDest: 'app/script',
  testsSrc: 'test/src/**/*.coffee',
  testsDest: 'test/script',
  sourceMapRoot: '../../src'
}

const platforms = ['osx64']

gulp.task('default', ['watch'])

// remove compiled folder
gulp.task('clean', done =>
  async.each([paths.scriptsDest, paths.testsDest], rimraf, done)
)

// download vendor libraries from the net
gulp.task('vendor', () => {
  const conf = []
  for (const file in frontDependencies) {
    conf.push({fileName: file, request: {url: frontDependencies[file]}})
  }
  return download(conf, {verbose: true})
    .on('end', () => gutil.log('files downloaded'))
    .on('error', err => {
      gutil.log(err)
      gutil.beep()
    })
    .pipe(gulp.dest('app/'))
})

// move assets to relevant destination
gulp.task('copy-assets', ['clean'], () =>
  gulp.src(paths.assetsSrc)
    .pipe(gulp.dest(paths.assetsDest))
)

// Build Coffee scripts
const buildScripts = () =>
  gulp.src(paths.scriptsSrc)
    .pipe(sourcemaps.init())
    .pipe(coffee({
      bare: true
    }))
    .on('end', () => gutil.log('scripts rebuilt'))
    .on('error', err => {
      gutil.log(`${err.filename}: ${err.message}\n${JSON.stringify(err.location, null, 2)}`)
      gutil.beep()
    })
    .pipe(sourcemaps.write({sourceRoot: paths.sourceMapRoot}))
    .pipe(gulp.dest(paths.scriptsDest))

gulp.task('build-scripts', ['clean'], buildScripts)

// Build all once
gulp.task('build', ['copy-assets', 'build-scripts'])

// Build tests scripts
const buildTests = () =>
  gulp.src(paths.testsSrc)
    .pipe(sourcemaps.init())
    .pipe(coffee({
      bare: true
    }))
    .on('end', () => gutil.log('test rebuilt'))
    .on('error', function(err) {
      gutil.log(`${err.filename}: ${err.message}\n${JSON.stringify(err.location, null, 2)}`)
      gutil.beep()
    })
    .pipe(sourcemaps.write({sourceRoot: paths.sourceMapRoot}))
    .pipe(gulp.dest(paths.testsDest))

gulp.task('build-tests', ['build'], buildTests)

// Clean, build, and then watch for files changes
gulp.task('watch', ['build-tests'], () => {
  gulp.watch(paths.scriptsSrc, buildScripts)
  return gulp.watch(paths.testsSrc, buildTests)
})