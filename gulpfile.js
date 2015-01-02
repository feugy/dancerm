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
var _ = require('lodash');
var async = require('async');
var gulp = require('gulp');
var gutil = require('gulp-util');
var rimraf = require('rimraf');
var coffee = require('gulp-coffee');
var sourcemaps = require('gulp-sourcemaps');
var download = require('gulp-download');
var deps = require('./package.json').frontDependencies;


var paths = {
  assetsSrc: ['app/src/style/{css,img,fonts}/**/*'],
  assetsDest: 'app/style',
  mapsDest: '.',
  scriptsSrc: 'app/src/**/*.coffee',
  scriptsDest: 'app/script',
  testsSrc: 'test/src/**/*.coffee',
  testsDest: 'test/script'
};

gulp.task('default', ['watch']);

// remove compiled folder
gulp.task('clean', function(done){
  async.each([paths.scriptsDest, paths.testsDest], rimraf, done);
});

// download vendor libraries from the net
gulp.task('vendor', function(){
  var conf = [];
  for (var file in deps) {
    conf.push({file: file, url: deps[file]});
  }
  return download(conf)
    .pipe(gulp.dest('app/'));
});

// move assets to relevant destination
gulp.task('copy-assets', ['clean'], function() {
  return gulp.src(paths.assetsSrc)
    .pipe(gulp.dest(paths.assetsDest));
});

// Build Coffee scripts
function buildScripts() {
  return gulp.src(paths.scriptsSrc)
    .pipe(sourcemaps.init())
    .pipe(coffee({
      bare: true
    }).on('error', function(err) {
      gutil.log(err.stack);
      gutil.beep();
    }))
    .pipe(sourcemaps.write({sourceRoot: paths.mapsRoot}))
    .pipe(gulp.dest(paths.scriptsDest))
    .on('end', function() {
      console.log('scripts rebuilt')
    });
}
gulp.task('build-scripts', ['clean'], buildScripts);

// Build all once
gulp.task('build', ['copy-assets', 'build-scripts']);

// Build tests scripts
function buildTests() {
  return gulp.src(paths.testsSrc)
    .pipe(coffee({
      bare: true
    }).on('error', function(err) {
      gutil.log(err.stack);
      gutil.beep();
    }))
    .pipe(gulp.dest(paths.testsDest))
    .on('end', function() {
      console.log('test rebuilt')
    });
}
gulp.task('build-tests', ['build'], buildTests);

// Clean, build, and then watch for files changes
gulp.task('watch', ['build-tests'], function(){
  gulp.watch(paths.scriptsSrc, buildScripts);
  return gulp.watch(paths.testsSrc, buildTests);
});