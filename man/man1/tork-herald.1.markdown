# TORK-HERALD 1 2014-10-26 20.0.0

## NAME

tork-herald - reports modified files

## SYNOPSIS

`tork-herald` [*OPTION*]...

## DESCRIPTION

This program monitors the current working directory and all those below it
recursively.  When any files therein are modified, it prints their relative
paths in a single-line JSON array to stdout.

## OPTIONS

`-h` [*PATTERN*], `--help` [*PATTERN*]
  Show this help manual and search for *PATTERN* regular expression therein.

## SEE ALSO

tork(1), tork-driver(1)