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

  * Its core is written in about 420 lines (SLOC) of pure Ruby code! :-)

### Architecture

Following UNIX philosophy, Tork is composed of simple text-based programs that
*do one thing well*.  As a result, you could even create your own Tork user
interface by wrapping `tork-driver` appropriately!

  * `tork` is an interactive command-line user interface for `tork-driver`
  * `tork-herald` monitors current directory tree and reports changed files
  * `tork-driver` drives the engine according to the herald's observations
  * `tork-engine` tells master to run tests and keeps track of test results
  * `tork-master` absorbs test execution overhead and forks to run your tests
  * `tork-remote` remotely controls any tork program running in the same `pwd`

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

  * Ruby 1.8.7 or 1.9.3 or newer.

  * Operating system that supports POSIX signals and the `fork()` system call.
    To check if your system qualifies, launch `irb` and enter the following:

        Process.respond_to? :fork  # must be true
        Signal.list.key? 'TERM'    # must be true

  * To make the `tork-herald` program's filesystem monitoring more efficient:

        gem install rb-inotify  # linux
        gem install rb-fsevent  # macosx

### Development

    git clone git://github.com/sunaku/tork
    cd tork
    bundle install
    bundle exec tork --help  # run it directly
    bundle exec rake --tasks # packaging tasks

## Usage

### At the command line

    tork --help

You can control tork(1) interactively from another terminal:

    tork-writer
    # type your commands here, one per line.
    # press Control-D to exit tork-writer(1)

You can also do the same non-interactively using a pipeline:

    # run lines 4, 33, and 21 of test/some_test.rb
    echo t test/some_test.rb 4 33 21 | tork-writer

You can monitor your test processes from another terminal:

    watch 'pgrep -f ^tork | xargs ps u'

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

## License

Released under the ISC license.  See the LICENSE file for details.

[factory_girl]: https://github.com/thoughtbot/factory_girl
[memory_test_fix]: https://github.com/stepahn/memory_test_fix
[parallel_tests]: https://github.com/grosser/parallel_tests
[Ruby on Rails]: http://rubyonrails.org
[Cucumber]: https://cukes.info
