gulp = require 'gulp'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
mocha = require 'gulp-mocha'
istanbul = require 'gulp-istanbul'

sources =
  js: 'lib/**/*.js'
  coffee: 'src/**/*.coffee'
  tests: 'test/**/*.unit.coffee'

gulp.task 'lint', ->
  return gulp.src sources.coffee
    .pipe coffeelint()
    .pipe coffeelint.reporter()

gulp.task 'compile', ->
  return gulp.src(sources.coffee)
    .pipe coffee()
    .pipe gulp.dest('lib/')

gulp.task 'test', ->
  return gulp.src sources.tests
    .pipe mocha()

gulp.task 'cover', ['compile'], ->
  return gulp.src sources.js
    .pipe istanbul()
    .pipe istanbul.hookRequire()
    .on 'finish', ->
      return gulp.src sources.tests
        .pipe mocha()
        .pipe istanbul.writeReports()

gulp.task 'build', ['lint', 'cover']

