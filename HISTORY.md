Version 4.0.0 (2011-01-13)
==========================

* Only run changed tests inside changed test files.

* Run tests in parallel: one worker per test file.

* Print the status of each test file after execution.

* Rename `@after_test_execution` to `@after_all_tests`
  and change its function signature.

* Clean up implementation and improve documentation.

Version 3.0.2 (2011-01-11)
==========================

* Reabsorb overhead upon Gemfile changes (Rails 3).

* Try to recover from all kinds of exceptions.

Version 3.0.1 (2011-01-05)
==========================

* Be resilient to $0 and ARGV being changed by tests.

* Reduce pollution by making `notify()` into lambda.

* Beautify markdown formatting and revise the README.

Version 3.0.0 (2011-01-04)
==========================

* Replace Rake #pathmap usage with lambda functions
  in the `@source_file_to_test_file_mapping` hash.

* Be resilient to syntax errors from loaded files.

Version 2.0.2 (2011-01-02)
==========================

* Do not print stack trace when Control-C pressed.

* Reduce the amount of notifications shown to user.

Version 2.0.1 (2011-01-01)
==========================

* Fix syntax error caused by a dangling comma. Thanks
  to darthdeus (Jakub Arnold) for reporting [this bug](
  https://github.com/sunaku/test-loop/issues#issue/1 ).

* Notify user before reabsorbing overhead.

Version 2.0.0 (2010-12-31)
==========================

* Add support for loading configuration file, which
  allows you to define additional test file globs
  and mappings, from the current working directory.

* Add support for executing arbitrary logic after every test run
  via the `@after_test_execution` hook in the configuration file.

* Before running tests, print out their file paths.

* Automatically retry when overhead absorption fails.

Version 1.2.0 (2010-11-23)
==========================

* Notify user when absorbing overhead initially.

* DRY up the repetiton of Time.at(0) calculation.

Version 1.1.0 (2010-11-22)
==========================

* All *_{test,spec}_helper.rb files inside test/ and
  spec/ are now considered to be absorable overhead.

Version 1.0.2 (2010-10-16)
==========================

* All *_helper.rb files inside test/ and spec/
  were absorbed as overhead instead of just
  the test_helper.rb and spec_helper.rb files.

Version 1.0.1 (2010-10-16)
==========================

* Ensure that $LOAD_PATH reflects `ruby -Ilib:test`.

Version 1.0.0 (2010-10-15)
==========================

* Remove ability to install as a Rails plugin.

* Move logic from lib/ into bin/ to keep it simple.

* Rely on $LOAD_PATH in bin/ instead of relative paths.

* Display status messages for better user interactivity.


Version 0.0.2 (2010-10-11)
==========================

* Forgot to register bin/test-loop as gem executable.

* Revise Usage section into Invocation and Operation.


Version 0.0.1 (2010-10-10)
==========================

* First public release.  Enjoy!
