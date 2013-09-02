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
        options:
          sourceMap: true

        expand: true
        cwd: 'test/src'
        src: ['**/*.coffee']
        dest: 'test/script'
        ext: '.js'

    # compile stylus stylesheet
    stylus:
      compile:
        expand: true
        cwd: 'app/src/style'
        src: ['**/*.styl']
        dest: 'app/style'
        ext: '.css'
        
    # bower dependencies for application
    bowerful:
      app:
        store: 'app/vendor'
        packages: 
          'angular': 'PatternConsulting/bower-angular#1.1.5'
          'angular-bootstrap': '0.5.0'
          'angular-ui-router': '0.0.2'
          'jquery': '2.0.3'

    # copy images file from stylus folder to style
    copy:
      stylus:
        files: [{
          expand: true 
          cwd: 'app/src/style', 
          src: ['img/**/*', 'font/**/*', 'css/**/*']
          dest: 'app/style'
        }]

    # compile when a coffee/stylus file has changed
    watch:
      app:
        files: 'app/src/**/*.coffee'
        tasks: 'coffee:app'
      test:
        files: 'test/src/**/*.coffee'
        tasks: 'coffee:test'
      style:
        files: 'app/src/style/**/*.styl'
        tasks: ['stylus', 'copy:stylus']

  # Load different plugins
  grunt.loadNpmTasks 'grunt-bowerful'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  # Default task(s).
  grunt.registerTask 'default', ['watch']
