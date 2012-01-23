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

  2. Forks to run your test files in parallel, without overhead.

  3. Avoids running unchanged tests inside changed test files.

------------------------------------------------------------------------------
Features
------------------------------------------------------------------------------

  * Executes test files in parallel, making full use of multi-core CPUs.

  * Tests *changes* in your Ruby application: avoids running (1) unchanged
    test files and (2) unchanged tests inside changed test files.

  * Supports MiniTest, Test::Unit, RSpec, and any testing framework that (1)
    reflects failures in the process' exit status and (2) is loaded by your
    application's `test/test_helper.rb` or `spec/spec_helper.rb` file.

  * Logs the output from your tests into separate files: one log per test.
    The path of a log file is simply the path of its test file plus ".log".

  * Configurable through a Ruby script in your current working directory.

  * Implemented in less than 400 lines (SLOC) of pure Ruby code! :-)

------------------------------------------------------------------------------
Architecture
------------------------------------------------------------------------------

Following UNIX philosophy, Tork is made of simple text-based programs: thus
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
Prerequisites
------------------------------------------------------------------------------

  * Ruby 1.8.7 or 1.9.2 or newer.

  * Operating system that supports POSIX signals and the `fork()` system call.

    To check if your system qualifies, launch `irb` and enter the following:

        Process.respond_to? :fork  # must be true
        Signal.list.key? 'TERM'    # must be true

------------------------------------------------------------------------------
Installation
------------------------------------------------------------------------------

As a Ruby gem:

    gem install tork

As a Git clone:

    git clone git://github.com/sunaku/tork
    cd tork
    rake install

------------------------------------------------------------------------------
Invocation
------------------------------------------------------------------------------

If installed as a Ruby gem:

    tork --help

If installed as a Git clone:

    bundle exec ruby -Ilib bin/tork --help

You can monitor your test processes in another terminal:

    watch 'ps xuw | sed -n "1p; /test[r]/p" | fgrep -v sed'

You can forcefully terminate Tork from another terminal:

    pkill -f tork

------------------------------------------------------------------------------
Configuration
------------------------------------------------------------------------------

Tork looks for a configuration file named `.tork.rb` in its current working
directory.  The configuration file is a normal Ruby script.  Inside it, you
can query and modify the `Tork::Config` object (OpenStruct) according to the
configuration options listed below.

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
a lambda function yielding a file globbing pattern describing a set of
test files that need to be run.  In other words, whenever the source files
(the hash key; left-hand side of the mapping) change, their associated test
files (the hash value; right-hand side of the mapping) are run.

For example, if test files had the same names as their source files followed
by an underscore and the file name in reverse like this:

  * `lib/hello.rb` => `test/hello_olleh.rb`
  * `app/world.rb` => `spec/world_ldrow.rb`

Then you would add the following to your configuration file:

    Tork::Config.test_file_globbers[%r<^(lib|app)/.+\.rb$>] = lambda do |path|
      name = File.basename(path, '.rb')
      "{test,spec}/**/#{name}_#{name.reverse}.rb"
    end

In addition, these lambda functions can return `nil` if they do not wish for a
particular source file to be tested.  For example, to ignore tests for all
source files except those within a `models/` directory, you would write:

    Tork::Config.test_file_globbers[%r<^(lib|app)/.+\.rb$>] = lambda do |path|
      if path.include? '/models/'
        "{test,spec}/**/#{File.basename(path)}"
      end
    end

### Tork::Config.test_name_extractor

Lambda function that is given a line of source code to determine whether it
can be considered as a test definition.  In which case, the function must
extract and return the name of the test being defined.

### Tork::Config.before_fork_hooks

Array of lambda functions that are executed inside `tork-master` before a
worker process is forked to run a test file.  These functions are given:

1. The sequence number of the worker process that will be forked shortly.

2. The path of the log file containing the live output of the worker process.

3. The path of the test file that will be run by the worker process.

4. An array of names of tests inside the test file that will be run.  If this
   array is empty, then all tests in the test file will be run.

For example, to see some real values:

    Tork::Config.before_fork_hooks << lambda do |worker_number, log_file, test_file, test_names|
      p :before_fork_hooks => {
        :worker_number => worker_number,
        :log_file      => log_file,
        :test_file     => test_file,
        :test_names    => test_names,
      }
    end

### Tork::Config.after_fork_hooks

Array of lambda functions that are executed inside a worker process forked
by `tork-master`.  These functions are given:

1. The sequence number of the worker process.

2. The path of the log file containing the live output of the worker process.

3. The path of the test file that will be run by the worker process.

4. An array of names of tests inside the test file that will be run.  If this
   array is empty, then all tests in the test file will be run.

For example, to see some real values, including the worker process' PID:

    Tork::Config.after_fork_hooks << lambda do |worker_number, log_file, test_file, test_names|
      p :after_fork_hooks => {
        :worker_pid    => $$,
        :worker_number => worker_number,
        :log_file      => log_file,
        :test_file     => test_file,
        :test_names    => test_names,
      }
    end

The first function in this array instructs Test::Unit and RSpec to only run
those tests that correspond to the given `test_names` values.  This
accelerates your test-driven development cycle and improves productivity!

------------------------------------------------------------------------------
Configuration helpers
------------------------------------------------------------------------------

The following libraries assist you with configuring Tork. To use them,
simply add the `require()` lines shown below to your configuration file
*or* pass their basenames to the tork(1) command, also as shown below.

### require 'tork/config/rails' # tork rails

Support for the [Ruby on Rails] web framework.

### require 'tork/config/parallel_tests' # tork parallel_tests

Support for the [parallel_tests] library.

------------------------------------------------------------------------------
Usage tips
------------------------------------------------------------------------------

### [factory_girl] factories

Don't load your factories in master process (as part of your test execution
overhead) because that would necessitate the reloading of said overhead
whenever you change an existing factory definition or create a new one.

Instead, use `at_exit()` to wait until (1) after the master process has forked
a worker process and (2) just before that worker process runs its test suite
(whose execution is started by your test framework's own `at_exit()` handler):

    require 'factory_girl'
    at_exit { FactoryGirl.find_definitions unless $! }

This way, worker processes will pick up changes in your factories "for free"
whenever they (re)run your test files.  Also, don't load your factories or do
anything else in your `at_exit()` handler if Ruby is exiting because of a
raised exception (denoted by the `$!` global variable in the snippet above).

------------------------------------------------------------------------------
Known issues
------------------------------------------------------------------------------

### Ruby on Rails

  * Ensure that your `config/environments/test.rb` file disables class caching
    as follows (**NOTE:** if you are using Rails 3, the `tork/config/rails`
    configuration helper can do this for you automatically):

        config.cache_classes = false

    Otherwise, Tork will appear to ignore source-code changes in your
    models, controllers, helpers, and other Ruby source files.

  * If SQLite3 raises one of the following errors, try using an [in-memory
    adapter for SQLite3][memory_test_fix] or use different database software
    (such as MySQL) for your test environment.

    * SQLite3::BusyException: database is locked

    * cannot start a transaction within a transaction

------------------------------------------------------------------------------
License
------------------------------------------------------------------------------

Released under the ISC license.  See the LICENSE file for details.

[factory_girl]: https://github.com/thoughtbot/factory_girl
[memory_test_fix]: https://github.com/mvz/memory_test_fix
[parallel_tests]: https://github.com/grosser/parallel_tests
[Ruby on Rails]: http://rubyonrails.org
