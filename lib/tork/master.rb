require 'tork/server'
require 'tork/config'

module Tork
class Master < Server

  # detect the number of CPUs available in the system
  # http://stackoverflow.com/questions/891537#6420817
  MAX_CONCURRENT_WORKERS = [
    'fgrep -c processor /proc/cpuinfo', # Linux
    'sysctl -n hw.ncpu',                # BSD
    'hwprefs cpu_count',                # Darwin 9
    'hwprefs thread_count',             # Darwin 10
  ].
  map {|cmd| `#{cmd} 2>/dev/null`.to_i }.push(1).max

  def initialize
    super
    Tork.config :master
    send @clients, [:boot]

    @worker_number_pool = (0 ... MAX_CONCURRENT_WORKERS).to_a
    @command_by_worker_pid = {}
  end

  def loop
    super
  ensure
    stop :SIGKILL
  end

  def test test_file, line_numbers
    # throttle forking rate to meet the maximum concurrent workers limit
    sleep 1 until @command_by_worker_pid.size <= @worker_number_pool.size

    $tork_test_file = test_file
    $tork_line_numbers = line_numbers
    $tork_log_file = $tork_test_file + '.log'
    $tork_worker_number = @worker_number_pool.shift
    Tork.config :onfork

    worker_pid = fork do
      # make the process title Test::Unit friendly and ps(1) searchable
      $0 = "tork-worker[#{$tork_worker_number}] #{$tork_test_file}"

      # detach worker process from master process' group for kill -pgrp
      Process.setsid

      # detach worker process from master process' standard input stream
      STDIN.reopen IO.pipe.first

      # capture test output in log file because tests are run in parallel
      # which makes it difficult to understand interleaved output thereof
      STDERR.reopen(STDOUT.reopen($tork_log_file, 'w')).sync = true

      Tork.config :worker

      # after loading the user's test file, the at_exit() hook of the user's
      # testing framework will take care of running the tests and reflecting
      # any failures in the worker process' exit status, which will then be
      # handled by the reaping thread registered in the master process (below)
      Kernel.load $tork_test_file if $tork_test_file.end_with? '.rb'
    end

    @command.push $tork_log_file, $tork_worker_number
    @command_by_worker_pid[worker_pid] = @command
    send @clients, @command

    # wait for the worker to finish and report its status to the client
    Thread.new(worker_pid) do |pid| # the reaping thread
      status = Process.wait2(pid).last
      command = @command_by_worker_pid.delete(pid)
      @worker_number_pool.push command.last
      command[0] = status.success? && :pass || :fail
      send @clients, command.push(status.to_i, status.inspect)
    end
  end

  def stop signal=:SIGTERM
    # the reaping threads registered above will reap these killed workers
    Process.kill signal, *@command_by_worker_pid.keys.map {|pid| -pid }
  rescue ArgumentError, SystemCallError
    # some workers might have already exited before we sent them the signal
  end

end
end

# monkeypatch at_exit to fix RSpec and MiniTest
# https://github.com/rspec/rspec-core/pull/720
# https://github.com/seattlerb/minitest/pull/183
module Kernel
  alias _d20922b4_a7b3_48d6_ad66_3d23e7310cf0 at_exit
  def at_exit &block
    _d20922b4_a7b3_48d6_ad66_3d23e7310cf0 do
      # prevent SystemExit from inhibiting testing libraries' autorun helpers:
      # RSpec and MiniTest don't run any tests if $! is present during at_exit
      if $! and $!.kind_of? SystemExit
        begin
          cleared_exit = $!
          $! = nil # works in Ruby 1.8; raises NameError in Ruby 1.9
        rescue NameError
          # $! becomes nil after this rescue block ends in Ruby 1.9
        end
        raise NotImplementedError, 'tork/master: could not clear $!' if $!
      end

      block.call

      # if calling the block didn't raise any exceptions, then restore the
      # SystemExit exception that we cleared away above (if there was any)
      raise cleared_exit if cleared_exit
    end
  end
end
