# TORK-RUNNER 1 2014-01-02 19.6.0

## NAME

tork-runner - runs tests once, non-interactively

## SYNOPSIS

`tork-runner` [*OPTION*]... [*TEST\_FILE\_GLOB*]...

## DESCRIPTION

This program can be thought of as a non-interactive version of tork(1).  It
runs all test files that match the given *TEST\_FILE\_GLOB*s and then exits
with a nonzero status if any tests failed.  If none are given, it runs all
test files known to `Tork::Driver::TEST_FILE_GLOBBERS` in tork-driver(1).

### Output

This program prints the following messages to stdout.

`>>` *failed\_test\_log\_file* `<<`
  This message will be followed by the content of *failed\_test\_log\_file*.

*T* `tested,` *P* `passed,` *F* `failed`
  *T* test files were tested and *P* of them passed but *F* of them failed.

This program prints the following messages to stderr if it is a TTY device.

`tork-runner:` *NN.N*`% tested`
  *NN.N* percent of test files were tested so far.

## OPTIONS

`-h`, `--help`
  Show this help manual.

## EXIT STATUS

0
  All test files passed.

1
  One or more test files failed.

## ENVIRONMENT

See tork(1).

## SEE ALSO

tork(1), tork-driver(1)