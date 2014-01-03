# TORK-NOTIFY 1 2014-01-02 19.6.0

## NAME

tork-notify - notifies you of test status changes

## SYNOPSIS

`tork-notify` [*OPTION*]...

## DESCRIPTION

This program serves as an example of how to receive and process messages sent
by the various programs in the tork(1) suite.  It notifies you when previously
passing tests fail (or vice versa) through libnotify, xmessage, or growl.  If
none are available on your system, then the notification is printed to stdout.

## OPTIONS

`-h`, `--help`
  Show this help manual.

## EXIT STATUS

See tork-remote(1).

## SEE ALSO

tork-remote(1), tork-engine(1)