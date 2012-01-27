    _______      _______
     ___  /___________ /__
      _  __/ __ \  __/ /_/
      / /_/ /_/ / / / ,\
      \__/\____/_/ /_/|_\
                 >>>------>

_Test with fork_
==============================================================================

Tork is a continuous testing tool for Ruby that automatically detects and
tests changes in your Ruby application or test suite in an efficient manner:

  1. Absorbs your test execution overhead into a master process.

  2. Forks to run your test files in parallel; overhead inherited.

  3. Avoids running unchanged tests inside changed test files.

------------------------------------------------------------------------------
Features
------------------------------------------------------------------------------

  * No configuration needed: run `tork` for Ruby, `tork rails` for Rails.

  * Runs test files in parallel using fork for multi-core/CPU utilization.

  * Tests *changes* your Ruby application for rapid TDD: avoids running (1)
    unchanged test files and (2) unchanged tests inside changed test files.

  * Supports MiniTest, Test::Unit, RSpec, and *any testing framework* that (1)
    exits with a nonzero status to indicate test failures (2) is loaded by
    your application's `test/test_helper.rb` or `spec/spec_helper.rb` file.

  * Logs the output from your tests into separate files: one log per test.
    The path of a log file is simply the path of its test file plus ".log".

  * Configurable through a Ruby script in your current working directory.

  * You can override the modular `tork*` programs with your own in $PATH.

  * Its core is written in less than 360 lines (SLOC) of pure Ruby code! :-)

### Architecture

Following UNIX philosophy, Tork is composed of simple text-based programs: so
you can build your own custom Tork user interface by wrapping `tork-driver`!

  * `tork` is an interactive command-line user interface (CLI) for driver
  * `tork-herald` monitors current directory tree and reports changed files
  * `tork-driver` tells master to run tests and keeps track of test results
  * `tork-master` absorbs test execution overhead and forks to run your tests

When the herald observes that files in or beneath the current directory have
been written to, it tells the driver, which then commands the master to fork a
worker process to run the tests affected by those changed files.  This is all
performed automatically.  But what if you want to manually run a test file?

You can (re)run any test file by simply saving it!  When you do, Tork tries to
figure out which tests inside your newly saved test file have changed (using
diff and regexps) and then attempts to run just those.  To make it run *all*
tests in your saved file, simply save the file *again* without changing it.

------------------------------------------------------------------------------
Installation
------------------------------------------------------------------------------

    gem install tork

### Prerequisites

  * Ruby 1.8.7 or 1.9.2 or newer.

  * Operating system that supports POSIX signals and the `fork()` system call.
    To check if your system qualifies, launch `irb` and enter the following:

        Process.respond_to? :fork  # must be true
        Signal.list.key? 'CHLD'    # must be true
        Signal.list.key? 'TERM'    # must be true

  * To make the `tork-herald` program's filesystem monitoring more efficient:

        gem install rb-inotify  # linux
        gem install rb-fsevent  # macosx

### Development

    git clone git://github.com/sunaku/tork
    cd tork
    bundle install --binstubs=bundle_bin
    bundle_bin/tork --help  # run it directly
    bundle exec rake -T     # packaging tasks

------------------------------------------------------------------------------
Usage
------------------------------------------------------------------------------

### At the command line

    tork --help

You can monitor your test processes from another terminal:

    watch 'ps xuw | sed -n "1p; /tor[k]/p" | fgrep -v sed'

### With [Ruby on Rails]

For Rails 3 or newer, use the rails configuration helper (see below).
Otherwise, ensure that your `config/environments/test.rb` file contains:

    config.cache_classes = false

To use SQLite3 as your test database, install its [in-memory database
adapter][memory_test_fix].  Otherwise, you *might* face these errors:

> SQLite3::BusyException: database is locked

> cannot start a transaction within a transaction

### With [factory_girl]

Do not load your factories into the master process as part of your test
execution overhead in your test/spec helper because that would necessitate
overhead reabsorption whenever you change or create factory definitions.

