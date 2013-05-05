## Version 19.2.2 (2013-05-04)

This release makes Tork resilient to `Errno::EADDRINUSE` errors that may occur
sometimes, intermittently, when test execution overhead is being reabsorbed.

Patch:

  * server: retry until the socket opens successfully

Other:

  * include md2man rake tasks in developer's rakefile

## Version 19.2.1 (2013-02-08)

Patch:

  * GH-46: allow reassigning `$tork_*` variable values.  Thanks to Joe
    Escalante for reminding me to fix this issue.

  * GH-48: disable class caching at the ActiveSupport level for Devise.
    Thanks to Ryan Ahearn for fixing this issue and to Jonathan Cairns for
    reporting it.

## Version 19.2.0 (2012-12-30)

Minor:

  * Add "devise" configuration helper that adds support for testing Rails
    applications that use the Devise authentication framework.  Thanks to Ryan
    Ahearn for this contribution.

Patch:

  * gemspec: upgrade to *listen* 0.7.0 to fix issue #43.  Thanks to Ryan
    Ahearn for reporting this issue and helping debug it, and to Thibaud
    Guillaume-Gentil for fixing this issue upstream in the *listen* library.

  * Fix `undefined method 'path' for nil` error on socket file removal.

## Version 19.1.0 (2012-12-12)

Minor:

  * tork-driver: don't run overhead files as test files

Patch:

  * rails: run dependent tests when `app/views/*` change

  * Clear FactoryGirl sequences and traits on fork in the `factory_girl`
    configuration helper.  Thanks to Ryan Ahearn for this contribution.

  * server: fix clean up of socket files upon exit

## Version 19.0.2 (2012-11-07)

Patch:

  * Monkeypatch `at_exit()` to fix RSpec and MiniTest:

    https://github.com/rspec/rspec-core/pull/720

    https://github.com/seattlerb/minitest/pull/183

Other:

  * README: document RSpec 2.9.0+ autorun skipping bug

  * README: MiniTest 1.3.2+ also has autorun skip bug

## Version 19.0.1 (2012-10-26)

Patch:

  * Support testing projects that have both test/ and spec/ directories.

    I assumed that users would only have either test/ or spec/ but not both.
    Do you know what happens when a test/ is run by RSpec or vice versa? :-)

    Thanks to Kyle Peyton for reporting this issue.

  * Automatically load the "autorun" helpers for RSpec and MiniTest.

    RSpec users are accustomed to not having `require "rspec/autorun"` in
    their spec/spec_helper.rb file because they use the rspec(1) executable
    to run their tests.  This commit makes things Just Work for them again.

Other:

  * test whether input is JSON by actually parsing it

  * server: use Set instead of Array for faster lookup

## Version 19.0.0 (2012-10-17)

Major:

  * The `.tork.rb` configuration file has been replaced by the `.tork/`
    directory, which contains specially-named Ruby scripts.  Refer to the
    `TORK_CONFIGS` environment variable in tork(1) for more information.

  * The `Tork::Config` object has been replaced by various data structures in
    the `Tork::` namespace.  See the "FILES" sections in the manual pages of
    tork programs for information on the data structures that replaced it.

  * `Tork::Config.test_event_hooks` has been removed.  Instead, you must now
    monitor the STDOUT of tork-master(1) or tork-engine(1) either directly
    or indirectly, via tork-remote(1), and react to their status messages.
    See the tork-notify(1) program for an example of how to implement this.

  * tork(1): 't' now runs a specified test, whereas 'a' runs all tests.

  * tork-engine(1): the `run_test_file` command now takes line numbers as a
    variable-length list of arguments (varargs) rather than as an array.

  * tork-engine(1): the `run_test_file` command now runs an entire test file
    when zero is given as one of the line numbers to be run.

  * tork-master(1): the `load` command is no longer accepted.  Instead, you
    must specify load paths and overhead files in the `.tork/master.rb` file.

  * The `TORK_CONFIGS` env-var is now a colon delimited list of directories.

  * The `tork/client` library has been removed.  The threaded IO and popen()
    wrappers that it provided have been replaced by the powerful IO.select().

Minor:

  * tork(1): allow user to specify arguments after command key

  * tork(1): add 'k' to stop all currently running tests with SIGKILL

  * add tork-remote(1) to remotely control any tork program.  This feature is
    made possible by the awesome power of IO.select() and UNIX domain sockets.

  * add tork-notify(1) as example of using tork-remote(1) and tork-engine(1)

  * tork-engine(1): add `["run_test_files"]` command to run multiple files

  * tork-engine(1): emit edge-triggered `pass_now_fail` and `fail_now_pass`
    events to notify you about changes in a test file's pass/fail status.

  * typing Control-D now breaks tork programs out of `Tork::Server#loop()`

Patch:

  * tork-master(1): stop workers with SIGKILL when quitting

