# generated on <%= date %> using <%= name %> <%= version %>
gulp        = require 'gulp'
$           = require('gulp-load-plugins')()
browserSync = require 'browser-sync'
del         = require 'del'
wiredep     = require('wiredep').stream
assign      = require('lodash').assign

reload = browserSync.reload


gulp.task 'styles', ->
  gulp.src 'app/styles/*.scss'
    .pipe $.plumber()
    .pipe $.sourcemaps.init()
    .pipe $.sass.sync
      outputStyle: 'expanded'
      precision: 10
      includePaths: ['.']
    .on 'error', $.sass.logError
    .pipe $.autoprefixer {browsers: ['> 1%', 'last 2 versions', 'Firefox ESR']}
    .pipe $.sourcemaps.write()
    .pipe gulp.dest '.tmp/styles'
    .pipe reload {stream: true}

gulp.task 'scripts', ->
  gulp.src 'app/scripts/**/*.{coffee,litcoffee}'
    .pipe $.coffee()
    .on 'error', (err) ->
      console.log 'Error!', err.message
    .pipe gulp.dest '.tmp/scripts'
<% if (includeJade) { %>
gulp.task 'views', ->
  gulp.src 'app/*.jade'
    .pipe $.plumber()
    .pipe $.jade {pretty: true}
    .on 'error', (err) ->
      console.log 'Error!', err.message
    .pipe gulp.dest '.tmp'
    .pipe reload {stream: true}<% } %>

eslint = (files, opts) ->
  ->
    gulp.src files
      .pipe reload {stream: true, once: true}
      .pipe $.eslint assign {}, opts,
        configFile: 'eslint.json'
      .pipe $.eslint.format()
      .pipe $.if (not browserSync.active), $.eslint.failAfterError()

coffeelint = (files, opts) ->
  ->
    gulp.src files
      .pipe reload {stream: true, once: true}
      .pipe $.coffeelint opts
      .pipe $.coffeelint.reporter require 'coffeelint-stylish'
      .pipe $.if (not browserSync.active), $.coffeelint.reporter 'fail'

scsslint = (files, opts) ->
  ->
    gulp.src files
      .pipe reload {stream: true, once: true}
      .pipe $.scssLint assign {}, opts,
        config: '.scss-lint.yml'
        reporterOutputFormat: 'Checkstyle'
      .pipe $.if (not browserSync.active), $.scssLint.failReporter 'E'

testLintOptions =
  env:
    <% if (testFramework === 'mocha') { %>mocha: true<% } %>
    <% if (testFramework === 'jasmine') { %>jasmine: true<% } %>

gulp.task 'eslint', eslint 'app/scrips/**/*.js'
gulp.task 'eslint:test', eslint 'test/spec/**/*.js', testLintOptions

gulp.task 'coffeelint', coffeelint 'app/scripts/**/*.coffee'

gulp.task 'scsslint', scsslint 'app/styles/**/*.scss'

gulp.task 'lint', ['eslint', 'coffeelint', 'scsslint']

gulp.task 'html', ['styles', 'scripts'<% if (includeJade) { %>, 'views'<% } %>], ->
  <% if (includeJade) { %>
  return gulp.src ['app/*.html', '.tmp/*.html']<% } else { %>
  return gulp.src 'app/*.html'<% } %>
    .pipe $.useref {searchPath: ['.tmp', 'app', '.']}
    .pipe $.if '*.js', $.uglify()
    .pipe $.if '*.css', $.cssnano()
    .pipe $.if '*.html', $.htmlmin()
    .pipe gulp.dest 'dist'

gulp.task 'images', ->
  gulp.src 'app/images/**/*'
    .pipe $.if $.if.isFile, $.cache $.imagemin
      progressive: true
      interlaced: true
      # don't remove IDs from SVGs, they are often used
      # as hooks for embedding and styling
      svgoPlugins: [{cleanupIDs: false}]
    .on 'error', (err) ->
      console.log err
      this.end()
    .pipe gulp.dest 'dist/images'

gulp.task 'fonts', ->
  bowerFiles = require 'main-bower-files'

  gulp.src bowerFiles('**/*.{eot,svg,ttf,woff,woff2}', (err) -> undefined).concat 'app/fonts/**/*'
    .pipe gulp.dest '.tmp/fonts'
    .pipe gulp.dest 'dist/fonts'