Instead, use `at_exit()` to wait until (1) after the master process has forked
a worker process and (2) just before that worker process runs its test suite
(whose execution is started by your test framework's own `at_exit()` handler):

    # in your test/spec helper
    require 'factory_girl'
    at_exit { FactoryGirl.find_definitions unless $! }

This way, worker processes will pick up changes in your factories "for free"
whenever they (re)run your test files.  Skip if Ruby is exiting because of a
raised exception (denoted by the `$!` global variable in the snippet above).

As a bonus, this arrangement also works when tests are run outside of Tork!

------------------------------------------------------------------------------
Configuration
------------------------------------------------------------------------------

Tork looks for a configuration file named `.tork.rb` in its current working
directory.  The configuration file is a normal Ruby script, inside which you
can query and modify the `Tork::Config` object: an instance of OpenStruct.

------------------------------------------------------------------------------
Configuration helpers
------------------------------------------------------------------------------

### [Ruby on Rails]

At the command line:

    tork rails

Or in your configuration file:

    require 'tork/config/rails'

### [Cucumber]

At the command line:

    tork cucumber

Or in your configuration file:

    require 'tork/config/cucumber'

### [parallel_tests]

At the command line:

    tork parallel_tests

Or in your configuration file:

    require 'tork/config/parallel_tests'

### Hide log files by prefixing their names with a dot

At the command line:

    tork dotlog

Or in your configuration file:

    require 'tork/config/dotlog'

### Isolate log files into a separate `log/` directory

At the command line:

    tork logdir

Or in your configuration file:

    require 'tork/config/logdir'

------------------------------------------------------------------------------
Configuration options
-----------------------------------------------------------------------------

### Tork::Config.max_forked_workers

Maximum number of worker processes at any given time.  The default value is
the number of processors detected on your system, or 1 if detection fails.

### Tork::Config.overhead_load_paths

Array of paths that are prepended to Ruby's `$LOAD_PATH` before the
test execution overhead is loaded into `tork-master`.

### Tork::Config.overhead_file_globs

Array of file globbing patterns that describe a set of Ruby scripts that are
loaded into `tork-master` as test execution overhead.

### Tork::Config.reabsorb_file_greps

Array of regular expressions that describe a set of file paths that cause the
test execution overhead to be reabsorbed in `tork-master` when they change.

### Tork::Config.all_test_file_globs

Array of file globbing patterns that describe the set of all test files in
your Ruby application.

### Tork::Config.test_file_globbers

Hash that maps (1) a regular expression describing a set of file paths to (2)
a lambda function that accepts the path to a changed file and a `MatchData`
object containing the results of the regular expression matching, and yields a
file globbing pattern that describes a set of test files that need to be run.

In other words, whenever the source files (the regular expression) change,
their associated test files (result of calling the lambda function) are run.

For example, if test files had the same names as their source files followed
by an underscore and the file name in reverse like this:

  * `lib/hello.rb` => `test/hello_olleh.rb`
  * `app/world.rb` => `spec/world_ldrow.rb`

Then you would add the following to your configuration file:

    Tork::Config.test_file_globbers[%r<^(lib|app)/.+\.rb$>] = lambda do |path, matches|
      name = File.basename(path, '.rb')
      "{test,spec}/**/#{name}_#{name.reverse}.rb"
    end

In addition, these lambda functions can return `nil` if they do not wish for a
particular source file to be tested.  For example, to ignore tests for all
source files except those within a `models/` directory, you would write:

    Tork::Config.test_file_globbers[%r<^(lib|app)/.+\.rb$>] = lambda do |path, matches|
      if path.include? '/models/'
        "{test,spec}/**/#{File.basename(path)}"
      end
    end

### Tork::Config.before_fork_hooks

Array of lambda functions that are executed inside `tork-master` before a
worker process is forked to run a test file.  These functions are given:

1. The sequence number of the worker process that will be forked shortly.

2. The path of the log file containing the live output of the worker process.

3. The path of the test file that will be run by the worker process.

4. An array of line numbers in the test file to run.  If this array is empty,
   then the entire test file will be run.

For example, to see some real values:

    Tork::Config.before_fork_hooks.push lambda {
      |test_file, line_numbers, log_file, worker_number|

      p :before_fork_hooks => {
        :test_file     => test_file,
        :line_numbers  => line_numbers,
        :log_file      => log_file,
        :worker_number => worker_number,
      }
    }

### Tork::Config.after_fork_hooks

Array of lambda functions that are executed inside a worker process forked
by `tork-master`.  These functions are given:

1. The sequence number of the worker process.

2. The path of the log file containing the live output of the worker process.

3. The path of the test file that will be run by the worker process.

4. An array of line numbers in the test file to run.  If this array is empty,
   then the entire test file will be run.

For example, to see some real values, including the worker process' PID:

    Tork::Config.after_fork_hooks.push lambda {
      |test_file, line_numbers, log_file, worker_number|

      p :after_fork_hooks => {
        :test_file     => test_file,
        :line_numbers  => line_numbers,
        :log_file      => log_file,
        :worker_number => worker_number,
        :worker_pid    => $$,
      }
    }

The first function in this array instructs Test::Unit and RSpec to only run
those tests that are defined on the given line numbers.  This accelerates your
test-driven development cycle by only running tests you are currently editing.

------------------------------------------------------------------------------
License
------------------------------------------------------------------------------

Released under the ISC license.  See the LICENSE file for details.

[factory_girl]: https://github.com/thoughtbot/factory_girl
[memory_test_fix]: https://github.com/mvz/memory_test_fix
[parallel_tests]: https://github.com/grosser/parallel_tests
[Ruby on Rails]: http://rubyonrails.org
[Cucumber]: https://cukes.info
