module Tork
# Wrapper for IO.popen() that automatically re-establishes itself
# whenever the child process terminates extraneously, on its own.
class Bridge

  def initialize command
    @command = command
    connect
  end

  def disconnect
    return unless @guardian.alive?

    # prevent guardian from reconnecting bridge while we disconnect it
    @guardian.exit

    # this should be enough to stop programs that use Tork::Server#loop
    # because their IO.select() loop terminates on the closing of STDIN
    @io.close_write

    # but some programs like tork-herald(1) need to be killed explicitly
    # because they do not follow our convention of exiting on STDIN close
    Process.kill :SIGTERM, @io.pid
    Process.waitpid @io.pid

    # this will block until the child process has exited so we must kill it
    # explicitly (as above) to ensure that this program does not hang here
    @io.close_read

  rescue IOError, SystemCallError
    # IOError happens if the child process' pipes are already closed
    # SystemCallError happens if the child process is already dead
  end

  def reconnect
    disconnect
    connect
  end

  # Allows this object to be passed directly
  # into IO.select() and Tork::Server#tell().
  def to_io
    @io
  end

  # Allows this object to be treated as IO.
  def method_missing *args, &block
    @io.__send__ *args, &block
  end

private

  def connect
    @io = IO.popen(@command, 'r+')

    # automatically reconnect the bridge when the child process terminates
    @guardian = Thread.new do
      Process.waitpid @io.pid
      warn "#{$0}: repairing collapsed bridge: #{@command} #{$?}"
      sleep 1 # avoid spamming the CPU by waiting a bit before reconnecting
      connect # no need to disconnect because child process is already dead
    end
  end

end
end
