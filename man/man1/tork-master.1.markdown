# TORK-MASTER 1 2014-01-02 19.6.0

## NAME

tork-master - absorbs overhead and runs tests

## SYNOPSIS

`tork-master` [*OPTION*]...

## DESCRIPTION

This program absorbs your Ruby application's test execution overhead once and
simply fork(3)s worker processses to run your tests thereafter.  As a result,
your tests run faster because they no longer spend any time absorbing the test
execution overhead: worker processes simply inherit the overhead when forked.

This program can be controlled remotely by multiple tork-remote(1) instances.

### Input

This program reads the following commands, which are single-line JSON arrays,
from stdin and then performs the associated actions.  For lines read from
stdin that are single-line JSON arrays, it splits each of them into an array
of words, using the same word-splitting algorithm as sh(1), before processing
them.  For example, the line `a "b c"` is split into the `["a", "b c"]` array.

`["test",` *test_file*`,` *line_numbers*`]`
  Forks a worker process to run tests that correspond to the given
  *line_numbers* in the given *test_file*.  If *line_numbers* is empty, then
  the entire *test_file* will be run.

`["stop",` *signal*`]`
  Stops all tests that are currently running by sending the given *signal*
  (optional; defaults to "SIGTERM") to their respective worker processes.

`["quit"]`
  Stops all tests that are currently running and exits.

### Output

This program prints the following messages, which are single-line JSON arrays,
to stdout.

`["absorb"]`
  Test execution overhead has been absorbed.  We are ready for testing!

`["test",` *test_file*`,` *line_numbers*`,` *log_file*`,` *worker_number*`]`
  Test has begun running.  Its output (both stdout and stderr) is being
  captured into *log_file* in real time, so you can watch it with `tail -f`.

`["pass",` *test_file*`,` *line_numbers*`,` *log_file*`,` *worker_number*`,` *exit_code*`,` *exit_info*`]`
  Test has passed.

`["fail",` *test_file*`,` *line_numbers*`,` *log_file*`,` *worker_number*`,` *exit_code*`,` *exit_info*`]`
  Test has failed.

## OPTIONS

`-h`, `--help`
  Show this help manual.

## FILES

*.tork/config.rb*
  Optional Ruby script that is loaded inside the driver process on startup.
  It can read and change the `ENV['TORK_CONFIGS']` environment variable.

*.tork/master.rb*
  Optional Ruby script that is loaded inside the master process on startup.
  It can read and change the following variables.

  > `Tork::Master::MAX_CONCURRENT_WORKERS`
  >   Maximum number of worker processes that are allowed to be running
  >   simultaneously at any given time.  The default value is either the
  >   number of processors detected on your system or 1 if detection failed.

*.tork/onfork.rb*
  Optional Ruby script that is loaded inside the master process just before a
  worker process is forked.  It can read and change the following variables.

  > `$tork_test_file`
  >   Path of the test file that will be run by the worker process.
  >
  > `$tork_line_numbers`
  >   Array of line numbers in the test file that were requested to be run.
  >
  > `$tork_log_file`
  >   Path of the log file that will hold the output of the worker process.
  >
  > `$tork_worker_number`
  >   Sequence number of the worker process that will be forked shortly.

*.tork/worker.rb*
  Optional Ruby script that is loaded inside a worker process just after
  it is forked.  It can read and change the following variables.

  > `$tork_test_file`
  >   Path of the test file that will be run by this worker process.
  >
  > `$tork_line_numbers`
  >   Array of line numbers in the test file that were requested to be run.
  >
  > `$tork_log_file`
  >   Path of the log file that will hold the output of this worker process.
  >
  > `$tork_worker_number`
  >   Sequence number of this worker process.

## ENVIRONMENT

See tork(1).

## SEE ALSO

tork(1), tork-remote(1)