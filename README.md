TestR - Continuous testing tool for Ruby
==============================================================================

TestR is a continuous testing tool for Ruby that automatically detects and
tests changes in your Ruby application or test suite in an efficient manner:

  1. Absorbs test execution overhead into the master Ruby process.

  2. Forks to run your test files in parallel and without overhead.

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

  * Implemented in less than 360 lines (SLOC) of pure Ruby code! :-)

------------------------------------------------------------------------------
Architecture
------------------------------------------------------------------------------

Following UNIX philosophy, TestR is made of simple text-based programs:

* `testr` is an interactive command-line user interface (CLI) for driver
* `testr-herald` monitors current directory tree and reports changed files
* `testr-driver` tells master to run tests and keeps track of test results
* `testr-master` absorbs test execution overhead and forks to run your tests

You can build your own custom TestR user interface by wrapping `testr-driver`!

------------------------------------------------------------------------------
Prerequisites
------------------------------------------------------------------------------

  * Ruby 1.8.7 or 1.9.2 or newer.

  * Operating system that supports POSIX signals and the `fork()` system call.

    To check if your system qualifies, launch `irb` and enter the following:

        Process.respond_to? :fork  # must be true
        Signal.list.key? 'TERM'    # must be true
        Signal.list.key? 'KILL'    # must be true

------------------------------------------------------------------------------
Installation
------------------------------------------------------------------------------

As a Ruby gem:

    gem install testr

As a Git clone:

    git clone git://github.com/sunaku/testr
    cd testr
    bundle install

------------------------------------------------------------------------------
Invocation
------------------------------------------------------------------------------

If installed as a Ruby gem:

    testr

If installed as a Git clone:

    bundle exec ruby -Ilib bin/testr

You can monitor your test processes in another terminal:

    watch 'ps xuw | sed -n "1p; /test[r]/p" | fgrep -v sed'

You can forcefully terminate TestR from another terminal:

    pkill -f testr

------------------------------------------------------------------------------
Configuration
------------------------------------------------------------------------------

TestR looks for a configuration file named `.testr.rb` in its current working
directory.  The configuration file is a normal Ruby script.  Inside it, you
can query and modify the `TestR::Config` object (OpenStruct) according to the
configuration options listed below.

------------------------------------------------------------------------------
Configuration options
------------------------------------------------------------------------------

### TestR::Config.max_concurrent_tests

Maximum number of test files to run concurrently.  The default value is the
number of detected processors on your system, or just 1 if detection fails.

### TestR::Config.overhead_load_paths

Array of paths that are prepended to Ruby's `$LOAD_PATH` before the
test execution overhead is loaded into `testr-master`.

### TestR::Config.overhead_file_globs

Array of file globbing patterns that describe a set of Ruby scripts that are
loaded into `testr-master` as test execution overhead.

### TestR::Config.reabsorb_file_greps

Array of regular expressions that describe a set of file paths that cause the
test execution overhead to be reabsorbed in `testr-master` when they change.

### TestR::Config.all_test_file_globs

Array of file globbing patterns that describe the set of all test files in
your Ruby application.

### TestR::Config.test_file_globbers

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

    TestR::Config.test_file_globbers[%r<^(lib|app)/.+\.rb$>] = lambda do |path|
      name = File.basename(path, '.rb')
      "{test,spec}/**/#{name}_#{name.reverse}.rb"
    end

In addition, these lambda functions can return `nil` if they do not wish for a
particular source file to be tested.  For example, to ignore tests for all
source files except those within a `models/` directory, you would write:

    TestR::Config.test_file_globbers[%r<^(lib|app)/.+\.rb$>] = lambda do |path|
      if path.include? '/models/'
        "{test,spec}/**/#{File.basename(path)}"
      end
    end

### TestR::Config.test_name_extractor

Lambda function that is given a line of source code to determine whether it
can be considered as a test definition.  In which case, the function must
extract and return the name of the test being defined.

### TestR::Config.before_fork_hooks

Array of lambda functions that are executed inside `testr-master` before a
worker process is forked to run a test file.  These functions are given:

1. The sequence number of the worker process that will be forked shortly.

2. The path of the log file containing the live output of the worker process.

3. The path of the test file that will be run by the worker process.

4. An array of names of tests inside the test file that will be run.  If this
   array is empty, then all tests in the test file will be run.

For example, to see some real values:

    TestR::Config.before_fork_hooks << lambda {
      |worker_number, log_file, test_file, test_names|

      p :before_fork_hooks => {
        :worker_number => worker_number,
        :log_file      => log_file,
        :test_file     => test_file,
        :test_names    => test_names,
      }
    }

### TestR::Config.after_fork_hooks

Array of lambda functions that are executed inside a worker process forked
by `testr-master`.  These functions are given:

1. The sequence number of the worker process.

2. The path of the log file containing the live output of the worker process.

3. The path of the test file that will be run by the worker process.

4. An array of names of tests inside the test file that will be run.  If this
   array is empty, then all tests in the test file will be run.

For example, to see some real values, including the worker process' PID:

    TestR::Config.after_fork_hooks << lambda {
      |worker_number, log_file, test_file, test_names|

      p :after_fork_hooks => {
        :worker_pid    => $$,
        :worker_number => worker_number,
        :log_file      => log_file,
        :test_file     => test_file,
        :test_names    => test_names,
      }
    }

The first function in this array instructs Test::Unit and RSpec to only run
those tests that correspond to the given `test_names` values.  This
accelerates your test-driven development cycle and improves productivity!

------------------------------------------------------------------------------
Configuration helpers
------------------------------------------------------------------------------

The following libraries assist you with configuring TestR.  To use them,
simply add the require() lines shown below to your configuration file.

### require 'testr/config/rails'

Support for the [Ruby on Rails](http://rubyonrails.org) web framework.

### require 'testr/config/parallel_tests'

Support for the [parallel_tests](https://github.com/grosser/parallel_tests)
library.

------------------------------------------------------------------------------
Known issues
------------------------------------------------------------------------------

### Ruby on Rails

  * Ensure that your `config/environments/test.rb` file disables class caching
    as follows (**NOTE:** if you are using Rails 3, the `testr/config/rails`
    configuration helper can do this for you automatically):

        config.cache_classes = false

    Otherwise, TestR will appear to ignore source-code changes in your
    models, controllers, helpers, and other Ruby source files.

  * SQLite3 [raises `SQLite3::BusyException: database is locked` errors](
    https://github.com/sunaku/test-loop/issues/2 ) because TestR runs your
    test files in parallel.  You can work around this by using an [in-memory
    adapter for SQLite3]( https://github.com/mvz/memory_test_fix ) or by using
    different database software (such as MySQL) for your test environment.

------------------------------------------------------------------------------
License
------------------------------------------------------------------------------

Released under the ISC license.  See the LICENSE file for details.
