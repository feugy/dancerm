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
const download = require('gulp-download')
const NwBuilder = require('nw-builder')
const runSequence = require('run-sequence')
const manifest = require('./package.json')


const paths = {
  assetsSrc: ['app/src/style/{css,img,fonts}/**/*'],
  assetsDest: 'app/style',
  mapsDest: '.',
  scriptsSrc: 'app/src/**/*.coffee',
  scriptsDest: 'app/script',
  testsSrc: 'test/src/**/*.coffee',
  testsDest: 'test/script',
  templateDest: 'app/template',
  vendor: 'app/vendor'
}

const platforms = ['osx64']

gulp.task('default', ['watch'])

// remove compiled folder
gulp.task('clean', done =>
  async.each([paths.scriptsDest, paths.testsDest], rimraf, done)
)

// download vendor libraries from the net
gulp.task('vendor', () => {
  const deps = manifest.frontDependencies
  const conf = []
  for (const file in deps) {
    conf.push({file: file, url: deps[file]})
  }
  return download(conf)
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
    //.pipe(sourcemaps.init())
    .pipe(coffee({
      bare: true
    }).on('error', function(err) {
      gutil.log(err.stack)
      gutil.beep()
    }))
    //.pipe(sourcemaps.write({sourceRoot: paths.mapsRoot}))
    .pipe(gulp.dest(paths.scriptsDest))
    .on('end', () => gutil.log('scripts rebuilt'))

gulp.task('build-scripts', ['clean'], buildScripts)

// Build all once
gulp.task('build', ['copy-assets', 'build-scripts'])

// Build tests scripts
const buildTests = () =>
  gulp.src(paths.testsSrc)
    .pipe(coffee({
      bare: true
    }).on('error', function(err) {
      gutil.log(err.stack)
      gutil.beep()
    }))
    .pipe(gulp.dest(paths.testsDest))
    .on('end', () => gutil.log('test rebuilt'))

gulp.task('build-tests', ['build'], buildTests)

// Make distribution packages
gulp.task('dist', () =>
  runSequence('clean', 'vendor', 'build', done => {
    const options = {
      files: ['./package.json',
        './app/src/**/*.styl',
        './' + paths.scriptsDest + '/**',
        './' + paths.assetsDest + '/**',
        './' + paths.templateDest + '/**',
        './' + paths.vendor + '/**',
        './node_modules/**'],
      version: '0.15.4',
      platforms: platforms,
      macIcns: 'app/src/style/img/dancerm.icns',
      winIco: 'app/src/style/img/dancerm.ico',
      platformOverrides: {
        osx: {
          toolbar: true
        }
      }
    }
    for (const package in manifest.devDependencies) {
      if (package !== 'rimraf') {
        // rimraf is needed by fs-extra: don't remove it
        options.files.push('!./node_modules/' + package + '/**')
      }
    }

    const nw = new NwBuilder(options)
    nw.on('log', gutil.log.bind(gutil)).build(done)
  })
)

// Clean, build, and then watch for files changes
gulp.task('watch', ['build-tests'], () => {
  gulp.watch(paths.scriptsSrc, buildScripts)
  return gulp.watch(paths.testsSrc, buildTests)
})