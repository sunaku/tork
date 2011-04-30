test-loop - Continuous testing for Ruby with fork/eval
==============================================================================

test-loop is a fast continuous testing tool for Ruby that automatically
detects and tests changes in your application in an efficient manner:

  1. Absorbs the test execution overhead into the main Ruby process.

  2. Forks to run your test files without overhead and in parallel.

  3. Avoids running unchanged test blocks inside changed test files.

------------------------------------------------------------------------------
Features
------------------------------------------------------------------------------

  * Tests *changes* in your Ruby application: avoids running (1) unchanged
    test files and (2) unchanged test blocks inside changed test files.

  * Supports Test::Unit, RSpec, and any other testing framework that (1)
    reflects failures in the process' exit status and (2) is loaded by your
    application's `test/test_helper.rb` or `spec/spec_helper.rb` file.

  * Reabsorbs test execution overhead if the test or spec helper file changes.

  * Executes test files in parallel, making full use of multiple processors.

  * Logs the output from your tests into separate files: one log per test.
    The path to a log file is simply the path of its test file plus ".log".

  * Generally I/O bound, so you can keep it running without CPU slowdown.

  * Configurable through a `.test-loop` file in your working directory.

  * Implemented in less than 240 lines (SLOC) of pure Ruby code! :-)

------------------------------------------------------------------------------
Prerequisites
------------------------------------------------------------------------------

  * Ruby 1.8.7 or 1.9.2 or newer.

  * Operating system that supports POSIX signals and the `fork()` system call.

    To check if your system qualifies, launch `irb` and enter the following:

        Process.respond_to? :fork                    # must be true

        signals = %w[INT TSTP QUIT TERM CHLD].sort
        Signal.list.keys.sort & signals == signals   # must be true

------------------------------------------------------------------------------
Installation
------------------------------------------------------------------------------

As a Ruby gem:

    gem install test-loop

As a Git clone:

    gem install diff-lcs -v '>= 1.1.2'
    git clone git://github.com/sunaku/test-loop

------------------------------------------------------------------------------
Invocation
------------------------------------------------------------------------------

If installed as a Ruby gem:

    test-loop

If installed as a Git clone:

    env RUBYLIB=lib ruby bin/test-loop

You can monitor your test processes in another terminal:

    watch 'ps xfw | sed -n "1p; /test-loop/p" | fgrep -v sed'

If it stops responding, you can annihilate test-loop from another terminal:

    pkill -9 -f test-loop

------------------------------------------------------------------------------
Operation
------------------------------------------------------------------------------

  * Press Control-Z or send the SIGTSTP signal to forcibly run all
    tests, even if there are no changes in your Ruby application.

  * Press Control-\\ or send the SIGQUIT signal to forcibly reabsorb
    the test execution overhead, even if its sources have not changed.

  * Press Control-C or send the SIGINT signal to quit the test loop.

------------------------------------------------------------------------------
Configuration
------------------------------------------------------------------------------

test-loop looks for a configuration file named `.test-loop` in the current
working directory.  This configuration file is a normal Ruby script in which
you can query and modify the `Test::Loop` OpenStruct configuration as follows:

### Test::Loop.delay_per_iteration

Number of seconds to wait after each loop iteration.  The default value is 1.

### Test::Loop.overhead_file_globs

Array of file globbing patterns that describe a set of Ruby scripts that are
loaded into the main Ruby process as overhead.

### Test::Loop.reabsorb_file_globs

Array of file globbing patterns that describe a set of files which cause the
overhead to be reabsorbed whenever they change.

### Test::Loop.test_file_matchers

Hash that maps a file globbing pattern describing a set of source files to a
lambda function yielding a file globbing pattern describing a set of test
files that need to be run.  In other words, whenever the source files (the
hash key; left-hand side of the mapping) change, their associated test files
(the hash value; right-hand side of the mapping) are run.

For example, if test files had the same names as their source files followed
by an underscore and the file name in reverse like this:

  * `lib/hello.rb` => `test/hello_olleh.rb`
  * `app/world.rb` => `spec/world_ldrow.rb`

Then you would add the following to your configuration file:

    Test::Loop.test_file_matchers['{lib,app}/**/*.rb'] = lambda do |path|
      extn = File.extname(path)
      name = File.basename(path, extn)
      "{test,spec}/**/#{name}_#{name.reverse}#{extn}"
    end

In addition, these lambda functions can return `nil` if they do not wish for a
particular source file to be tested.  For example, to ignore tests for all
source files except those within a `models/` directory, you would write:

    Test::Loop.test_file_matchers['{lib,app}/**/*.rb'] = lambda do |path|
      if path.include? '/models/'
        "{test,spec}/**/#{File.basename(path)}"
      end
    end

