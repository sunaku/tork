test-loop - Continuous testing for Ruby with fork/eval
======================================================

test-loop is a fast continuous testing tool for Ruby that automatically
detects and tests changes in your application in an efficient manner:

1. Absorbs the test execution overhead into the main Ruby process.
2. Forks to run your test files without overhead and in parallel.
3. Avoids running unchanged test blocks inside changed test files.

It relies on file modification times to determine what parts of your Ruby
application have changed, applies a lambda mapping function to determine which
test files in your test suite correspond to those changes, and uses diffing to
find and run only those test blocks that have changed inside your test files.


> IMPORTANT note for Ruby on Rails users!
> ---------------------------------------
>
> Ensure that your `config/environments/test.rb` file disables class caching:
>
>     config.cache_classes = false
>
> Otherwise, test-loop will appear to ignore class-level changes in your
> models, controllers, etc. and will thereby cause you great frustration!


Features
--------

* Tests *changes* in your Ruby application: avoids running (1) unchanged
  test files and (2) unchanged test blocks inside changed test files.

* Supports Test::Unit, RSpec, and any other testing framework that (1)
  reflects failures in the process' exit status and (2) is loaded by your
  application's `test/test_helper.rb` or `spec/spec_helper.rb` file.

* Reabsorbs test execution overhead if the test or spec helper file changes.

* Executes test files in parallel, making full use of multiple processors.

* Generally I/O bound, so you can have it always running without CPU slowdown.

* Configurable through a `.test-loop` file in your current working directory.

* Implemented in less than 100 lines (SLOC) of pure Ruby code! :-)


Installation
------------

As a Ruby gem:

    gem install test-loop

As a Git clone:

    gem install diff-lcs
    git clone git://github.com/sunaku/test-loop


Invocation
----------

If installed as a Ruby gem:

    test-loop

If installed as a Git clone:

    ruby bin/test-loop


Operation
---------

* Press Control-Z or send the SIGTSTP signal to forcibly run all
  tests, even if there are no changes in your Ruby application.

* Press Control-\ or send the SIGQUIT signal to forcibly reabsorb
  the test execution overhead, even if its sources have not changed.

* Press Control-C or send the SIGINT signal to quit the test loop.


Configuration
-------------

test-loop looks for a configuration file named `.test-loop` in the current
working directory.  This configuration file is a normal Ruby script, in which
you can query and modify the `$test_loop_config` OpenStruct object as follows:

* `$test_loop_config.overhead_file_globs` is an array of file globbing
  patterns that describe a set of Ruby scripts that are loaded into the main
  Ruby process as overhead.

* `$test_loop_config.reabsorb_file_globs` is an array of file globbing
  patterns that describe a set of files which cause the overhead to be
  reabsorbed whenever they change.

* `$test_loop_config.test_file_matchers` is a hash that maps a file globbing
  pattern describing a set of source files to a lambda function yielding a
  file globbing pattern describing a set of test files that need to be run.
  In other words, whenever the source files (the hash key; left-hand side of
  the mapping) change, their associated test files (the hash value; right-hand
  side of the mapping) are run.

  For example, if test files had the same names as their source files but the
  letters were in reverse order like this:

  * lib/hello.rb => test/olleh.rb
  * app/world.rb => spec/ldrow.rb

  Then you would add the following to your configuration file:

      $test_loop_config.test_file_matchers['{lib,app}/**/*.rb'] = lambda do |path|
        extn = File.extname(path)
        name = File.basename(path, extn)
        "{test,spec}/**/#{name.reverse}#{extn}" # <== notice the reverse()
      end

* `$test_loop_config.test_name_parser` is a lambda function that is passed a
  line of source code to determine whether that line can be considered as a
  test definition, in which case it must return the name of the test being
  defined.

* `$test_loop_config.before_each_test` is a lambda function that is executed
  inside the worker process before loading the test file.  It is passed the
  path to the test file and the names of tests (identified by
  `$test_loop_config.test_name_parser`) inside the test file that have changed
  since the last time the test file was run.

  These test names should be passed down to your chosen testing library,
  instructing it to skip all other tests except those passed down to it.  This
  accelerates your test-driven development cycle and improves productivity!

* `$test_loop_config.after_all_tests` is a lambda function that is executed
  inside the master process after all tests have finished running.  It is
  passed four things: whether all tests had passed, the time when test
  execution began, a list of test files, and the exit statuses of the worker
  processes that ran them.

  For example, to display a summary of the test execution results as an OSD
  notification via libnotify, add the following to your configuration file:

      $test_loop_config.after_all_tests = lambda do |success, ran_at, files, statuses|
        icon = success ? 'apple-green' : 'apple-red'
        title = "#{success ? 'PASS' : 'FAIL'} at #{ran_at}"
        details = files.zip(statuses).map do |file, status|
          "#{status.success? ? '✔' : '✘'} #{file}"
        end
        system 'notify-send', '-i', icon, title, details.join("\n")
      end

  Also add the following at the top of the file if you use Ruby 1.9.x:

      # encoding: utf-8

  That will prevent the following errors from occurring:

      invalid multibyte char (US-ASCII)

      syntax error, unexpected $end, expecting ':'
      "#{status.success? ? '✔' : '✘'} #{file}"
                            ^


License
-------

Released under the ISC license.  See the `bin/test-loop` file for details.
