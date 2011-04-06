------------------------------------------------------------------------------
Version 10.0.0 (2011-04-06)
------------------------------------------------------------------------------

Incompatible changes:

* The `Test::Loop.before_each_test` and `Test::Loop.after_each_test`
  parameters are arrays now.

------------------------------------------------------------------------------
Version 9.4.0 (2011-04-06)
------------------------------------------------------------------------------

New features:

* Allow lambda functions in `Test::Loop.test_file_matchers` to return `nil` so
  that you can exclude certain tests from being executed. (Brian Burns)

* Prefix worker process title with "test-loop" for easier ps(1) searchability.
  The monitoring command in the README is now simplified to the following:

      watch 'ps xf | grep test-loop | sed 1,3d'

Bug fixes:

* Skip `at_exit()` when exiting master process.  This prevents an empty test
  from being run when exiting the loop after having processed a test/spec
  helper that loads the Test::Unit library. (Brian Burns)

Housekeeping:

* Use throw/catch to break loop instead of raising SystemExit exception.

* Trap SIGTERM with IGNORE/DEFAULT instead of using a closure in master.

* Unregister master's custom signal handlers inside worker processes.

* Separate configuration parameters into subsections in README.

------------------------------------------------------------------------------
Version 9.3.0 (2011-04-01)
------------------------------------------------------------------------------

New features:

* Resume currently running tests--as well as those currently needing to be
  run--after reabsorbing test execution overhead. (Brian Burns)

* Stop currently running tests (and wait for them to finish) before
  reabsorbing overhead.  This greatly improves responsiveness because worker
  processes are no longer there to compete with the new master process for
  system resources.

* Notify user when running all tests and when exiting. (Brian Burns)

* Notify user when overhead changes instead of when restarting the loop.

* Use ANSI clear line command to erase control-key combinations outputted by
  shells such as BASH and ZSH in test-loop's output. (Brian Burns)

Bug fixes:

* `@last_ran_at` was being set during every iteration of the loop.  This is
  problematic when Ruby's `Time.now` is more precise than your filesystem's
  modification timestamp.  For example, in the ext3 filesystem under Linux,
  file modification timestamps have a precision of 1 second.  (Brian Burns)

* Exit gently on SIGINT by sending SIGTERM to all worker processes and then
  running waitall(), instead of sending SIGKILL to the entire process group.
  As a result, test-loop no longer exits with a non-zero status upon SIGINT.

* Remove 'ansi' gem dependency. (Brian Burns)

Documentation:

* Add tip on deleting logs for passing tests. (Brian Burns)

* Add tip on monitoring test processes with watch(1) in README.

------------------------------------------------------------------------------
Version 9.2.0 (2011-03-28)
------------------------------------------------------------------------------

* Extract Rails-specific configuration to 'test/loop/rails' sublibrary.

* Add 'test/loop/notify' sublibrary for OSD notifications on failures.

------------------------------------------------------------------------------
Version 9.1.1 (2011-03-15)
------------------------------------------------------------------------------

* $0 does not work from RubyGems wrapper executable.
  Thanks to Brian Burns for reporting this issue.

* Add information about sqlite3 errors & workaround in README.

------------------------------------------------------------------------------
Version 9.1.0 (2011-02-23)
------------------------------------------------------------------------------

* Print the status of completed tests in ANSI color.

* Print the failure log of failing tests to STDERR.

* `$?` is not defined when Errno::ECHILD is raised.

------------------------------------------------------------------------------
Version 9.0.1 (2011-02-18)
------------------------------------------------------------------------------

* Shield normal output from control-key combos printed into the terminal.

* Do not print worker PID in status messages because every test file has
  exactly one worker anyway.

* Reabsorb on any `*.{rb,yml}` changes beneath the config/ directory.

* Do not reabsorb overhead when the configuration file changes.

* Add `after_each_test` example for failure-only notifications.

------------------------------------------------------------------------------
Version 9.0.0 (2011-02-15)
------------------------------------------------------------------------------

* Remove SIGUSR1 for killing worker processes.

* Handle Ctrl-Z signal from the very beginning.

------------------------------------------------------------------------------
Version 8.0.0 (2011-02-12)
------------------------------------------------------------------------------

* Move configuration into `Test::Loop` object itself.

* Allow loading `bin/test-loop` into IRB for testing.

* Simplify initialization of default configuration.

* Revise README: delete needless cruft; add examples.

* Add example on extending `before_each_test` function.

* DRY `sleep 1` commands into higher order function.

* Accept > 80 character lines in some cases.

* Freeze more constant values against modification.

------------------------------------------------------------------------------
Version 7.0.1 (2011-02-10)
------------------------------------------------------------------------------

* Fix minitest deadlock issues with I/O redirection.

* Do not signal to restart loop when overhead changes.

------------------------------------------------------------------------------
Version 7.0.0 (2011-02-10)
------------------------------------------------------------------------------

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

------------------------------------------------------------------------------
Version 6.0.0 (2011-02-09)
------------------------------------------------------------------------------

* Only consider `{test,spec}_helper.rb` as overhead, not all `*_helper.rb`.

* Give the user freedom to inspect and change the default configuration by
  storing it in a `$test_loop_config` global variable instead of returning the
  user's desired configuration as a hash from the user's configuration file.

* Change the method signature of the `after_all_tests` lambda function.

* Add support for growl and xmessage in the `after_all_tests` example.

* Add note about disabling class caching in Rails test environment.

* Add better explanation for the `test_file_matchers` example.

