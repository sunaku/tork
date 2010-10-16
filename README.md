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


License
-------

See the LICENSE file for details.
