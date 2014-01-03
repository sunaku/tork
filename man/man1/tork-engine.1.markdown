# TORK-ENGINE 1 2014-01-02 19.6.0

## NAME

tork-engine - wraps tork-master(1) with bookkeeping

## SYNOPSIS

`tork-engine` [*OPTION*]...

## DESCRIPTION

This program uses tork-master(1) to run tests and keeps track of the results.

This program can be controlled remotely by multiple tork-remote(1) instances.

### Input

This program reads the following commands, which are single-line JSON arrays,
from stdin and then performs the associated actions.  For lines read from
stdin that are single-line JSON arrays, it splits each of them into an array
of words, using the same word-splitting algorithm as sh(1), before processing
them.  For example, the line `a "b c"` is split into the `["a", "b c"]` array.

`["reabsorb_overhead"]`
  Stops any test files that are currently running, reabsorbs the test
  execution overhead, and then re-runs those stopped test files.

`["run_test_file"`, *test_file*`,` *line_numbers*...`]`
  Runs tests that correspond to the given sequence of *line_numbers* in the
  given *test_file*.  If no *line_numbers* are given, then only those lines
  that have changed since the last run of *test_file* will be substituted.
  If any *line_numbers* are zero, then the entire *test_file* will be run.

`["run_test_files"`, *test\_files\_with\_optional\_line\_numbers*`]`
  Calls the `run_test_file` command once for each item in the given array.

`["stop_running_test_files"`, *signal*`]`
  Stops test files that are currently running by sending the given *signal*
  (optional; defaults to "SIGTERM") to their respective worker processes.

`["rerun_passed_test_files"]`
  Runs all test files that have passed during their most recent run.

`["rerun_failed_test_files"]`
  Runs all test files that have failed during their most recent run.

`["quit"]`
  Stops all tests that are currently running and exits.

### Output

This program prints the following messages, which are single-line JSON arrays,
to stdout.

`["idle"]`
  All tests have finished running and no tests are queued for running either.

`["pass_now_fail",` *test_file*`,` *message*`]`
  A previously passing *test_file* has now failed.  See *message* for details.

`["fail_now_pass",` *test_file*`,` *message*`]`
  A previously failing *test_file* has now passed.  See *message* for details.

*...*
  Messages from tork-master(1) are also reproduced here.

## OPTIONS

`-h`, `--help`
  Show this help manual.

## FILES

*.tork/config.rb*
  Optional Ruby script that is loaded inside the driver process on startup.
  It can read and change the `ENV['TORK_CONFIGS']` environment variable.

*.tork/engine.rb*
  Optional Ruby script that is loaded inside the master process on startup.

## ENVIRONMENT

See tork(1).

## SEE ALSO

tork(1), tork-remote(1), tork-master(1)