var gulp = require('gulp');
var g = require('gulp-load-plugins')({
	pattern: ['gulp-*', 'gulp.*'],
	replaceString: /\bgulp[\-.]/
});
var runSequence = require('run-sequence'),
		browserSync = require('browser-sync');

gulp.task('styles', function () {
	gulp.src(['less/main.less'])
		.pipe(g.plumber({
			errorHandler: function (error) {
				console.log(error.message);
				this.emit('end');
			}
		}))
		// .pipe(g.recess())
		// .pipe(g.recess.reporter())
		.pipe(g.less())
		.pipe(g.autoprefixer('last 2 versions'))
		.pipe(g.rename({suffix: '.min'}))
		.pipe(g.cssnano())
		.pipe(gulp.dest('../../public/'))
		.pipe(browserSync.reload({stream:true}));
});
gulp.task('scripts', function() {
	gulp.src('js/main.js')
		.pipe(g.plumber({
			errorHandler: function (error) {
				console.log(error.message);
				this.emit('end');
			}
		}))
		.pipe(g.rename({suffix: '.min'}))
		.pipe(g.uglify())
		.pipe(gulp.dest('../../public/'))
		.pipe(browserSync.reload({stream:true}));
});

gulp.task('build', function () {
	runSequence(['styles', 'scripts']);
});

gulp.task('reload', function () {
	browserSync.reload();
});

gulp.task('serve', function () {
	browserSync({
		proxy: 'localhost:3000/doc',
		online: false
  });
});

gulp.task('watch', function () {
	gulp.watch('less/**/*.less', ['styles']);
	gulp.watch('js/**/*.js', ['scripts']);
	gulp.watch('../views/**/*', ['reload']);
});

gulp.task('default', ['build', 'serve', 'watch'], function () {
});