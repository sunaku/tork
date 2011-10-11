require 'json'
require 'testr/server'
require 'testr/config'

module TestR
module Master

  extend Server
  extend self

  def load paths, files
    $LOAD_PATH.unshift(*paths)

    files.each do |file|
      branch, leaf = File.split(file)
      file = leaf if paths.include? branch
      require file.sub(/\.rb$/, '')
    end

    @upstream.print @command_line
  end

  def test test_file, test_names
    # throttle forking rate to meet the maximum concurrent workers limit
    # NOTE: the next SIGCHLD signal will wake us from this eternal sleep
    sleep until @command_by_worker_pid.size < Config.max_forked_workers

    log_file = test_file + '.log'
    worker_number = @worker_number_pool.shift

    Config.before_fork_hooks.each do |hook|
      hook.call worker_number, log_file, test_file, test_names
    end

    worker_pid = fork do
      # make the process title Test::Unit friendly and ps(1) searchable
      $0 = "testr-worker[#{worker_number}] #{test_file}"

      # detach worker process from master process' group for kill -pgrp
      Process.setsid

      # detach worker process from master process' standard input stream
      STDIN.reopen IO.pipe.first

      # capture test output in log file because tests are run in parallel
      # which makes it difficult to understand interleaved output thereof
      STDERR.reopen(STDOUT.reopen(log_file, 'w')).sync = true

      Config.after_fork_hooks.each do |hook|
        hook.call worker_number, log_file, test_file, test_names
      end

      # after loading the user's test file, the at_exit() hook of the user's
      # testing framework will take care of running the tests and reflecting
      # any failures in the worker process' exit status, which will then be
      # handled by the SIGCHLD trap registered in the master process (below)
      Kernel.load test_file
    end

    @command_by_worker_pid[worker_pid] = @command.push(worker_number)
    @upstream.print @command_line
  end

  def stop
    # NOTE: the SIGCHLD handler will reap these killed worker processes
    Process.kill :SIGTERM, *@command_by_worker_pid.keys.map {|pid| -pid }
  rescue ArgumentError, SystemCallError
    # some workers might have already exited before we sent them the signal
  end

  def loop
    super
    stop
  end

private

  @worker_number_pool = (0 ... Config.max_forked_workers).to_a
  @command_by_worker_pid = {}

  # process exited child processes and report finished workers to upstream
  trap :SIGCHLD do
    begin
      while wait2_array = Process.wait2(-1, Process::WNOHANG)
        child_pid, child_status = wait2_array
        if command = @command_by_worker_pid.delete(child_pid)
          @worker_number_pool.push command.pop
          command[0] = child_status.success? ? 'pass' : 'fail'
          @upstream.puts JSON.dump(command.push(child_status))
        else
          warn "testr-master: unknown child exited: #{wait2_array.inspect}"
        end
      end
    rescue SystemCallError
      # raised by wait2() when there are currently no child processes
    end
  end

end
end
