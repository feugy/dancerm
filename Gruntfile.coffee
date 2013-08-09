module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    # Coffee-script compilation
    coffee: 
      options:
        bare: true
        sourceMap: true

      glob_to_multiple:
        expand: true
        cwd: 'app/src'
        src: ['**/*.coffee']
        dest: 'app/script'
        ext: '.js'

    # bower dependencies
    bowerful:
      dist:
        store: 'app/vendor'
        packages: 
          angular: 'PatternConsulting/bower-angular#1.1.5'
          'angular-bootstrap': '0.5.0'
          jquery: '2.0.3'
          requirejs: '2.1.8'
          underscore: '1.4.4'
          'underscore.string': '2.3.2'

    # Chrome package app generation (To be done with valid key)
    ###crx:
      DanceRM: 
        src: 'app/'
        dest: 'dist/DancerRM'
        privateKey: 'chrome-key.pem'###

  # Load different plugins
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-bowerful'
  #grunt.loadNpmTasks 'grunt-crx'

  # Default task(s).
  grunt.registerTask 'default', ['coffee']