For source files not satisfying the above constraint, this lambda function
will return `nil`, thereby excluding those source files from being tested.

### Test::Loop.test_name_parser

Lambda function that is passed a line of source code to determine whether that
line can be considered as a test definition, in which case it must return the
name of the test being defined.

### Test::Loop.before_each_test

Array of lambda functions that are executed inside the worker process before
loading the test file.

These functions are passed (1) the path to the test file, (2) the path to
the log file containing the live output of running the test file, and (3) an
array containing the names of tests (which were identified by
`Test::Loop.test_name_parser`) inside the test file that have changed since
the last run of the test file.

For example, to print a worker process' ID and what work it will perform:

    Test::Loop.before_each_test.push lambda {
      |test_file, log_file, test_names|

      p :worker_pid => $$,
        :test_file => test_file,
        :log_file => log_file,
        :test_names => test_names
    }

By default, the first function in this array instructs Test::Unit and RSpec to
only run certain test blocks inside the test file.  This accelerates your
test-driven development cycle and improves productivity!

### Test::Loop.after_each_test

Array of lambda functions that are executed inside the master process after a
test has finished running.

These functions are passed (1) the path to the test file, (2) the path to the
log file containing the output of running the test file, (3) a
`Process::Status` object describing the exit status of the worker process that
ran the test file, (4) the time when test execution began, and (5) how many
seconds it took for the overall test execution to complete.

For example, to delete log files for successful tests, add the following to
your configuration file:

    Test::Loop.after_each_test.push lambda {
      |test_file, log_file, run_status, started_at, elapsed_time|

      File.delete(log_file) if run_status.success?
    }

For example, to see on-screen-display notifications only about test failures,
add the following to your configuration file (**NOTE:** the `test/loop/notify`
preset does this for you):

    Test::Loop.after_each_test.push lambda {
      |test_file, log_file, run_status, started_at, elapsed_time|

      unless run_status.success? or run_status.signaled?
        title = 'FAIL at %s in %0.1fs' % [started_at.strftime('%r'), elapsed_time]

        message = test_file

        Thread.new do # run in background
          system 'notify-send', '-i', 'dialog-error', title, message or
          system 'growlnotify', '-a', 'Xcode', '-m', message, title or
          system 'xmessage', '-timeout', '5', '-title', title, message
        end
      end
    }

For example, to see on-screen-display notifications about completed test runs,
regardless of whether they passed or failed, add the following to your
configuration file:

    Test::Loop.after_each_test.push lambda {
      |test_file, log_file, run_status, started_at, elapsed_time|

      success = run_status.success?

      title = '%s at %s in %0.1fs' %
        [success ? 'PASS' : 'FAIL', started_at.strftime('%X'), elapsed_time]

      message = test_file

      Thread.new do # run in background
        system 'notify-send', '-i', "dialog-#{success ? 'information' : 'error'}", title, message or
        system 'growlnotify', '-a', 'Xcode', '-m', message, title or
        system 'xmessage', '-timeout', '5', '-title', title, message
      end
    }

------------------------------------------------------------------------------
Configuration presets
------------------------------------------------------------------------------

The following sub-libraries provide "preset" configurations.  To use them,
simply add the require() lines shown below to your `.test-loop` file or to
your application's `test/test_helper.rb` or `spec/spec_helper.rb` file.

### require 'test/loop/notify'

Shows on-screen-display notifications for test failures.

### require 'test/loop/rails'

Provides support for the Ruby on Rails web framework.

------------------------------------------------------------------------------
Known issues
------------------------------------------------------------------------------

### Ruby on Rails

  * Ensure that your `config/environments/test.rb` file disables class caching
    as follows (**NOTE:** if you are using Rails 3, the `test/loop/rails`
    preset will automatically do this for you):

        config.cache_classes = false

    Otherwise, test-loop will appear to ignore source-code changes in your
    models, controllers, helpers, and other Ruby source files.

  * SQLite3 [raises `SQLite3::BusyException: database is locked` errors](
    https://github.com/sunaku/test-loop/issues/2 ) because test-loop runs your
    test files in parallel.  You can work around this by using an [in-memory
    adapter for SQLite3]( https://github.com/mvz/memory_test_fix ) or by using
    different database software (such as MySQL) for your test environment.

------------------------------------------------------------------------------
License
------------------------------------------------------------------------------

Released under the ISC license.  See the LICENSE file for details.
