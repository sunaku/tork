test:loop - continuous testing with fork/eval
=============================================

test:loop is a Rake task that continously tests changes in your Ruby
application in an efficient manner, using a fork/eval approach that:

1. Absorbs the test execution overhead into the main Rake process.
2. Forks to evaluate your test files directly and without overhead.

It relies on file modification times to determine what parts of your Ruby
application have changed and then uses Rake's String#pathmap function to
determine which test files in your test suite correspond to those changes.


Features
--------

* Tests CHANGES in your Ruby application; does NOT run all tests every time.

* Supports Test::Unit, RSpec, or any other testing framework that is utilized
  by your application's `test/test_helper.rb` and `spec/spec_helper.rb` files.

* Reabsorbs test execution overhead if the test or spec helper file changes.

* Mostly I/O bound, so you can have it always running without CPU slowdowns.

* Composed of just 35 (SLOC) lines of code! :-)


Install
-------

As a Ruby on Rails plugin:

    rails plugin install git://github.com/sunaku/test-loop  # Rails >= 3
    script/plugin install git://github.com/sunaku/test-loop # older Rails

As a regular Ruby library, download the `lib/tasks/test:loop.rake` file and
require it into your Rakefile or use it directly by passing it to `rake -f`.


Usage
-----

rake test:loop

* Pass "RUN=1" as a command-line argument
  to run all tests initially, even if there
  are no changes in your Ruby application.

* To stop the task after it has begun running,
  press Control-C or kill the process manually.


License
-------

See the LICENSE file for details.