------------------------------------------------------------------------------
Version 5.0.3 (2011-01-25)
------------------------------------------------------------------------------

* Use "diff/lcs" library instead of "diff" for RSpec compatibility.

  Thanks to millisami for reporting this bug:
  https://github.com/sunaku/test-loop/issues/3

* Terminate worker processes when user presses Control-C.

* Reabsorb when bundler is run, not when Gemfile changes.

------------------------------------------------------------------------------
Version 5.0.2 (2011-01-19)
------------------------------------------------------------------------------

* Support string interpolations that yield empty strings in test names.

* Accept extra characters before test name in test definition:
  * Whitespace between `def` and `test_` in traditional test methods.
  * Opening parenthesis between test name and test definition keyword.

* Mention that diff gem is necessary for manual git clone installation.

------------------------------------------------------------------------------
Version 5.0.1 (2011-01-18)
------------------------------------------------------------------------------

* Sanitize string interpolation in parsed test names.

* Remove useless use of #map; result is not reused.

* Mention parallelism and revise the introduction.

* DRY the mentioning of .test-loop file in README.

------------------------------------------------------------------------------
Version 5.0.0 (2011-01-17)
------------------------------------------------------------------------------

* The configuration file must now yield a Ruby
  hash instead of polluting the global Object
  private environment with instance variables.

* Shortened the `:source_file_glob_to_test_file_mapping`
  configuration parameter name to `:test_file_matchers`.

------------------------------------------------------------------------------
Version 4.0.1 (2011-01-14)
------------------------------------------------------------------------------

* Print how much time it took to run all tests.

* Do not print test file before loading because it
  is hard to follow parallel test execution anyway.

* Print rescued top-level exceptions to STDERR.

* Strip surrounding spaces from parsed test names.

* Use long options when passing test names in ARGV.

* Only prepend lib/, test/, and spec/ to $LOAD_PATH.

------------------------------------------------------------------------------
Version 4.0.0 (2011-01-13)
------------------------------------------------------------------------------

* Only run changed tests inside changed test files.

* Run tests in parallel: one worker per test file.

* Print the status of each test file after execution.

* Rename `@after_test_execution` to `@after_all_tests`
  and change its function signature.

* Clean up implementation and improve documentation.

------------------------------------------------------------------------------
Version 3.0.2 (2011-01-11)
------------------------------------------------------------------------------

* Reabsorb overhead upon Gemfile changes (Rails 3).

* Try to recover from all kinds of exceptions.

------------------------------------------------------------------------------
Version 3.0.1 (2011-01-05)
------------------------------------------------------------------------------

* Be resilient to $0 and ARGV being changed by tests.

* Reduce pollution by making `notify()` into lambda.

* Beautify markdown formatting and revise the README.

------------------------------------------------------------------------------
Version 3.0.0 (2011-01-04)
------------------------------------------------------------------------------

* Replace Rake #pathmap usage with lambda functions
  in the `@source_file_to_test_file_mapping` hash.

* Be resilient to syntax errors from loaded files.

------------------------------------------------------------------------------
Version 2.0.2 (2011-01-02)
------------------------------------------------------------------------------

* Do not print stack trace when Control-C pressed.

* Reduce the amount of notifications shown to user.

------------------------------------------------------------------------------
Version 2.0.1 (2011-01-01)
------------------------------------------------------------------------------

* Fix syntax error caused by a dangling comma. Thanks
  to darthdeus (Jakub Arnold) for reporting [this bug](
  https://github.com/sunaku/test-loop/issues#issue/1 ).

* Notify user before reabsorbing overhead.

------------------------------------------------------------------------------
Version 2.0.0 (2010-12-31)
------------------------------------------------------------------------------

* Add support for loading configuration file, which
  allows you to define additional test file globs
  and mappings, from the current working directory.

* Add support for executing arbitrary logic after every test run
  via the `@after_test_execution` hook in the configuration file.

* Before running tests, print out their file paths.

* Automatically retry when overhead absorption fails.

------------------------------------------------------------------------------
Version 1.2.0 (2010-11-23)
------------------------------------------------------------------------------

* Notify user when absorbing overhead initially.

* DRY up the repetiton of Time.at(0) calculation.

------------------------------------------------------------------------------
Version 1.1.0 (2010-11-22)
------------------------------------------------------------------------------

* All *_{test,spec}_helper.rb files inside test/ and
  spec/ are now considered to be absorable overhead.

------------------------------------------------------------------------------
Version 1.0.2 (2010-10-16)
------------------------------------------------------------------------------

* All *_helper.rb files inside test/ and spec/
  were absorbed as overhead instead of just
  the test_helper.rb and spec_helper.rb files.

------------------------------------------------------------------------------
Version 1.0.1 (2010-10-16)
------------------------------------------------------------------------------

* Ensure that $LOAD_PATH reflects `ruby -Ilib:test`.

------------------------------------------------------------------------------
Version 1.0.0 (2010-10-15)
------------------------------------------------------------------------------

* Remove ability to install as a Rails plugin.

* Move logic from lib/ into bin/ to keep it simple.

* Rely on $LOAD_PATH in bin/ instead of relative paths.

* Display status messages for better user interactivity.

------------------------------------------------------------------------------
Version 0.0.2 (2010-10-11)
------------------------------------------------------------------------------

* Forgot to register bin/test-loop as gem executable.

* Revise Usage section into Invocation and Operation.

------------------------------------------------------------------------------
Version 0.0.1 (2010-10-10)
------------------------------------------------------------------------------

* First public release.  Enjoy!
