'use strict';

var cheerio     = require('gulp-cheerio');
var gulp        = require('gulp');
var jshint      = require('gulp-jshint');
var jsstylish   = require('jshint-stylish');
var rename      = require('gulp-rename');
var rename      = require('gulp-rename');
var scsslint    = require('gulp-scss-lint');
var scssstylish = require('gulp-scss-lint-stylish');
var svgmin      = require('gulp-svgmin');
var svgstore    = require('gulp-svgstore');

var paths = {
  js: ['Gulpfile.js', 'source/javascripts/**/*.js', '!source/javascripts/vendors/*.js'],
  svg: ['source/svg/*.svg'],
  sass: ['source/stylesheets/**/*.scss', '!source/stylesheets/vendors/*.scss']
};

// Lint JS
gulp.task('js', function () {
  return gulp.src(paths.js)
    .pipe(jshint())
    .pipe(jshint.reporter(jsstylish));
});

// Lint Sass
gulp.task('sass', function() {
  gulp.src(paths.sass)
    .pipe(scsslint({
      config: '.scss-lint.yml',
      bundleExec: true,
      customReport: scssstylish
    }));
});

// Minify and concatenate SVGs
// and save as a Rails partial
gulp.task('svg', function () {
  return gulp.src(paths.svg)
    .pipe(rename({
      prefix: 'svg-'
    }))
    .pipe(svgmin())
    .pipe(cheerio({
      run: function ($) {
        $('[style]').removeAttr('style');
        $('[fill]').removeAttr('fill');
        $('[stroke]').removeAttr('stroke');
      },
      parserOptions: { xmlMode: true }
    }))
    .pipe(svgstore({ inlineSvg: true }))
    .pipe(cheerio({
      run: function ($) {
        $('svg').attr({
          'style': 'display:none'
        });
        $('svg').removeAttr('xmlns');
      },
      parserOptions: { xmlMode: true }
    }))
    .pipe(rename('_icons.svg.erb'))
    .pipe(gulp.dest('source/partials'));
});

gulp.task('watch', function () {
  gulp.watch(paths.js, ['js']);
  gulp.watch(paths.svg, ['svg']);
  gulp.watch(paths.sass, ['sass']);
});

gulp.task('default', ['watch']);
