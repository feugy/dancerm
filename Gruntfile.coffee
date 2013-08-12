module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    coffee: 
      options:
        bare: true

      # coffee-script compilation for application
      app:
        options:
          sourceMap: true

        expand: true
        cwd: 'app/src'
        src: ['**/*.coffee']
        dest: 'app/script'
        ext: '.js'

      # coffee-script compilation for tests
      test:
        expand: true
        cwd: 'test/src'
        src: ['**/*.coffee']
        dest: 'test/script'
        ext: '.js'

    # compile stylus stylesheet
    stylus:
      compile:
        expand: true
        cwd: 'app/style'
        src: ['**/*.styl']
        dest: 'app/style'
        ext: '.css'
        
    bowerful:
      # bower dependencies for application
      app:
        store: 'app/vendor'
        packages: 
          'angular': 'PatternConsulting/bower-angular#1.1.5'
          'angular-bootstrap': '0.5.0'
          'jquery': '2.0.3'
          'moment': '2.1.0'
          'requirejs': '2.1.8'
          'requirejs-i18n': '2.0.3'
          'underscore': '1.5.1'
          'underscore.string': '2.3.2'

      # bower dependenvies for tests
      test:
        store: 'test/vendor'
        packages: 
          'chai': '1.7.2'
          'jquery': '2.0.3'
          'mocha': '1.12.0'
          'moment': '2.1.0'
          'requirejs': '2.1.8'
          'underscore': '1.5.1'
          'underscore.string': '2.3.2'

    # copy app file into test script to allow testing
    copy:
      app:
        files: [{
          expand: true 
          cwd: 'app/script', 
          src: ['**/*.js']
          dest: 'test/script/'
        }]

    # compile when a coffee/stylus file has changed
    watch:
      app:
        files: 'app/src/**/*.coffee'
        tasks: ['coffee', 'copy:app']
      test:
        files: 'test/src/**/*.coffee'
        tasks: 'coffee'
      style:
        files: 'app/style/**/*.styl'
        tasks: 'stylus'

    # Chrome package app generation (To be done with valid key)
    ###crx:
      DanceRM: 
        src: 'app/'
        dest: 'dist/DancerRM'
        privateKey: 'chrome-key.pem'###

  # Load different plugins
  grunt.loadNpmTasks 'grunt-bowerful'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  #grunt.loadNpmTasks 'grunt-crx'

  # Default task(s).
  grunt.registerTask 'default', ['watch']
