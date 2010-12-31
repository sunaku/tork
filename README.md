test-loop - Continuous testing for Ruby with fork/eval
======================================================

test-loop is a fast continuous testing tool for Ruby that continuously detects
and tests changes in your Ruby application in an efficient manner, whereby it:

1. Absorbs the test execution overhead into the main Ruby process.
2. Forks to evaluate your test files directly and without overhead.

It relies on file modification times to determine what parts of your Ruby
application have changed and then uses Rake's `String#pathmap` function to
determine which test files in your test suite correspond to those changes.


Features
--------

* Tests CHANGES in your Ruby application; does NOT run all tests every time.

* Reabsorbs test execution overhead if the test or spec helper file changes.

* Mostly I/O bound, so you can have it always running without CPU slowdowns.

* Supports Test::Unit, RSpec, or any other testing framework that is utilized
  by your application's `test/test_helper.rb` and `spec/spec_helper.rb` files.

* Implemented in less than 40 (SLOC) lines of code! :-)


Installation
------------

As a Ruby gem:

    gem install test-loop

As a Git clone:

    git clone git://github.com/sunaku/test-loop


Invocation
----------

If installed as a Ruby gem:

    test-loop

If installed as a Git clone:

    ruby bin/test-loop


Operation
---------

* Press Control-Z (or send the SIGTSTP signal) to forcibly run all
  tests, even if there are no changes in your Ruby application.

* Press Control-\ (or send the SIGQUIT signal) to forcibly reabsorb
  the test execution overhead, even if its sources have not changed.

* Press Control-C (or send the SIGINT signal) to quit the test loop.


Configuration
-------------

test-loop looks for a configuration file named `test-loop.conf` in its working
directory.  This configuration file is a normal Ruby script which can define
the following instance variables:

* `@overhead_file_globs` is an array of file globbing patterns that describe a
  set of Ruby scripts that are loaded into the main Ruby process as overhead.

* `@reabsorb_file_globs` is an array of file globbing patterns that describe a
  set of files which cause the overhead to be reabsorbed whenever they change.

* `@source_file_to_test_file_mapping` is a hash that maps a file globbing
  pattern describing a set of source files to a [Rake pathmap expression](
  http://rake.rubyforge.org/classes/String.html#M000017 ) yielding a file
  globbing pattern describing a set of test files that need to be run.  In
  other words, whenever the source files (the hash key; left-hand side of the
  mapping) change, their associated test files (the hash value; right-hand
  side of the mapping) are run.

* `@after_test_execution` is a proc/lambda object that is executed after tests
  are run.  It is passed three things: the status of the test execution
  subprocess, the time when the tests were run, and the list of test files
  that were run.

  For example, to get on-screen-display notifications through libnotify,
  add the following to your `test-loop.conf` file:

      @after_test_execution = lambda do |status, ran_at, files|
        if status.success?
          result, icon = 'PASS', 'apple-green'
        else
          result, icon = 'FAIL', 'apple-red'
        end
        system 'notify-send', '-i', icon, "#{result} at #{ran_at}", files.join("\n")
      end


License
-------

See the `bin/test-loop` file.