Other:

  * tork(1): document parameters for `t` and `s` commands

  * README: add tip about rlwrap for better interactive

  * README: simplify watch command using pgrep & xargs

  * README: use standard bundle exec; no `--binstubs`

## Version 18.2.4 (2012-10-10)

Other:

  * GH-39: upgrade listen gem version to fix a bug in OSX.
    Thanks to Adam Grant for reporting this issue.

## Version 18.2.3 (2012-09-26)

Patch:

  * Restored support for building Tork from its gemspec under Ruby 1.8.
    Thanks to Ohno Shin'ichi for reporting this issue and contributing a
    preliminary fix.

  * Add resilience against failed command dispatch in `Tork::Server#loop()`.

Other:

  * It's not worth rescuing Interrupt only to exit silently.
    Let the user see stack traces when they press Control-C.

  * Update old comments about SIGCHLD handler, which was
    replaced by reaping threads quite a few releases ago.

  * Use $0 instead of hard-coding the program name.

## Version 18.2.2 (2012-07-11)

Patch:

  * GH-35: resume dispatched but not yet started tests.

    After reabsorbing overhead, we need to resume previously dispatched test
    files that have not yet finished running.  This includes the waiting set
    (dispatched but not yet running) as well as the running set (dispatched
    and already started running).  Otherwise, we encounter a bug where test
    files in the waiting set can NEVER be run again!

## Version 18.2.1 (2012-07-05)

Patch:

  * GH-37: switch from Guard::Listener to Listen gem.
    Thanks to Jesse Cooke for reporting this issue.

Other:

  * gemspec: need to provide .0 suffix for ~> operator.

  * gemspec: LICENSE file contains UTF-8 author names.

## Version 18.2.0 (2012-03-27)

Minor:

  * Emit warnings when commands cannot be performed.  This improves the user
    experience by giving them immediate feedback.  For example, if you issue
    the "rerun_failed_tests" command and no tests have failed yet, you will
    now see a warning message that explains the situation.  Thanks to
    NagaChaitanya Vellanki (@chaitanyav) for suggesting this change.

Patch:

  * GH-32: Restore support for Selenium and Capybara by replacing the global
    SIGCHLD handler in tork-master(1) with individual threads, one per forked
    worker process.  Thanks to Bjørn Trondsen (@Sharagoz) for reporting this
    issue and verifying the fix.

  * README: Recommend a newer fork of the "memory_test_fix" Rails plugin.

## Version 18.1.0 (2012-02-26)

Minor:

  * Add `tork/config/coverage` configuration helper for Ruby 1.9, which prints
    a coverage report at the end of your log file in YAML format.  The report
    is a hash containing the following information per each loaded Ruby file
    that exist in or beneath the current working directory:

      * :grade - percentage of C0 code coverage for source lines of code
      * :nsloc - total number of source lines of code in the file
      * :holes - line numbers of source lines that were not covered

## Version 18.0.1 (2012-02-13)

Alert:

  * If you're on Ruby 1.9, please use 1.9.3 or newer because 1.9.2 is
    known to segfault under RSpec and Rails.  See GH-30 and GH-32.

