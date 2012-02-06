    _______      _______
     ___  /___________ /__
      _  __/ __ \  __/ /_/
      / /_/ /_/ / / / ,\
      \__/\____/_/ /_/|_\
                 >>>------>

# _Test with fork_

Tork runs your tests as they change, in parallel:

  1. Absorbs test execution overhead into a master process.

  2. Forks to inherit overhead and run test files in parallel.

  3. Avoids running unchanged tests inside changed test files.

## Features

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

  * Its core is written in about 410 lines (SLOC) of pure Ruby code! :-)

### Architecture

Following UNIX philosophy, Tork is composed of simple text-based programs that
*do one thing well*.  As a result, you could even create your own Tork user
interface by wrapping `tork-driver` appropriately!

  * `tork` is an interactive command-line user interface for `tork-driver`
  * `tork-herald` monitors current directory tree and reports changed files
  * `tork-driver` drives the engine according to the herald's observations
  * `tork-engine` tells master to run tests and keeps track of test results
  * `tork-master` absorbs test execution overhead and forks to run your tests

When the herald observes that files in or beneath the current directory have
been written to, it tells the driver, which then commands the master to fork a
worker process to run the tests affected by those changed files.  This is all
performed automatically.  But what if you want to manually run a test file?

You can (re)run any test file by simply saving it!  When you do, Tork tries to
figure out which tests inside your newly saved test file have changed (using
diff and regexps) and then attempts to run just those.  To make it run *all*
tests in your saved file, simply save the file *again* without changing it.

## Installation

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

## Usage

### At the command line

    tork --help

You can monitor your test processes from another terminal:

    watch 'ps xuw | sed -n "1p; /tor[k]/p" | fgrep -v sed'

### With RSpec

