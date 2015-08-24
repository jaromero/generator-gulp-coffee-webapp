// generated on <%= date %> using <%= name %> <%= version %>
import gulp from 'gulp';
import gulpLoadPlugins from 'gulp-load-plugins';
import browserSync from 'browser-sync';
import del from 'del';
import {stream as wiredep} from 'wiredep';

const $ = gulpLoadPlugins();
const reload = browserSync.reload;

gulp.task('styles', () => {<% if (includeSass) { %>
  return gulp.src('app/styles/*.scss')
    .pipe($.plumber())
    .pipe($.sourcemaps.init())
    .pipe($.sass.sync({
      outputStyle: 'expanded',
      precision: 10,
      includePaths: ['.']
    }).on('error', $.sass.logError))<% } else { %>
  return gulp.src('app/styles/*.css')
    .pipe($.sourcemaps.init())<% } %>
    .pipe($.autoprefixer({browsers: ['last 1 version']}))
    .pipe($.sourcemaps.write())
    .pipe(gulp.dest('.tmp/styles'))
    .pipe(reload({stream: true}));
});

gulp.task('scripts', () => {
  return gulp.src('app/scripts/**/*.{coffee,litcoffee}')
    .pipe($.coffee()).on('error', function(err) { console.log('Error!', err.message)})
    .pipe(gulp.dest('.tmp/scripts'));
});
<% if (includeJade) { %>
gulp.task('views', () => {
  return gulp.src('app/*.jade')
    .pipe($.jade({pretty: true}))
    .pipe(gulp.dest('.tmp'))
    .pipe(reload({stream: true}));
});<% } %>

function eslint(files, options) {
  return () => {
    return gulp.src(files)
      .pipe(reload({stream: true, once: true}))
      .pipe($.eslint(options))
      .pipe($.eslint.format())
      .pipe($.if(!browserSync.active, $.eslint.failAfterError()));
  };
}
function coffeelint(files, options) {
  return () => {
    return gulp.src(files)
      .pipe(reload({stream: true, once: true}))
      .pipe($.coffeelint(options))
      .pipe($.coffeelint.reporter(require('coffeelint-stylish')))
      .pipe($.if(!browserSync.active, $.coffeelint.reporter('fail')));
  };
}
const testLintOptions = {
  env: {
<% if (testFramework === 'mocha') { -%>
    mocha: true
<% } else if (testFramework === 'jasmine') { -%>
    jasmine: true
<% } -%>
  }
};

gulp.task('eslint', eslint('app/scripts/**/*.js'));
gulp.task('eslint:test', eslint('test/spec/**/*.js', testLintOptions));

gulp.task('coffeelint', coffeelint('app/scripts/**/*.coffee'));

gulp.task('html', ['styles', 'scripts'<% if (includeJade) { %>, 'views'<% } %>], () => {
  const assets = $.useref.assets({searchPath: ['.tmp', 'app', '.']});
  <% if (includeJade) { %>
  return gulp.src(['app/*.html', '.tmp/*.html'])<% } else { %>
  return gulp.src('app/*.html')<% } %>
    .pipe(assets)
    .pipe($.if('*.js', $.uglify()))
    .pipe($.if('*.css', $.minifyCss({compatibility: '*'})))
    .pipe(assets.restore())
    .pipe($.useref())
    .pipe($.if('*.html', $.minifyHtml({conditionals: true, loose: true})))
    .pipe(gulp.dest('dist'));
});

gulp.task('images', () => {
  return gulp.src('app/images/**/*')
    .pipe($.if($.if.isFile, $.cache($.imagemin({
      progressive: true,
      interlaced: true,
      // don't remove IDs from SVGs, they are often used
      // as hooks for embedding and styling
      svgoPlugins: [{cleanupIDs: false}]
    }))
    .on('error', function (err) {
      console.log(err);
      this.end();
    })))
    .pipe(gulp.dest('dist/images'));
});

gulp.task('fonts', () => {
  return gulp.src(require('main-bower-files')('**/*.{eot,svg,ttf,woff,woff2}', function (err) {})
    .concat('app/fonts/**/*'))
    .pipe(gulp.dest('.tmp/fonts'))
    .pipe(gulp.dest('dist/fonts'));
});

gulp.task('extras', () => {
  return gulp.src([
    'app/*.*',
    '!app/*.html'<% if (includeJade) { %>,
    '!app/*.jade'<% } %>
  ], {
    dot: true
  }).pipe(gulp.dest('dist'));
});

gulp.task('clean', del.bind(null, ['.tmp', 'dist']));

gulp.task('serve', ['styles', 'fonts', 'scripts'<% if (includeJade) { %>, 'views'<% } %>], () => {
  browserSync({
    notify: false,
    port: 9000,
    server: {
      baseDir: ['.tmp', 'app'],
      routes: {
        '/bower_components': 'bower_components'
      }
    }
  });

  gulp.watch([
    'app/*.html',<% if (includeJade) { %>
    '.tmp/*.html',<% } %>
    'app/scripts/**/*.js',
    '.tmp/scripts/**/*.js',
    'app/images/**/*',
    '.tmp/fonts/**/*'
  ]).on('change', reload);
  <% if (includeJade) { %>
  gulp.watch('app/**/*.jade', ['views']); <% } %>
  gulp.watch('app/styles/**/*.<%= includeSass ? 'scss' : 'css' %>', ['styles']);
  gulp.watch('app/scripts/**/*.{coffee,litcoffee}', ['scripts']);
  gulp.watch('app/fonts/**/*', ['fonts']);
  gulp.watch('bower.json', ['wiredep', 'fonts']);
});

gulp.task('serve:dist', () => {
  browserSync({
    notify: false,
    port: 9000,
    server: {
      baseDir: ['dist']
    }
  });
});

gulp.task('serve:test', () => {
  browserSync({
    notify: false,
    port: 9000,
    ui: false,
    server: {
      baseDir: 'test',
      routes: {
        '/bower_components': 'bower_components'
      }
    }
  });

  gulp.watch('test/spec/**/*.js').on('change', reload);
  gulp.watch('test/spec/**/*.js', ['lint:test']);
});

// inject bower components
gulp.task('wiredep', () => {<% if (includeSass) { %>
  gulp.src('app/styles/*.scss')
    .pipe(wiredep({
      ignorePath: /^(\.\.\/)+/
    }))
    .pipe(gulp.dest('app/styles'));
<% } if (includeJade) { %>
  gulp.src('app/layouts/*.jade')<% } else { %>
  gulp.src('app/*.html')<% } %>
    .pipe(wiredep({<% if (includeBootstrap) { if (includeSass) { %>
      exclude: ['bootstrap-sass'],<% } else { %>
      exclude: ['bootstrap.js'],<% }} %>
      ignorePath: /^(\.\.\/)*\.\./
    }))
    .pipe(gulp.dest('app'));
});

gulp.task('build', ['lint', 'html', 'images', 'fonts', 'extras'], () => {
  return gulp.src('dist/**/*').pipe($.size({title: 'build', gzip: true}));
});

gulp.task('default', ['clean'], () => {
  gulp.start('build');
});
