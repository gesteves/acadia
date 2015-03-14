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
    svgstore: {
      options: {
        prefix: 'svg-',
        svg: {
          style: 'display: none;'
        },
        cleanup: ['style', 'fill', 'stroke']
      },
      default: {
        files: {
          'source/partials/_icons.svg.erb': ['tmp/source/svg/*.svg']
        }
      }
    },
    svgmin: {
      options: {},
      dist: {
        files: [{
          expand: true,
          src: ['source/svg/*.svg'],
          dest: 'tmp'
        }]
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
      },
      svg: {
        files: ['source/svg/*.svg'],
        tasks: ['svgmin', 'svgstore']
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-scss-lint');
  grunt.loadNpmTasks('grunt-svgstore');
  grunt.loadNpmTasks('grunt-svgmin');

  grunt.registerTask('default', 'watch');
  grunt.registerTask('svg', ['svgmin', 'svgstore']);
};
