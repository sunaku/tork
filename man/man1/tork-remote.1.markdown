# TORK-REMOTE 1 2012-09-26 18.2.3

## NAME

tork-remote - controls tork(1) programs

## SYNOPSIS

`tork-remote` [*OPTION*]... *PROGRAM*

## DESCRIPTION

This program sends single-line JSON messages read from its stdin to the given
*PROGRAM* which is already running in the same working directory as this one.

If lines read from stdin are not single-line JSON messages, then they are
split into an array of words, using the same word-splitting algorithm as
sh(1), before being sent to the *PROGRAM* as a single-line JSON message.

If the *PROGRAM* sends any messages in response, then they are printed to
stdout if they are valid single-line JSON messages or to stderr otherwise.

## OPTIONS

`-h`, `--help`
  Show this help manual.

## EXIT STATUS

1
  Could not connect to the *PROGRAM*.

2
  Lost connection to the *PROGRAM*.

## SEE ALSO

tork(1), tork-driver(1), tork-engine(1), tork-master(1)