require 'tork/server'
require 'tork/config'

module Tork
class Master < Server

  # detect the number of CPUs available in the system
  # http://stackoverflow.com/questions/891537#6420817
  MAX_WORKERS = [
    'fgrep -c processor /proc/cpuinfo', # Linux
    'sysctl -n hw.ncpu',                # BSD
    'hwprefs cpu_count',                # Darwin 9
    'hwprefs thread_count',             # Darwin 10
  ].
  map {|cmd| `#{cmd} 2>/dev/null`.to_i }.push(1).max

  def initialize
    Tork.config :master
    super
    @worker_number_pool = (0 ... MAX_WORKERS).to_a
    @command_by_worker_pid = {}
    send [:load]
  end

  def test test_file, line_numbers
    # throttle forking rate to meet the maximum concurrent workers limit
    sleep 1 until @command_by_worker_pid.size < @worker_number_pool.size

    log_file = test_file + '.log'
    worker_number = @worker_number_pool.shift

    $tork_test_file = test_file
    $tork_line_numbers = line_numbers
    $tork_log_file = log_file
    $tork_worker_number = worker_number
    Tork.config :onfork

    worker_pid = fork do
      # make the process title Test::Unit friendly and ps(1) searchable
      $0 = "tork-worker[#{worker_number}] #{test_file}"

      # detach worker process from master process' group for kill -pgrp
      Process.setsid

      # detach worker process from master process' standard input stream
      STDIN.reopen IO.pipe.first

      # capture test output in log file because tests are run in parallel
      # which makes it difficult to understand interleaved output thereof
      STDERR.reopen(STDOUT.reopen(log_file, 'w')).sync = true

      Tork.config :worker

      # after loading the user's test file, the at_exit() hook of the user's
      # testing framework will take care of running the tests and reflecting
      # any failures in the worker process' exit status, which will then be
      # handled by the reaping thread registered in the master process (below)
      Kernel.load test_file if test_file.end_with? '.rb'
    end

    @command_by_worker_pid[worker_pid] = @command.push(log_file, worker_number)
    send @command

    # wait for the worker to finish and report its status to the client
    Thread.new do # the reaping thread
      worker_status = Process.wait2(worker_pid).last
      command = @command_by_worker_pid.delete(worker_pid)
      @worker_number_pool.push command.last
      command[0] = if worker_status.success? then :pass else :fail end
      send command.push(worker_status.to_i, worker_status.inspect)
    end
  end

  def stop signal=:SIGTERM
    # the reaping threads registered above will reap these killed workers
    Process.kill signal, *@command_by_worker_pid.keys.map {|pid| -pid }
  rescue ArgumentError, SystemCallError
    # some workers might have already exited before we sent them the signal
  end

  def quit
    stop
    super
  end

end
end
