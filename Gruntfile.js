'use strict';

module.exports = function(grunt) {

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    jshint: {
      files: ['Gruntfile.js', 'source/javascripts/**/*.js'],
      options: {
        node: true,
        curly: true,
        eqeqeq: true,
        indent: 2,
        quotmark: 'single',
        unused: true,
        trailing: true,
        smarttabs: true,
        eqnull: true,
        browser: true,
        globalstrict: false,
        globals: {
          jQuery: true,
          _: true,
          Modernizr: true,
        },
      }
    },
    scsslint: {
      allFiles: [
        'source/stylesheets/**/*.scss',
      ],
      options: {
        exclude: 'source/stylesheets/vendors/**/*',
        config: '.scss-lint.yml',
        bundleExec: true
      }
    },
    watch: {
      js: {
        files: '<%= jshint.files %>',
        tasks: 'jshint'
      },
      sass: {
        files: ['.scss-lint.yml', 'source/stylesheets/**/*.scss'],
        tasks: 'scsslint'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-scss-lint');

  grunt.registerTask('default', 'watch');
};