Patch:

  * GH-27: Cucumber features now run correctly under RSpec.  Thanks to Scott
    Radcliff for reporting this issue and to David Burrows for solving it!

  * tork(1): fix undefined method `strip' for nil:NilClass error.

  * tork/config: ignore directories given as configuration files.

## Version 18.0.0 (2012-02-06)

Alert:

  * RSpec 2.8.0 and older contain [a bug](
    https://github.com/sunaku/tork/issues/31 ) where a nonzero
    exit status (caused by an uncaught exception) is overridden
    by RSpec's `Kernel#at_exit` handler to be zero, thereby
    falsely indicating that a spec had passed.  [This patch](
    https://github.com/rspec/rspec-core/pull/569/files) fixes the
    problem.  Thanks to Gumaro Melendez for reporting this issue.

Major:

  * Dropped first parameter to `Tork::Config::test_file_globbers`.

  * GH-31: tork-master now emits separate exit code and info.
    Update your `Tork::Config::test_event_hooks` accordingly.

  * tork/server: switch from modules to class inheritance.

  * tork/config: switch to Struct to prevent misspellings.

Minor:

  * tork-driver now recursively expands dependent test files while globbing.

  * Extracted bookkeeping stuff from tork-driver into tork-engine component.

Other:

  * tork/config: do not reabsorb when .tork.rb
    changes.  Since the configuration is loaded in
    multiple processes, it is difficult to reload
    the configuration on the fly without adding
    significant complexity to Tork.  Instead, it's
    easier to accept the limitation that you must
    restart Tork if you change your configuration.

  * GH-29: bump guard version requirement to v1 series.

  * Improve documentation; revise markdown; clean up.

## Version 17.1.0 (2012-01-30)

Minor:

  * Added `Tork::Config.test_event_hooks` configuration option.

  * Added `tork/config/notify` configuration helper for receiving
    edge-triggered notifications (via libnotify, growl, or
    xmessage) about changes in test files' pass/fail status.

  * Added `tork/config/factory_girl` configuration helper for properly
    clearing factory definitions before forking and then finding them after
    forking to avoid `FactoryGirl::DuplicateDefinitionError`.  (Mark Hayes)

  * Lambda functions in `Tork::Config.test_file_globbers` can now return
    multiple globs in an array, in addition to just a single glob or `nil`.

  * Added support for the MiniTest convention of naming test files as
    `test/**/test_*.rb` and `spec/**/spec_*.rb`. (Jose Pablo Barrantes)

## Version 17.0.1 (2012-01-29)

Patch:

  * tork-herald(1) *sometimes* reported changed test files twice.

  * tork/driver: only whole test file runs should qualify as pass.

  * tork/config/cucumber: only set ARGV for `*.feature` test files.

  * Tork::Client::Transceiver needs to stop both TX & RX loops.

Other:

  * tork/driver: store test file lists in Set, not Array.

  * HISTORY: use single-word change-set descriptions.

## Version 17.0.0 (2012-01-27)

Major:

  * tork-herald(1) now emits batches of single-line JSON arrays instead of
    printing one (raw) path per line.  This makes IPC uniform across Tork.

  * tork-master(1) now emits log_file and worker_number in status messages.

  * The order of parameters for before/after fork hooks has been changed to
    better reflect the order of items in tork-master(1)'s status messages.

    * The old order was: worker_number, log_file, test_file, line_numbers.

    * The new order is:  test_file, line_numbers, log_file, worker_number.

Minor:

  * GH-24: add `tork/config/dotlog` configuration helper to "hide" log files.
    (Nicolas Fouché)

  * GH-25: add `tork/config/logdir` configuration helper to isolate log files.
    (Jose Pablo Barrantes)

  * tork(1) now strips all whitespace from your input, in case you pressed
    spacebar or tab a few times, by accident, before entering your command.

Other:

  * tork/client: Replace write lock with queue to support SIGCHLD handler.

    The SIGCHLD handler in tork-master(1) can be triggered at any time, even
    in the middle of writing to the standard output stream!  Locking access
    to the output stream in normal code (outside the signal handler) would
    freeze the program because the signal handler, waiting for the lock to
    be released, would never return!

    One solution is to maintain a thread-safe queue of outgoing items that
    need to be written to the output stream.  Both normal code and the
    signal handler can quickly push an outgoing item onto the queue and
    proceed with their business.  A separate thread can then have the sole
    responsibility of (and access to) continually writing those outgoing
    items to the output stream.

  * README: revise instructions, reorganize document, and other improvements.

## Version 16.0.0 (2012-01-25)

Major:

  * Drop the `Tork::Config.test_name_extractor` configuration option.

  * Pass line numbers instead of test names to before/after fork hooks.

  * Pass $~ (MatchData) to `Tork::Config::test_file_globbers` functions.

Minor:

  * tork/config/cucumber: only run changed scenarios in changed features.

Other:

  * README: update instructions on running Tork directly from Git clone.

## Version 15.1.0 (2012-01-25)

Minor:

  * GH-19: add `tork cucumber` for running cucumber features.

Patch:

  * tork/config/rails: support Rails 2 and don't assume AR is used.  (Benjamin
    Quorning)

  * tork/config: settings from configuration helpers specified in
    $TORK_CONFIGS should override settings from the `.tork.rb` file.

  * README: need to set $PATH to run this project from a git clone.

  * LICENSE: give copyright to major contributors only.
    See <http://stackoverflow.com/questions/1497756>.
    Also added forgotten Luke Wendling to the list.

## Version 15.0.1 (2012-01-24)

Patch:

  * GH-21: Ruby 1.9 class_eval() is smarter than 1.8.

  * GH-20: forgot `require 'thread'` for Mutex class.  (Jesse Cooke)

Other:

  * tork(1): fix shadowed variable names.  (Jose Pablo Barrantes)

  * GH-22: fix command to build & install gem from source.

  * GH-22: add m2dman as development dependency in gemspec.

  * GH-18: windows not supported; lacks fork & SIGCHLD.

  * README: spruce up introduction and features list.

  * README: missed a testr => tork rename in watch cmd.

  * README: add tip about Guard's FS watching backends.

## Version 15.0.0 (2012-01-23)

Major:

  * This project has been renamed from TestR to Tork (test with fork) in order
    to better compete with rival projects, namely Spork! >:-)  Credit goes to
    Brian D. Burns for thinking of this most succinct & awesome project name!
    He also created the snazzy ASCII-art logo featured in the project README.

  * tork(1): rename `r` command, which runs all tests, to `t`, for *t*ork.

## Version 14.3.0 (2012-01-20)

