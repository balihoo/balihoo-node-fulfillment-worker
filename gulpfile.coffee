gulp = require 'gulp'
coffeelint = require 'gulp-coffeelint'

sources =
  coffee: 'src/**/*.coffee'

gulp.task 'lint', ->
  gulp.src sources.coffee
    .pipe coffeelint()
    .pipe coffeelint.reporter()
