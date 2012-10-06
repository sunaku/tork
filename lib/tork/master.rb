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

  OVERHEAD_LOAD_PATHS = ['lib', 'test', 'spec']

  OVERHEAD_FILE_GLOBS = ['{test,spec}/{test,spec}_helper.rb']

  def initialize
    super
    Tork.config :master

    @worker_number_pool = (0 ... MAX_CONCURRENT_WORKERS).to_a
    @command_by_worker_pid = {}

    absorb_overhead
  end

  def test test_file, line_numbers
    # throttle forking rate to meet the maximum concurrent workers limit
    sleep 1 until @command_by_worker_pid.size < @worker_number_pool.size

    log_file = test_file + '.log'
    worker_number = @worker_number_pool.shift
    @command.push log_file, worker_number

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

      apply_line_numbers
      Tork.config :worker

      # after loading the user's test file, the at_exit() hook of the user's
      # testing framework will take care of running the tests and reflecting
      # any failures in the worker process' exit status, which will then be
      # handled by the reaping thread registered in the master process (below)
      Kernel.load test_file if test_file.end_with? '.rb'
    end

    @command_by_worker_pid[worker_pid] = @command
    send @command

    # wait for the worker to finish and report its status to the client
    Thread.new(worker_pid) do |pid| # the reaping thread
      status = Process.wait2(pid).last
      command = @command_by_worker_pid.delete(pid)
      @worker_number_pool.push command.last
      command[0] = status.success? && :pass || :fail
      send command.push(status.to_i, status.inspect)
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

private

  # Absorbs test execution overhead
  def absorb_overhead
    $LOAD_PATH.unshift(*OVERHEAD_LOAD_PATHS)
    OVERHEAD_FILE_GLOBS.each do |glob|
      Dir[glob].each do |file|
        branch, leaf = File.split(file)
        file = leaf if OVERHEAD_LOAD_PATHS.include? branch
        require file.sub(/\.rb$/, '')
      end
    end
    send [:absorb]
  end

  # Instruct the testing framework to only run those
  # tests that correspond to the given line numbers.
  def apply_line_numbers
    return if $tork_line_numbers.empty?

    case File.basename($tork_test_file)
    when /(\b|_)spec(\b|_).*\.rb$/ # RSpec
      $tork_line_numbers.each do |line|
        ARGV.push '--line_number', line.to_s
      end

    when /(\b|_)test(\b|_).*\.rb$/ # Test::Unit
      test_file_lines = File.readlines($tork_test_file)
      test_names = $tork_line_numbers.map do |line|
        catch :found do
          # search backwards from the desired line number to
          # the first line in the file for test definitions
          line.downto(0) do |i|
            test_name =
              case test_file_lines[i]
              when /^\s*def\s+test_(\w+)/ then $1
              when /^\s*(test|context|should|describe|it)\b.+?(['"])(.*?)\2/
                # elide string interpolation and invalid method name characters
                $3.gsub(/\#\{.*?\}/, ' ').strip.gsub(/\W+/, '.*')
              end \
            and throw :found, test_name
          end; nil # prevent unsuccessful search from returning an integer
        end
      end.compact.uniq

      unless test_names.empty?
        ARGV.push '--name', "/(?i:#{test_names.join('|')})/"
      end
    else
      warn "#{$0}: could not limit test execution to given line numbers"
    end
  end

end
end
