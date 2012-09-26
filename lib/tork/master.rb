require 'tork/server'
require 'tork/config'

module Tork
class Master < Server

  def initialize
    super

    @worker_number_pool = (0 ... Config.max_forked_workers).to_a
    @command_by_worker_pid = {}
  end

  def load paths, files
    $LOAD_PATH.unshift(*paths)

    @overhead_files = files.each do |file|
      branch, leaf = File.split(file)
      file = leaf if paths.include? branch
      require file.sub(/\.rb$/, '')
    end

    @client.send @command
  end

  def test test_file, line_numbers
    return if @overhead_files.include? test_file

    # throttle forking rate to meet the maximum concurrent workers limit
    sleep 1 until @command_by_worker_pid.size < Config.max_forked_workers

    log_file = test_file + '.log'
    worker_number = @worker_number_pool.shift

    Config.before_fork_hooks.each do |hook|
      hook.call test_file, line_numbers, log_file, worker_number
    end

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

      Config.after_fork_hooks.each do |hook|
        hook.call test_file, line_numbers, log_file, worker_number
      end

      # after loading the user's test file, the at_exit() hook of the user's
      # testing framework will take care of running the tests and reflecting
      # any failures in the worker process' exit status, which will then be
      # handled by the reaping thread registered in the master process (below)
      Kernel.load test_file if test_file.end_with? '.rb'
    end

    @command_by_worker_pid[worker_pid] = @command.push(log_file, worker_number)
    @client.send @command

    # wait for the worker to finish and report its status to the client
    Thread.new do # the reaping thread
      worker_status = Process.wait2(worker_pid).last
      command = @command_by_worker_pid.delete(worker_pid)
      @worker_number_pool.push command.last
      command[0] = if worker_status.success? then :pass else :fail end
      @client.send command.push(worker_status.to_i, worker_status.inspect)
    end
  end

  def stop
    # the reaping threads registered above will reap these killed workers
    Process.kill :SIGTERM, *@command_by_worker_pid.keys.map {|pid| -pid }
  rescue ArgumentError, SystemCallError
    # some workers might have already exited before we sent them the signal
  end

  def quit
    stop
    super
  end

end
end