Minor:

  * testr(1): notify user while dispatching their commands. This is especially
    useful when the "rerun_passed_test_files" command has been dispatched but
    there are no passed test files, so nothing happens and from the user's
    perspective: TestR sucks because it's unresponsive.

  * config/testr/rails: Reopen connections in forked workers to fix errors:

        Mysql2::Error: MySQL server has gone away
        PGError: connection not open

    Thanks to Spencer Steffen for [contributing this solution](
    https://github.com/sunaku/tork/issues/14#issuecomment-3539470).

  * testr-driver(1): document the "over" status message in manual page.

Other:

  * testr-driver(1): keep same herald; only replace master.

  * testr(1): shorten code for loop break on quit command.

  * server: rename `@upstream` to `@client` for coherence.

  * Can pass lambda and proc with block to `<<` method.

  * Explain `$0` override at the start of bin/ scripts.

  * LICENSE: credit our most recent contributors.

## Version 14.2.0 (2012-01-16)

Minor:

  * Add ability to run `testr rails` without needing a `.testr.rb` file.

  * testr(1) no longer shows command menu at startup.  Press ENTER to see it.

  * testr(1) now notifies you before absorbing overhead at startup.

Patch:

  * testr(1) now accepts death silently when Control-C is pressed.

## Version 14.1.3 (2012-01-13)

Patch:

  * Add support Guard v0.9.0 and newer in `testr-herald`.  (Jose Pablo
    Barrantes)

Other:

  * Tighten version constraints for gem dependencies to avoid future
    breakages.

## Version 14.1.2 (2012-01-09)

Minor:

  * Don't consider partial test file pass as full pass.

Other:

  * Upgrade to binman 3 for better bundler support.

## Version 14.1.1 (2011-12-07)

Patch:

  * Do not fail when given test file no longer exists.

  * Make xUnit `--name` option regexp case-insensitive.

  * RSpec does not accept regexp for `--example` option;
    see https://github.com/rspec/rspec-core/issues/445
    and https://github.com/dchelimsky/rspec/issues/44

  * Ruby 187 does not have Symbol#upcase() method.

Other:

  * README: add another SQLite3 error to known issues.
    Thanks to Luke Wendling for contributing this patch.

  * README: add a section explaining usage and theory.

  * README: show example earlier in factory_girl tip.

  * README: update lines of code statistic: 372 SLOC.

  * Better variable naming for self-documentation.

  * Upgrade to binman 2.0.0 for UNIX man pages.

## Version 14.1.0 (2011-11-03)

Minor:

  * Make servers responsive to quit request (SIGTERM) from upstream.

    This change lets the user quit testr-master(1) while it is loading
    test execution overhead (which can be a lengthy, blocking operation).

    By sending a signal to the server, we don't have to wait for it to
    finish processing its current command before seeing our :quit command.

  * Add embedded BinMan manual pages to bin scripts.  All TestR scripts now
    have a `--help` option which displays their UNIX manual page.  Try it!

    The single-line JSON message protocol used by these scripts is now
    documented in their manual pages, so you should have everything you
    need to create *your own custom user interface to TestR* if you wish! :-)

Patch:

  * SIGCHLD does not awaken main thread in Ruby 1.9.3p0.

Other:

  * Simplify watch(1) ps(1) process title monitoring.

  * Testr: tell user to press ENTER after command key.

  * README: add tip on loading factory_girl factories.

## Version 14.0.3 (2011-10-11)

Patch:

  * Forgot to migrate the `testr/config/rails` configuration helper to use the
    new TestR configuration parameter names.

## Version 14.0.2 (2011-10-11)

Patch:

  * Fix updating passed/failed test files bookkeeping.  Once a test file
    failed, it was (incorrectly) always considered failed, even if it passed
    later on.

  * Do not requeue test files that are waiting to run.

Other:

  * Rename `*.md` files to `*.markdown` to avoid ambiguity.

## Version 14.0.1 (2011-10-10)

Patch:

  * Use blue/red for pass/fail instead of green/red to accommodate the color
    blind.

  * Incorrect test name regexp was passed down to Test::Unit.  This broke
    focused testing, where only changed tests in a changed test file are run.

Other:

  * Make `testr-master` wait for killed worker processes before exiting.

## Version 14.0.0 (2011-10-09)

Major:

  * Renamed this project and its resources from test-loop to TestR.

  * Renamed the `reabsorb_file_globs` configuration parameter to
    `reabsorb_file_greps`.  It now contains regular expressions.

  * Renamed the `test_file_matchers` configuration parameter to
    `test_file_globbers`.  Its keys are now regular expressions.

  * Renamed the `test_name_parser` configuration parameter to
    `test_name_extractor`.

  * Renamed the `max_concurrent_tests` configuration parameter to
    `max_forked_workers`.

  * Renamed the `before_each_test` configuration parameter to
    `after_fork_hooks`.  Its function parameters have also changed.

  * Removed the `delay_per_iteration` and `after_each_test` configuration
    parameters.

  * Removed the `test/loop/notify` and `test-loop/coco` libraries.

