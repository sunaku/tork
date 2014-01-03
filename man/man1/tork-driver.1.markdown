# TORK-DRIVER 1 2014-01-02 19.6.0

## NAME

tork-driver - drives tork-engine(1) when files change

## SYNOPSIS

`tork-driver` [*OPTION*]...

## DESCRIPTION

This program drives tork-engine(1) when tork-herald(1) reports files changes.

This program can be controlled remotely by multiple tork-remote(1) instances.

### Input

This program reads the following commands, which are single-line JSON arrays,
from stdin and then performs the associated actions.  For lines read from
stdin that are single-line JSON arrays, it splits each of them into an array
of words, using the same word-splitting algorithm as sh(1), before processing
them.  For example, the line `a "b c"` is split into the `["a", "b c"]` array.

`["run_all_test_files"]`
  Runs all test files found within and beneath the current working directory.

*...*
  Commands for tork-engine(1) are also accepted here.

### Output

This program prints the following messages, which are single-line JSON arrays,
to stdout.

`["reabsorb",` *overhead_file*`]`
  Test execution overhead is being reabsorbed because *overhead_file* has
  changed.

*...*
  Messages from tork-engine(1) and tork-master(1) are also reproduced here.

## OPTIONS

`-h`, `--help`
  Show this help manual.

## FILES

*.tork/config.rb*
  Optional Ruby script that is loaded inside the driver process on startup.
  It can read and change the `ENV['TORK_CONFIGS']` environment variable.

`.tork/driver.rb`
  Optional Ruby script that is loaded inside the driver process on startup.
  It can read and change the following variables.

  > `Tork::Driver::REABSORB_FILE_GREPS`
  >   Array of strings or regular expressions that match the paths of overhead
  >   files.  If any of these equal or match the path of a changed file
  >   reported by tork-herald(1), then the test execution overhead will be
  >   reabsorbed in tork-master(1).
  >
  > `Tork::Driver::ALL_TEST_FILE_GLOBS`
  >   Array of file globbing patterns that describe the set of all test files
  >   in your Ruby application.
  >
  > `Tork::Driver::TEST_FILE_GLOBBERS`
  >   Hash that maps (1) a regular expression describing a set of file paths
  >   to (2) a lambda function that accepts a `MatchData` object containing
  >   the results of the regular expression matching against the path of a
  >   changed file, and yields one or more file globbing patterns (a single
  >   string, or an array of strings) that describe a set of test files that
  >   need to be run.
  >
  >   The results of these functions are recursively expanded (fed back into
  >   them) to construct an entire dependency tree of test files that need to
  >   be run.  For instance, if one function returns a glob that yields files
  >   matched by another function, then that second function will be called to
  >   glob more test files.  This process repeats until all dependent test
  >   files have been accounted for.
  >
  > > ***Single glob expansion***
  > >
  > > For example, if test files had the same names as their source files
  > > followed by an underscore and the file name in reverse like this:
  > >
  > >   * lib/hello.rb => test/hello_olleh.rb
  > >   * app/world.rb => spec/world_ldrow.rb
  > >
  > > Then you would add the following to your configuration file:
  > >
  > >     Tork::Driver::TEST_FILE_GLOBBERS.update(
  > >       %r{^(lib|app)/.*?([^/]+?)\.rb$} => lambda do |matches|
  > >         name = matches[2]
  > >         "{test,spec}/**/#{name}_#{name.reverse}.rb"
  > >       end
  > >     )
  > >
  > > ***Multi-glob expansion***
  > >
  > > For example, if test files could optionally have "test" or "spec"
  > > prefixed or appended to their already peculiar names, like so:
  > >
  > >   * lib/hello.rb => test/hello\_olleh\_test.rb
  > >   * lib/hello.rb => test/test\_hello\_olleh.rb
  > >   * app/world.rb => spec/world\_ldrow\_spec.rb
  > >   * app/world.rb => spec/spec\_world\_ldrow.rb
  > >
  > > Then you would add the following to your configuration file:
  > >
  > >     Tork::Driver::TEST_FILE_GLOBBERS.update(
  > >       %r{^(lib|app)/.*?([^/]+?)\.rb$} => lambda do |matches|
  > >         name = matches[2]
  > >         ["{test,spec}/**/#{name}_#{name.reverse}.rb",
  > >          "{test,spec}/**/#{name}_#{name.reverse}_{test,spec}.rb",
  > >          "{test,spec}/**/{test,spec}_#{name}_#{name.reverse}.rb"]
  > >       end
  > >     )
  > >
  > > ***Recursive expansion***
  > >
  > > For example, if you wanted to run test files associated with
  > > `lib/hello.rb` whenever the `app/world.rb` file changed, then you would
  > > write:
  > >
  > >     Tork::Driver::TEST_FILE_GLOBBERS.update(
  > >       %r{^app/world\.rb$} => lambda do |matches|
  > >         'lib/hello.rb'
  > >       end
  > >     )
  > >
  > > This effectively aliases one file onto another, but not in both
  > > directions.
  > >
  > > ***Suppressing expansion***
  > >
  > > These lambda functions can return `nil` if they do not wish for a
  > > particular source file to be tested.  For example, to ignore tests for
  > > all source files except those within a `models/` directory, you would
  > > write:
  > >
  > >     Tork::Driver::TEST_FILE_GLOBBERS.update(
  > >       %r{^(lib|app)(/.*?)([^/]+?)\.rb$} => lambda do |matches|
  > >         if matches[2].include? '/models/'
  > >           ["{test,spec}/**/#{matches[3]}_{test,spec}.rb",
  > >            "{test,spec}/**/{test,spec}_#{matches[3]}.rb"]
  > >         #else     # implied by the Ruby language
  > >           #nil    # implied by the Ruby language
  > >         end
  > >       end
  > >     )

## ENVIRONMENT

See tork(1).

## SEE ALSO

tork(1), tork-remote(1), tork-herald(1), tork-engine(1), tork-master(1)