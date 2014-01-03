# TORK 1 2014-01-02 19.6.0

## NAME

tork - Continuous testing tool for Ruby

## SYNOPSIS

`tork` [*OPTION*]... [*CONFIG*]...

## DESCRIPTION

This program can be thought of as an interactive version of tork-runner(1).
It functions as a rudimentary command-line user interface to tork-driver(1).

First, it applies the given *CONFIG* values, which are either (1) paths to
directories that contain configuration files or (2) names of configuration
helpers listed in the description of the `TORK_CONFIGS` environment variable.

Next, it waits for you to supply interactive commands either (1) directly on
its stdin or (2) remotely through tork-remote(1).  From then onward, type `h`
and press ENTER to see a help message that shows a menu of accepted commands.

Some interactive commands accept additional arguments, described as follows.

`t` *test_file* [*line_number*]...
  Runs the given *test_file* while only running those tests that are defined
  on the given list of *line_number*s.  If no *line_number*s are given, then
  only those tests that have changed since the last run of the *test_file*
  will now be run.

`s` [*signal*]
  Stops test files that are currently running by sending the given *signal*
  (optional; defaults to `SIGTERM`) to their respective worker processes.

This program can be controlled remotely by multiple tork-remote(1) instances.

## OPTIONS

`-h`, `--help`
  Show this help manual.

## FILES

*.tork/config.rb*
  Optional Ruby script that is loaded inside the driver process on startup.
  It can read and change the `ENV['TORK_CONFIGS']` environment variable.

## ENVIRONMENT

`TORK_CONFIGS`
  Colon-separated (:) list of either paths to directories that contain
  configuration files or names of the following configuration helpers.
  If this variable is not set, then its value is assumed to be "default".

  > `default`
  >   Loads the following configuration helpers (as appropriate) if your
  >   current working directory appears to utilize what they configure.
  >   See below for complete descriptions of these configuration helpers.
  >
  >   * rails
  >   * devise
  >   * test
  >   * spec
  >   * cucumber
  >   * factory_girl
  >
  > `dotlog`
  >   Hides log files by prefixing their names with a period (dot).
  >
  > `logdir`
  >   Keeps log files away from your tests, in the `log/` directory.
  >
  > `coverage`
  >   Measures C0 code coverage under Ruby 1.9 and dumps a hash in YAML
  >   format at the end of your log file containing every Ruby script that
  >   was loaded from the current working directory or any of its descendant
  >   directories (the key) mapped to the following information (the value):
  >
  > > `:grade`
  > >   Percentage of source lines that were C0 covered.
  > >
  > > `:nsloc`
  > >   Total number of source lines of code in the file.
  > >
  > > `:holes`
  > >   Line numbers of source lines that were not covered.
  >
  > `test`
  >   Supports the Test::Unit standard library.
  >
  > `spec`
  >   Supports the [RSpec] testing framework.
  >
  > `cucumber`
  >   Supports the [Cucumber] testing framework.
  >
  > `rails`
  >   Supports the [Ruby on Rails] web framework.
  >
  > `devise`
  >   Supports the [Devise] authentication framework.
  >
  > `factory_girl`
  >   Supports the [factory_girl] testing library.
  >
  > `parallel_tests`
  >   Supports the [parallel_tests] testing library.

## SEE ALSO

tork-runner(1), tork-driver(1), tork-master(1)

[factory_girl]: https://github.com/thoughtbot/factory_girl
[memory_test_fix]: https://github.com/stepahn/memory_test_fix
[parallel_tests]: https://github.com/grosser/parallel_tests
[Ruby on Rails]: http://rubyonrails.org
[Cucumber]: https://cukes.info
[RSpec]: http://rspec.info
[Devise]: https://github.com/plataformatec/devise