Minor:

  * The file system is no longer polled to detect modified files.  Instead, it
    is monitored for file modification events in a portable and efficient
    manner using the [Guard](https://github.com/guard/guard) library.

  * The number of processors on your system is automatically detected for the
    `max_forked_workers` configuration parameter.

  * Added `overhead_load_paths`, `all_test_file_globs`, and
    `before_fork_hooks` configuration parameters.

  * Added ability to re-run passed and failed tests in the `testr` script.

Other:

  * The monolithic `test-loop` script has been replaced by several smaller
    ones that communicate with each other using single-line JSON messages via
    their standard input & output streams.  See "Architecture" in the README.

  * Now using Bundler to manage development dependencies and gem packaging.

## Version 13.0.1 (2011-09-21)

Other:

  * Forgot to include `test/loop/coco` preset in gem package.

  * Forgot to mention `test/loop/parallel_tests` preset in README.

## Version 13.0.0 (2011-08-24)

Major:

  * Pass worker sequence number as the last argument to lambda functions in
    `Test::Loop.before_each_test` and `Test::Loop.after_each_test` arrays.

Minor:

  * In the `test/loop/rails` configuration preset:

    * Automatically test a controller when its model or factory is modified.

    * Warn the user if Railtie (Rails 3) is not available for automatic
      disabling of Rails' class caching mechanism under the test environment.

  * Add `test/loop/parallel_tests` configuration preset for parallel_tests
    gem.  (Corné Verbruggen)

  * Assign rotating sequence numbers to workers so that you can handle parallel
    processes like connecting to separate databases better.  (Corné
    Verbruggen)

Other:

  * README: move configuration presets above options.

  * Eliminate 1 SLOC: .rb extension used in file glob.

  * Turn off executable bit on loop.rb file mode.

  * Pass child ENV directly to exec() for atomicity.

## Version 12.3.1 (2011-07-19)

Patch:

  * Binary data could not be stored in environment variable values.

Other:

  * Forgot to add Jacob Helwig to the gemspec's authors list.

## Version 12.3.0 (2011-07-19)

Minor:

  * Add `Test::Loop::max_concurrent_tests` configuration parameter to limit
    the number of test files run concurrently (default 4).  Otherwise, with
    large test suites, we could end up swamping the machine running the tests
    by forking hundreds of test files at once.  (Jacob Helwig)

  * Rails: add matcher for `test/factories/*_factory.rb`.

Other:

  * ENV returns a Hash with duplicate/frozen keys/values.  (Brian D. Burns)

  * Use Marshal to propagate resume_files to reabsorb.

  * Store test_files in a Set instead of an Array.

## Version 12.2.0 (2011-06-01)

  * Prevent empty test suite run in master process.  (Brian D. Burns)

  * Report test execution statistics in `test/loop/notify` preset as
    requested by Juan G. Hurtado..

  * Add `test/loop/coco` preset for integrating the [Coco code coverage
    library](http://lkdjiin.github.com/coco/).

## Version 12.1.0 (2011-04-29)

Minor:

  * Add `Test::Loop.delay_per_iteration` parameter to control the number of
    seconds (or fractions thereof) to sleep in between test-loop iterations.

## Version 12.0.4 (2011-04-29)

Patch:

  * Reabsorb overhead when user's configuration file changes.  (Brian D. Burns
    and Daniel Pittman)

  * `Thread.new { system() }` really is backgrounded so `fork { system() }` is
    not necessary!  [This issue](https://github.com/sunaku/test-loop/issues/5)
    was solved by upgrading to the newer 2.6.38.4-1 Linux kernel on my system.

## Version 12.0.3 (2011-04-25)

Patch:

  * Fix SIGCHLD handling and test completion reporting (Daniel Pittman).

    We need to reap all ready children in SIGCHLD, not just the first, and
    should not be reporting completion in the signal handler.

    On a fast machine, or where there is a slow hook executed at the
    completion of a test run, more than one test child can terminate before
    the SIGCHLD handler is invoked, or while it is running.

    In that event we will only get another SIGCHLD when a new child
    terminates, not to signal that there was more than one current
    termination.  We need to loop to collect all terminated children during
    each invocation of the handler.

    Since we don't know which child terminated, we wait on any terminated
    child with NOHANG, until it informs us that there are no more zombies
    hanging about.

    Doing all the work of finishing the test case, cleaning up, and running
    user hooks inside the SIGCHLD handler block was pretty slow.  This could
    lead to a big pile-up of children that needed to be cleaned up, especially
    if the user hook did something like run another external process to signal
    completion.

    Moving the heavy work of completion outside the signal handler makes the
    whole thing a lot faster, and less likely to bump into the low limit for
    per-user processes on Mac OS-X.

  * Send SIGTERM to each worker PGID to kill workers (Brian D. Burns).

    Using Process.setsid() in the workers establishes each process "as a new
    session and process group leader".  So, the SIGTERM sent to the master's
    process group was not recieved by the workers.  kill_workers was simply
    waiting for the workers to finish.

  * Revert "skip at_exit() handlers defined in master process".

    This reverts commit 0a0837f0b7ec92810e1c81d7506f2c8309f25f62 which was
    originally written to skip the reporting of an empty test suite (master
    does not load test files, workers do) by Test::Unit and Minitest in the
    master process.

    Such a harmless annoyance should not warrant the crippling of at_exit in
    the master process because that would inhibit its valid uses as well:

    > "UNIX was not designed to stop you from doing stupid things, because
    > that would also stop you from doing clever things." ~Doug Gwyn

  * `Thread.new { system() }` is not really backgrounded so `fork()` instead!
    Many thanks to Brian D. Burns and Daniel Pittman for helping solve [this
    issue](https://github.com/sunaku/test-loop/issues/5).

## Version 12.0.2 (2011-04-21)

Patch:

  * Consider DB schema dump file as overhead in Rails.

  * Do not consider test factories as overhead in Rails.

  * Run test files when test factory files change in Rails.

Other:

  * Detach worker from master's terminal device sooner.

  * All required signals must be present in irb check.

  * Prevent ps(1) from truncating lines to $TERM width.

  * Retain ps(1) column header in watch command output.

  * Begin parameter descriptions with the noun itself.

## Version 12.0.1 (2011-04-20)

Patch:

  * Restore support for Ruby 1.8.7.

  * Allow user's test execution overhead to fork.

Other:

  * Freeze master's ENV properly; keep resume key.

  * Remove completed test from running list sooner.

  * Add instructions to check for POSIX prerequisites.

  * Support multiple test-loop instances in watch command.

## Version 12.0.0 (2011-04-19)

Major:

  * You must now explicitly `require 'test/loop/rails'` for Rails support
    because we can only *automatically* apply our Railtie (to disable class
    caching) after the overhead has been loaded, and by then it's too late:
    your models are already loaded & cached by the Rails environment.

  * Your tests can no longer read from the user's terminal (master's STDIN);
    instead they will read from an empty stream (the reading end of IO.popen).

Patch:

  * Replace threads with SIGCHLD for reporting test results.

    This fixes deadlock errors that sometimes occurred when the user's chosen
    test library tried to print something to STDOUT/STDERR (even though those
    streams were redirected to a log file in the worker process).

    Thanks to Brian D. Burns for suggesting and verifying that the use of
    threads to monitor workers was the culprit behind the deadlocks errors.

  * Ctrl-C did not raise Interrupt in my Rails 3 test suite.

Other:

  * Ensure a clean ENV when reabsorbing overhead.  Environment variables set
    by your test execution overhead are not propagated to subsequent
    reabsorptions.  (Brian D. Burns)

  * Call `setsid()` to detach worker from master's terminal.
    <http://stackoverflow.com/questions/1740308#1740314>

  * Mutex is not needed since we only use GIL'ed array methods.
    <http://www.ruby-forum.com/topic/174086#762788>

  * Remove redundant STDOUT coercion after loading user's testing library.

  * Further simplify `Test::Loop.run()` by higher-order programming.

  * Add LICENSE file to gem package.

  * Add prerequisites section about POSIX environment.

  * Add tip about annihilating test-loop processes.

  * Fix markdown formatting.

## Version 11.0.1 (2011-04-14)

Patch:

  * Only attempt to define Railtie if the current Rails version supports it.

## Version 11.0.0 (2011-04-14)

Major:

  * The `test/loop/rails` preset has been internalized and is now applied
    automatically if your test execution overhead includes Ruby on Rails.

Minor:

  * If you are using Rails 3, test-loop will automatically set
    `config.cache_classes = false` for your test environment.  (Brian D.
    Burns)

Patch:

  * Avoid deadlock errors when printing output from Test::Unit and MiniTest.
    (Brian D. Burns)

        `write': deadlock detected (fatal)

  * Signaled worker termination is neither pass nor fail.
    Do not treat it as a failure by printing the log file.

  * Ignore SIGINT in workers; only master must honor it.

## Version 10.0.1 (2011-04-08)

Patch:

  * Workers must ignore SIGTSTP, otherwise master waits forever before
    exiting.

  * Unregister trap in workers upon first reception instead of racing to
    unregister the trap handlers inherited from the master process.

  * Prevent uncaught throw error on subsequent Ctrl-C.

  * Simpler solution for terminating loop upon Ctrl-C.

## Version 10.0.0 (2011-04-06)

Major:

  * The `Test::Loop.before_each_test` and `Test::Loop.after_each_test`
    parameters are arrays now.

## Version 9.4.0 (2011-04-06)

Minor:

  * Allow lambda functions in `Test::Loop.test_file_matchers` to return `nil`
    so that you can exclude certain tests from being executed.  (Brian D.
    Burns)

  * Prefix worker process title with "test-loop" for easier ps(1)
    searchability.  The monitoring command in the README is now simplified to
    the following:

        watch 'ps xf | grep test-loop | sed 1,3d'

Patch:

  * Skip `at_exit()` when exiting master process.  This prevents an empty test
    from being run when exiting the loop after having processed a test/spec
    helper that loads the Test::Unit library.  (Brian D. Burns)

Other:

  * Use throw/catch to break loop instead of raising SystemExit exception.

  * Trap SIGTERM with IGNORE/DEFAULT instead of using a closure in master.

  * Unregister master's custom signal handlers inside worker processes.

  * Separate configuration parameters into subsections in README.

## Version 9.3.0 (2011-04-01)

Minor:

  * Resume currently running tests--as well as those currently needing to be
    run--after reabsorbing test execution overhead.  (Brian D. Burns)

  * Stop currently running tests (and wait for them to finish) before
    reabsorbing overhead.  This greatly improves responsiveness because worker
    processes are no longer there to compete with the new master process for
    system resources.

  * Notify user when running all tests and when exiting.  (Brian D. Burns)

  * Notify user when overhead changes instead of when restarting the loop.

  * Use ANSI clear line command to erase control-key combinations outputted by
    shells such as BASH and ZSH in test-loop's output.  (Brian D. Burns)

Patch:

  * `@last_ran_at` was being set during every iteration of the loop.  This is
    problematic when Ruby's `Time.now` is more precise than your filesystem's
    modification timestamp.  For example, in the ext3 filesystem under Linux,
    file modification timestamps have a precision of 1 second.  (Brian D.
    Burns)

  * Exit gently on SIGINT by sending SIGTERM to all worker processes and then
    running waitall(), instead of sending SIGKILL to the entire process group.
    As a result, test-loop no longer exits with a non-zero status upon SIGINT.

  * Remove 'ansi' gem dependency.  (Brian D. Burns)

Other:

  * Add tip on deleting logs for passing tests.  (Brian D. Burns)

  * Add tip on monitoring test processes with watch(1) in README.

## Version 9.2.0 (2011-03-28)

  * Extract Rails-specific configuration to 'test/loop/rails' sublibrary.

  * Add 'test/loop/notify' sublibrary for OSD notifications on failures.

## Version 9.1.1 (2011-03-15)

  * $0 does not work from RubyGems wrapper executable.
    Thanks to Brian D. Burns for reporting this issue.

  * Add information about sqlite3 errors & workaround in README.

## Version 9.1.0 (2011-02-23)

  * Print the status of completed tests in ANSI color.

  * Print the failure log of failing tests to STDERR.

  * `$?` is not defined when Errno::ECHILD is raised.

## Version 9.0.1 (2011-02-18)

  * Shield normal output from control-key combos printed into the terminal.

  * Do not print worker PID in status messages because every test file has
    exactly one worker anyway.

  * Reabsorb on any `*.{rb,yml}` changes beneath the `config/` directory.

  * Do not reabsorb overhead when the configuration file changes.

  * Add `after_each_test` example for failure-only notifications.

## Version 9.0.0 (2011-02-15)

  * Remove SIGUSR1 for killing worker processes.

  * Handle Ctrl-Z signal from the very beginning.

## Version 8.0.0 (2011-02-12)

  * Move configuration into `Test::Loop` object itself.

  * Allow loading `bin/test-loop` into IRB for testing.

  * Simplify initialization of default configuration.

  * Revise README: delete needless cruft; add examples.

  * Add example on extending `before_each_test` function.

  * DRY `sleep 1` commands into higher order function.

  * Accept > 80 character lines in some cases.

  * Freeze more constant values against modification.

## Version 7.0.1 (2011-02-10)

  * Fix minitest deadlock issues with I/O redirection.

  * Do not signal to restart loop when overhead changes.

## Version 7.0.0 (2011-02-10)

  * Switch from shell-script style to modular Ruby style in the source code.
    This yields more lines of code, but the result is much easier to read.

    * Replace the `$test_loop_config` global variable with the
      `Test::Loop::Config` constant.

  * Do not wait for all test runs to finish before detecting more changes.

    * Replace the `after_all_tests` parameter with `after_each_test`.

  * Capture test run output into separate log files; one log per test file.

    * The `before_each_test` function is now passed the path to a log file.

  * Register signal handlers at the earliest and act upon signals immediately.

    * Previously, SIGQUIT did not work if there were no test helpers.

  * Send the SIGUSR1 signal to terminate workers and their subprocesses.

  * Break long lines at 80 characters in the source code.

## Version 6.0.0 (2011-02-09)

  * Only consider `{test,spec}_helper.rb` as overhead, not all `*_helper.rb`.

  * Give the user freedom to inspect and change the default configuration by
    storing it in a `$test_loop_config` global variable instead of returning
    the user's desired configuration as a hash from the user's configuration
    file.

  * Change the method signature of the `after_all_tests` lambda function.

  * Add support for growl and xmessage in the `after_all_tests` example.

  * Add note about disabling class caching in Rails test environment.

  * Add better explanation for the `test_file_matchers` example.

## Version 5.0.3 (2011-01-25)

  * Use "diff/lcs" library instead of "diff" for RSpec compatibility.

    Thanks to millisami for reporting this bug:
    https://github.com/sunaku/test-loop/issues/3

  * Terminate worker processes when user presses Control-C.

  * Reabsorb when bundler is run, not when Gemfile changes.

## Version 5.0.2 (2011-01-19)

  * Support string interpolations that yield empty strings in test names.

  * Accept extra characters before test name in test definition:
    * Whitespace between `def` and `test_` in traditional test methods.
    * Opening parenthesis between test name and test definition keyword.

  * Mention that diff gem is necessary for manual git clone installation.

## Version 5.0.1 (2011-01-18)

  * Sanitize string interpolation in parsed test names.

  * Remove useless use of #map; result is not reused.

  * Mention parallelism and revise the introduction.

  * DRY the mentioning of .test-loop file in README.

## Version 5.0.0 (2011-01-17)

  * The configuration file must now yield a Ruby
    hash instead of polluting the global Object
    private environment with instance variables.

  * Shortened the `:source_file_glob_to_test_file_mapping`
    configuration parameter name to `:test_file_matchers`.

## Version 4.0.1 (2011-01-14)

  * Print how much time it took to run all tests.

  * Do not print test file before loading because it
    is hard to follow parallel test execution anyway.

  * Print rescued top-level exceptions to STDERR.

  * Strip surrounding spaces from parsed test names.

  * Use long options when passing test names in ARGV.

  * Only prepend lib/, test/, and spec/ to $LOAD_PATH.

## Version 4.0.0 (2011-01-13)

  * Only run changed tests inside changed test files.

  * Run tests in parallel: one worker per test file.

  * Print the status of each test file after execution.

  * Rename `@after_test_execution` to `@after_all_tests`
    and change its function signature.

  * Clean up implementation and improve documentation.

## Version 3.0.2 (2011-01-11)

  * Reabsorb overhead upon Gemfile changes (Rails 3).

  * Try to recover from all kinds of exceptions.

## Version 3.0.1 (2011-01-05)

  * Be resilient to $0 and ARGV being changed by tests.

  * Reduce pollution by making `notify()` into lambda.

  * Beautify markdown formatting and revise the README.

## Version 3.0.0 (2011-01-04)

  * Replace Rake pathmap usage with lambda functions
    in the `@source_file_to_test_file_mapping` hash.

  * Be resilient to syntax errors from loaded files.

## Version 2.0.2 (2011-01-02)

  * Do not print stack trace when Control-C pressed.

  * Reduce the amount of notifications shown to user.

## Version 2.0.1 (2011-01-01)

  * Fix syntax error caused by a dangling comma. Thanks
    to darthdeus (Jakub Arnold) for reporting [this bug](
    https://github.com/sunaku/test-loop/issues#issue/1 ).

  * Notify user before reabsorbing overhead.

## Version 2.0.0 (2010-12-31)

  * Add support for loading configuration file, which
    allows you to define additional test file globs
    and mappings, from the current working directory.

  * Add support for executing arbitrary logic after every test run
    via the `@after_test_execution` hook in the configuration file.

  * Before running tests, print out their file paths.

  * Automatically retry when overhead absorption fails.

## Version 1.2.0 (2010-11-23)

  * Notify user when absorbing overhead initially.

  * DRY up the repetition of Time.at(0) calculation.

## Version 1.1.0 (2010-11-22)

  * All `*_{test,spec}_helper.rb` files inside `test/` and
    `spec/` are now considered to be absorable overhead.

## Version 1.0.2 (2010-10-16)

  * All *_helper.rb files inside test/ and spec/
    were absorbed as overhead instead of just
    the test_helper.rb and spec_helper.rb files.

## Version 1.0.1 (2010-10-16)

  * Ensure that $LOAD_PATH reflects `ruby -Ilib:test`.

## Version 1.0.0 (2010-10-15)

  * Remove ability to install as a Rails plugin.

  * Move logic from `lib/` into `bin/` to keep it simple.

  * Rely on $LOAD_PATH in `bin/` instead of relative paths.

  * Display status messages for better user interactivity.

## Version 0.0.2 (2010-10-11)

  * Forgot to register `bin/test-loop` as gem executable.

  * Revise Usage section into Invocation and Operation.

## Version 0.0.1 (2010-10-10)

  * First public release.  Enjoy!
