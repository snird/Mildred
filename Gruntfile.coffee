module.exports = (grunt) ->

  # Utilities
  # =========
  path = require 'path'

  # Package
  # =======
  pkg = require './package.json'

  # Modules
  # =======
  # TODO: Remove this as soon as uRequire releases 0.3 which will able to
  #  do this for us in the right order magically.
  modules = [
    'src/lib/support.coffee'
    'src/lib/utils.coffee'
    'src/lib/helpers.coffee'
    'src/lib/history.coffee'
    'src/lib/route.coffee'
    'src/lib/router.coffee'
    'src/lib/composition.coffee'
    'src/lib/sync_machine.coffee'
    'src/controllers/controller.coffee'
    'src/models/model.coffee'
    'src/models/collection.coffee'
    'src/views/view.coffee'
    'src/views/layout.coffee'
    'src/views/collection_view.coffee'
    'src/dispatcher.coffee'
    'src/composer.coffee'
    'src/application.coffee'
  ]

  test_modules = [
    'test/spec/application_spec.coffee'
    'test/spec/model_spec.coffee'
    'test/spec/collection_spec.coffee'
    'test/spec/sync_machine_spec.coffee'
    'test/spec/view_spec.coffee'
    'test/spec/collection_view_spec.coffee'
    'test/spec/layout_spec.coffee'
    'test/spec/controller_spec.coffee'
    # 'test/spec/dispatcher_spec.coffee'- should rewrite the specs completely
    'test/spec/router_spec.coffee'
  ]

  # Configuration
  # =============
  grunt.initConfig

    # Package
    # -------
    pkg: pkg

    # Clean
    # -----
    clean:
      build: 'build'
      temp: 'temp'
      components: 'components'
      test: ['test/temp*', 'test/coverage']

    # Compilation
    # -----------
    coffee:
      compile:
        files: [
          expand: true
          dest: 'build/'
          cwd: 'temp'
          src: '*.coffee'
          ext: '.js'
        ]

      test:
        files: [
          expand: true
          dest: 'test/'
          cwd: 'test/temp'
          src: '**/*.coffee'
          ext: '.js'
        ]

      options:
        bare: false

    # Module concatenation
    # --------------------
    concat:
      universal:
        files: [
          dest: 'temp/<%= pkg.name %>.coffee'
          src: modules
        ]

        options:
          banner: '''
          window.Mildred = {}

          '''

      tests:
        files: [
          dest: 'test/temp/tests.coffee'
          src: test_modules
        ]

    # Lint
    # ----
    coffeelint:
      source: 'src/**/*.coffee'
      grunt: 'Gruntfile.coffee'

    # Instrumentation
    # ---------------
    instrument:
      files: [
        'test/temp/mildred/*.js'
      ]

      options:
        basePath: '.'

    storeCoverage:
      options:
        dir : '.'
        json : 'coverage.json'
        coverageVar : '__coverage__'

    makeReport:
      src: 'coverage.json'
      options:
        type: 'html'
        dir: 'test/coverage'

    # Browser dependencies
    # --------------------
    bower:
      install:
        options:
          targetDir: './test/bower_components'
          cleanup: true

    # Test runner
    # -----------
    mocha:
      index:
        src: ['test/index.html']
        # options:
        #   grep: 'autoAttach'
        #   mocha:
        #     grep: 'autoAttach'

    # Minify
    # ------
    uglify:
      options:
        mangle: false
      universal:
        files:
          'build/mildred.min.js': 'build/mildred.js'

    # Compression
    # -----------
    compress:
      files: [
        src: 'build/mildred.min.js'
        dest: 'build/mildred.min.js.gz'
      ]

    # Watching for changes
    # --------------------
    watch:
      coffee:
        files: ['src/*.coffee']
        tasks: [
          'coffee:compile'
          'copy:test'
          'mocha'
        ]

      test:
        files: ['test/spec/*.coffee'],
        tasks: [
          'coffee:test'
          'mocha'
        ]

  # Events
  # ======
  grunt.event.on 'mocha.coverage', (coverage) ->
    # This is needed so the coverage reporter will find the coverage variable.
    global.__coverage__ = coverage

  # Dependencies
  # ============
  for name of pkg.devDependencies when name.substring(0, 6) is 'grunt-'
    grunt.loadNpmTasks name

  # Tasks
  # =====

  # Prepare
  # -------
  grunt.registerTask 'prepare', [
    'clean'
    'bower'
    'clean:components'
  ]

  # Build
  # -----

  grunt.registerTask 'build', [
    'concat:universal'
    'coffee:compile'
    'uglify'
  ]

  # Lint
  # ----
  grunt.registerTask 'lint', 'coffeelint'

  # Test
  # ----
  grunt.registerTask 'test', [
    'concat:universal'
    'coffee:compile'
    'concat:tests'
    'coffee:test'
    'mocha'
  ]

  # Coverage
  # --------
  grunt.registerTask 'cover', [
    'coffee:compile'
    'copy:test'
    'coffee:test'
    'copy:beforeInstrument'
    'instrument'
    'mocha'
    'storeCoverage'
    'copy:afterInstrument'
    'makeReport'
  ]

  # Test Watcher
  # ------------
  grunt.registerTask 'test-watch', [
    'test'
    'watch'
  ]

  # Releasing
  # ---------

  grunt.registerTask 'release:git', 'Check context, commit and tag for release.', ->
    prompt = require 'prompt'
    prompt.start()
    prompt.message = prompt.delimiter = ''
    prompt.colors = false
    # Command/query wrapper, turns description object for `spawn` into runner
    command = (desc, message) ->
      (next) ->
        grunt.log.writeln message if message
        grunt.util.spawn desc, (err, result, code) -> next(err)
    query = (desc) ->
      (next) -> grunt.util.spawn desc, (err, result, code) -> next(err, result)
    # Help checking input from prompt. Returns a callback that calls the
    # original callback `next` only if the input was as expected
    checkInput = (expectation, next) ->
      (err, input) ->
        unless input and input.question is expectation
          grunt.fail.warn "Aborted: Expected #{expectation}, got #{input}"
        next()

    steps = []
    continuation = this.async()

    # Check for master branch
    steps.push query(cmd: 'git', args: ['rev-parse', '--abbrev-ref', 'HEAD'])
    steps.push (result, next) ->
      result = result.toString().trim()
      if result is 'master'
        next()
      else
        prompt.get([
            description: "Current branch is #{result}, not master. 'ok' to continue, Ctrl-C to quit."
            pattern: /^ok$/, required: true
          ],
          checkInput('ok', next)
        )
    # List dirty files, ask for confirmation
    steps.push query(cmd: 'git', args: ['status', '--porcelain'])
    steps.push (result, next) ->
      grunt.fail.warn "Nothing to commit." unless result.toString().length

      grunt.log.writeln "The following dirty files will be committed:"
      grunt.log.writeln result
      prompt.get([
          description: "Commit these files? 'ok' to continue, Ctrl-C to quit.",
          pattern: /^ok$/, required: true
        ],
        checkInput('ok', next)
      )

    # Commit
    steps.push command(cmd: 'git', args: ['commit', '-a', '-m', "Release #{pkg.version}"])

    # Tag
    steps.push command(cmd: 'git', args: ['tag', '-a', pkg.version, '-m', "Version #{pkg.version}"])

    grunt.util.async.waterfall steps, continuation

  grunt.registerTask 'release', [
    'check:versions',
    'release:git',
    'build',
  ]

  # Default
  # -------
  grunt.registerTask 'default', [
    'lint'
    'clean'
    'build'
    'test'
  ]