gulp.task 'extras', ->
  gulp.src [
    'app/*.*'
    '!app/*.html'<% if (includeJade) { %>
    '!app/*.jade'<% } %>
  ],
    dot: true
  .pipe gulp.dest 'dist'

gulp.task 'clean', del.bind null, ['.tmp', 'dist']

gulp.task 'browser', ['styles', 'fonts', 'scripts'<% if (includeJade) { %>, 'views'<% } %>], ->
  browserSync
    notify: false
    port: 9000
    server:
      baseDir: ['.tmp', 'app']
      routes:
        '/bower_components': 'bower_components'

gulp.task 'browser:e2e', ['styles', 'fonts', 'scripts'<% if (includeJade) { %>, 'views'<% } %>], ->
  browserSync
    notify: false
    port: 9000
    ui: false
    open: false
    server:
      baseDir: ['.tmp', 'app']
      routes:
        '/bower_components': 'bower_components'

gulp.task 'serve', ['browser'], ->
  gulp.watch [
    'app/*.html'<% if (includeJade) { %>
    '.tmp/*.html'<% } %>
    'app/scripts/**/*.js'
    '.tmp/scripts/**/*.js'
    'app/images/**/*'
    '.tmp/fonts/**/*'
  ]
  .on 'change', reload
  <% if (includeJade) { %>
  gulp.watch 'app/**/*.jade', ['views']<% } %>
  gulp.watch 'app/styles/**/*.scss', ['styles']
  gulp.watch 'app/scripts/**/*.{coffee,litcoffee}', ['scripts']
  gulp.watch 'app/fonts/**/*', ['fonts']
  gulp.watch 'bower.json', ['wiredep', 'fonts']

gulp.task 'serve:e2e', ['browser:e2e']

gulp.task 'serve:dist', ->
  browserSync
    notify: false
    port: 9000
    server:
      baseDir: ['dist']

gulp.task 'serve:test', ->
  browserSync
    notify: false
    port: 9000
    ui: false
    server:
      baseDir: 'test'
      routes:
        '/bower_components': 'bower_components'

  gulp.watch('test/spec/**/*.js').on 'change', reload
  gulp.watch 'test/spec/**/*.js', ['eslint:test']

webdriverOpts =
  desiredCapabilities:
    browserName: 'firefox'
  seleniumOptions:
    version: '2.47.1'
  seleniumInstallOptions:
    version: '2.47.1'
    baseURL: 'http://selenium-release.storage.googleapis.com'

gulp.task 'e2e', ['serve:e2e'], ->
  gulp.src 'e2e/**/*.js', {read: false}
    .pipe $.webdriver webdriverOpts
    .once 'end', ->
      browserSync.exit()

gulp.task 'e2e:chrome', ['serve:e2e'], ->
  gulp.src 'e2e/**/*.js', {read: false}
    .pipe $.webdriver assign {}, webdriverOpts,
      desiredCapabilities:
        browserName: 'chrome'
      seleniumInstallOptions:
        drivers:
          chrome:
            version: '2.18'
            arch: process.arch
            baseURL: 'http://chromedriver.storage.googleapis.com'
    .once 'end', ->
      browserSync.exit()

# inject bower components
gulp.task 'wiredep', ->
  gulp.src 'app/styles/*.scss'
    .pipe wiredep
      ignorePath: /^(\.\.\/)+/
    .pipe gulp.dest 'app/styles'
<% if (includeJade) { %>
  gulp.src 'app/layouts/*.jade'<% } else { %>
  gulp.src 'app/*.html'<% } %>
    .pipe wiredep<% if (includeBootstrap) { %>
      exclude: ['bootstrap-sass']<% } %>
      ignorePath: /^(\.\.\/)*\.\./<% if (includeJade) { %>
    .pipe gulp.dest 'app/layouts'<% } else { %>
    .pipe gulp.dest 'app'<% } %>

gulp.task 'build', ['lint', 'html', 'images', 'fonts', 'extras'], ->
  gulp.src 'dist/**/*'
    .pipe $.size {title: 'build', gzip: true}

gulp.task 'default', ['clean'], ->
  gulp.start 'build'
