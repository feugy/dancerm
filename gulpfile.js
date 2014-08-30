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
var _ = require('underscore');
var async = require('async');
var gulp = require('gulp');
var gutil = require('gulp-util');
var rimraf = require('rimraf');
var stylus = require('gulp-stylus');
var coffee = require('gulp-coffee');
var plumber = require('gulp-plumber');
var sourcemaps = require('gulp-sourcemaps');
var download = require('gulp-download');

var paths = {
  assetsSrc: ['app/src/style/{css,img,fonts}/**/*'],
  assetsDest: 'app/style',
  mapsDest: '.',
  scriptsSrc: 'app/src/**/*.coffee',
  scriptsDest: 'app/script',
  stylesSrc: 'app/src/style/**/*.styl',
  stylesDest: 'app/style',
  testsSrc: 'test/src/**/*.coffee',
  testsDest: 'test/script',
  vendorSrc: [
    {file:'vendor/jquery.js', url:'http://code.jquery.com/jquery-2.1.1.min.js'}, 
    {file:'vendor/angular.js', url:'https://code.angularjs.org/1.3.0-rc.0/angular.min.js'},
    {file:'vendor/angular-animate.js', url:'https://code.angularjs.org/1.3.0-rc.0/angular-animate.min.js'},
    {file:'vendor/angular-sanitize.js', url:'https://code.angularjs.org/1.3.0-rc.0/angular-sanitize.min.js'},
    {file:'vendor/angular-ui-router.js', url:'https://raw.githubusercontent.com/angular-ui/ui-router/0.2.11/release/angular-ui-router.min.js'},
    // unrelease yet, build from trunk
    //{file:'vendor/ui-bootstrap-tpls.js', url:'http://angular-ui.github.io/bootstrap/ui-bootstrap-tpls-0.12.0.min.js'},
    {file:'src/style/css/bootstrap.css', url:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css'},
    {file:'src/style/fonts/glyphicons-halflings-regular.eot', url:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/fonts/glyphicons-halflings-regular.eot'},
    {file:'src/style/fonts/glyphicons-halflings-regular.woff', url:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/fonts/glyphicons-halflings-regular.woff'},
    {file:'src/style/fonts/glyphicons-halflings-regular.ttf', url:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/fonts/glyphicons-halflings-regular.ttf'},
    {file:'src/style/fonts/glyphicons-halflings-regular.svg', url:'http://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/fonts/glyphicons-halflings-regular.svg'}
  ]
};

gulp.task('default', ['watch']);

// remove compiled folder
gulp.task('clean', function(done){
  async.each([paths.stylesDest, paths.scriptsDest, paths.testsDest], rimraf, done);
});

// download vendor libraries from the net
gulp.task('vendor', function(){
  return download(paths.vendorSrc)
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
    .pipe(plumber({
      errorHandler: function(err) {
        gutil.log(err);
        gutil.beep();
      }
    }))
    .pipe(coffee({
      bare: true
    }))
    .pipe(sourcemaps.write({sourceRoot: paths.mapsRoot}))
    .pipe(gulp.dest(paths.scriptsDest))
    .on('end', function() {
      console.log('scripts rebuilt')
    });
}
gulp.task('build-scripts', ['clean'], buildScripts);

// Build Stylus scripts
function buildStyles() {
  return gulp.src(paths.stylesSrc)
    .pipe(sourcemaps.init())
    .pipe(plumber({
      errorHandler: function(err) {
        gutil.log(err);
        gutil.beep();
      }
    }))
    .pipe(stylus())
    .pipe(sourcemaps.write({}))
    .pipe(gulp.dest(paths.stylesDest))
    .on('end', function() {
      console.log('styles rebuilt')
    });
}
gulp.task('build-styles', ['copy-assets'], buildStyles);

// Build all once
gulp.task('build', ['build-styles', 'build-scripts']);

// Build tests scripts
function buildTests() {
  return gulp.src(paths.testsSrc)
    .pipe(plumber({
      errorHandler: function(err) {
        gutil.log(err);
        gutil.beep();
      }
    }))
    .pipe(coffee({
      bare: true
    }))
    .pipe(gulp.dest(paths.testsDest))
    .on('end', function() {
      console.log('test rebuilt')
    });
}
gulp.task('build-tests', ['build'], buildTests);

// Clean, build, and then watch for files changes
gulp.task('watch', ['build-tests'], function(){
  gulp.watch(paths.stylesSrc, buildStyles);
  gulp.watch(paths.scriptsSrc, buildScripts);
  return gulp.watch(paths.testsSrc, buildTests);
});