RSpec 2.8.0 and older contain [a bug](
https://github.com/sunaku/tork/issues/31 ) where a nonzero exit status (caused
by an uncaught exception) is overridden by RSpec's `Kernel#at_exit` handler to
be zero, thereby falsely indicating that a spec had passed.  [This patch](
https://github.com/rspec/rspec-core/pull/569/files ) fixes the problem.

### With [Ruby on Rails]

For Rails 3 or newer, use the `tork/config/rails` configuration helper.
Otherwise, ensure that your `config/environments/test.rb` file contains:

    config.cache_classes = false

To use SQLite3 as your test database, install its [in-memory database
adapter][memory_test_fix].  Otherwise, you *might* face these errors:

> SQLite3::BusyException: database is locked

> cannot start a transaction within a transaction

## Configuration

Tork looks for a configuration file named `.tork.rb` in its current working
directory.  The configuration file is a normal Ruby script, inside which you
can query and modify the `Tork::Config` object, which is a kind of `Struct`.

Note that Tork *does not* automatically reload changes in your configuration
file.  So you must restart Tork accordingly if your configuration changes.

## Configuration helpers

In case you did not read the `tork --help` manual page, please note that you
can pass *multiple* configuration helpers to tork(1) at the command line!

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

### [factory_girl]

At the command line:

    tork factory_girl

Or in your configuration file:

    require 'tork/config/factory_girl'

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

### Receive notifications via libnotify, growl, or xmessage

At the command line:

    tork notify

Or in your configuration file:

    require 'tork/config/notify'

## Configuration options

This table shows which configuration options affect which Tork components:

| Affects `tork-driver` | Affects `tork-engine` | Affects `tork-master` |
| --------------------- | --------------------- | --------------------- |
| overhead_load_paths   | test_event_hooks      | max_forked_workers    |
| overhead_file_globs   |                       | before_fork_hooks     |
| reabsorb_file_greps   |                       | after_fork_hooks      |
| all_test_file_globs   |                       |                       |
| test_file_globbers    |                       |                       |

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
a lambda function that accepts a `MatchData` object containing the results of
the regular expression matching against the path of a changed file, and yields
one or more file globbing patterns (a single string, or an array of strings)
that describe a set of test files that need to be run.

The results of these functions are recursively expanded (fed back into them)
to construct an entire dependency tree of test files that need to be run.  For
instance, if one function returns a glob that yields files matched by another
function, then that second function will be called to glob more test files.
This process repeats until all dependent test files have been accounted for.

#### Single glob expansion

For example, if test files had the same names as their source files followed by an
underscore and the file name in reverse like this:

  * `lib/hello.rb` => `test/hello_olleh.rb`
  * `app/world.rb` => `spec/world_ldrow.rb`

Then you would add the following to your configuration file:

    Tork::Config.test_file_globbers[%r<^(lib|app)/.*?([^/]+?)\.rb$>] = lambda do |matches|
      name = matches[2]
      "{test,spec}/**/#{name}_#{name.reverse}.rb"
    end

#### Multi-glob expansion

For example, if test files could optionally have "test" or "spec" prefixed or
appended to their already peculiar names, like so:

  * `lib/hello.rb` => `test/hello_olleh_test.rb`
  * `lib/hello.rb` => `test/test_hello_olleh.rb`
  * `app/world.rb` => `spec/world_ldrow_spec.rb`
  * `app/world.rb` => `spec/spec_world_ldrow.rb`

Then you would add the following to your configuration file:

    Tork::Config.test_file_globbers[%r<^(lib|app)/.*?([^/]+?)\.rb$>] = lambda do |matches|
      name = matches[2]
      ["{test,spec}/**/#{name}_#{name.reverse}.rb",
       "{test,spec}/**/#{name}_#{name.reverse}_{test,spec}.rb",
       "{test,spec}/**/{test,spec}_#{name}_#{name.reverse}.rb"]
    end

#### Recursive expansion

For example, if you wanted to run test files associated with `lib/hello.rb`
whenever the `app/world.rb` file changed, then you would write:

    Tork::Config.test_file_globbers[%r<^app/world\.rb$>] = lambda do |matches|
      'lib/hello.rb'
    end

This effectively aliases one file onto another, but not in both directions.

#### Suppressing expansion

These lambda functions can return `nil` if they do not wish for a particular
source file to be tested.  For example, to ignore tests for all source files
except those within a `models/` directory, you would write:

    Tork::Config.test_file_globbers[%r<^(lib|app)(/.*?)([^/]+?)\.rb$>] = lambda do |matches|
      if matches[2].include? '/models/'
        ["{test,spec}/**/#{matches[3]}_{test,spec}.rb",
         "{test,spec}/**/{test,spec}_#{matches[3]}.rb"]
      #else     # implied by the Ruby language
        #nil    # implied by the Ruby language
      end
    end

### Tork::Config.before_fork_hooks

Array of lambda functions that are invoked inside `tork-master` before a
worker process is forked to run a test file.  These functions are given:

1. The path of the test file that will be run by the worker process.

2. An array of line numbers in the test file to run.  If this array is empty,
   then the entire test file will be run.

3. The path of the log file containing the live output of the worker process.

4. The sequence number of the worker process that will be forked shortly.

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

Array of lambda functions that are invoked inside a worker process forked
by `tork-master`.  These functions are given:

1. The path of the test file that will be run by the worker process.

2. An array of line numbers in the test file to run.  If this array is empty,
   then the entire test file will be run.

3. The path of the log file containing the live output of the worker process.

4. The sequence number of the worker process.

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

### Tork::Config.test_event_hooks

Array of lambda functions that are invoked inside `tork-engine` whenever it
receives a status message (passed into those functions) from `tork-master`.
Run `tork-master --help` for more information about these status messages.

For example, to see some real values:

    Tork::Config.test_event_hooks.push lambda {|message_from_tork_master|
      p :test_event_hooks => message_from_tork_master
    }

## License

Released under the ISC license.  See the LICENSE file for details.

[factory_girl]: https://github.com/thoughtbot/factory_girl
[memory_test_fix]: https://github.com/mvz/memory_test_fix
[parallel_tests]: https://github.com/grosser/parallel_tests
[Ruby on Rails]: http://rubyonrails.org
[Cucumber]: https://cukes.info
