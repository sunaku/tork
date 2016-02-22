# TORK-REMOTE 1 2012-09-26 18.2.3

## NAME

tork-remote - controls tork(1) programs

## SYNOPSIS

`tork-remote` [*OPTION*]... *PROGRAM*

## DESCRIPTION

This program reads lines from its stdin and sends them to the given *PROGRAM*,
which must already be running in the same working directory as this program.
It also prints lines, received in response, from the given *PROGRAM* either
to stdout if they are valid single-line JSON arrays or to stderr otherwise.

## OPTIONS

`-h` [*PATTERN*], `--help` [*PATTERN*]
  Show this help manual and optionally search for *PATTERN* regular expression.

## EXIT STATUS

1
  Could not connect to the *PROGRAM*.

2
  Lost connection to the *PROGRAM*.

## SEE ALSO

tork(1), tork-driver(1), tork-engine(1), tork-master(1)