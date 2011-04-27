require 'ostruct'
require 'diff/lcs'

module Test
  Loop = OpenStruct.new

  Loop.overhead_file_globs = ['{test,spec}/{test,spec}_helper.rb']

  Loop.reabsorb_file_globs = Loop.overhead_file_globs.dup

  Loop.test_file_matchers = {
    # source files that correspond to test files
    'lib/**/*.rb' => lambda do |path|
      extn = File.extname(path)
      base = File.basename(path, extn)
      "{test,spec}/**/#{base}_{test,spec}#{extn}"
    end,

    # the actual test files themselves
    '{test,spec}/**/*_{test,spec}.rb' => lambda {|path| path }
  }

  Loop.test_name_parser = lambda do |line|
    case line
    when /^\s*def\s+test_(\w+)/ then $1
    when /^\s*(test|context|should|describe|it)\b.+?(['"])(.*?)\2/ then $3
    end
  end

  Loop.before_each_test = [
    lambda {|test_file, log_file, test_names|
      unless test_names.empty?
        test_name_pattern = test_names.map do |name|
          # sanitize string interpolations and invalid method name characters
          name.gsub(/\#\{.*?\}/, ' ').strip.gsub(/\W+/, '.*')
        end.join('|')

        case File.basename(test_file)
        when /(\b|_)test(\b|_)/ # Test::Unit
          ARGV.push '--name', "/#{test_name_pattern}/"
        when /(\b|_)spec(\b|_)/ # RSpec
          ARGV.push '--example', test_name_pattern
        end
      end
    }
  ]

  Loop.after_each_test = []

  class << Loop
    def run
      init_shared_vars
      trap_user_signals
      load_user_config
      load_user_overhead
      init_worker_queue
      enter_testing_loop

    rescue Interrupt
      # allow user to break the loop

    rescue Exception => error
      STDERR.puts error.inspect, error.backtrace
      pause_momentarily
      reload_master_process

    ensure
      stop_worker_queue
      notify 'Goodbye!'
    end

    private

    MASTER_EXECV = [$0, *ARGV].map {|s| s.dup.freeze }.freeze
    MASTER_ENV = Hash[ENV.map {|k,v| [k.freeze, v.freeze] }].freeze
    RESUME_ENV_KEY = 'TEST_LOOP_RESUME_FILES'.freeze

    ANSI_CLEAR_LINE = "\e[2K\e[0G".freeze
    ANSI_GREEN = "\e[32m%s\e[0m".freeze
    ANSI_RED = "\e[31m%s\e[0m".freeze

    Worker = Struct.new(:test_file, :log_file, :started_at, :finished_at,
                        :exit_status)

    def notify message
      # using print() because puts() is not an atomic operation.
      # also, clear the line before printing because some shells emit
      # text when control-key combos are pressed (to trigger signals)
      print "#{ANSI_CLEAR_LINE}test-loop: #{message}\n"
    end

    def pause_momentarily
      sleep 1
    end

    def init_shared_vars
      @lines_by_file = {} # path => readlines
      @last_ran_at = @started_at = Time.now
      @worker_by_pid = {}
    end

    def trap_user_signals
      trap(:INT) { raise Interrupt }
      trap(:TSTP) { forcibly_run_all_tests }
      trap(:QUIT) { reload_master_process }
    end

    def forcibly_run_all_tests
      notify 'Running all tests...'
      @last_ran_at = Time.at(0)
      @lines_by_file.clear
    end

    # The given test files are passed down (along with currently running
    # test files) to the next incarnation of test-loop for resumption.
    def reload_master_process test_files = []
      test_files.concat currently_running_test_files
      stop_worker_queue
      ENV.replace MASTER_ENV.merge(RESUME_ENV_KEY => test_files.inspect)
      exec(*MASTER_EXECV)
    end

    def load_user_config
      if File.exist? config_file = File.join(Dir.pwd, '.test-loop')
        notify 'Loading configuration...'
        load config_file

        # ...and if the configuration file changes, reload everything.
        reabsorb_file_globs.push config_file
      end
    end

    def load_user_overhead
      notify 'Absorbing overhead...'
      $LOAD_PATH.unshift 'lib', 'test', 'spec'
      Dir[*overhead_file_globs].each do |file|
        require File.basename(file, File.extname(file))
      end
    end

    def enter_testing_loop
      notify 'Ready for testing!'
      loop do
        reap_worker_queue

        # find test files that have been modified since the last run
        test_files = test_file_matchers.map do |source_glob, test_matcher|
          Dir[source_glob].select {|file| File.mtime(file) > @last_ran_at }.
          map {|path| Dir[test_matcher.call(path).to_s] }
        end.flatten.uniq

        # resume test files stopped by the previous incarnation of test-loop
        if ENV.key? RESUME_ENV_KEY
          resume_files = eval(ENV.delete(RESUME_ENV_KEY))
          unless resume_files.empty?
            notify 'Resuming tests...'
            test_files.concat(resume_files).uniq!
          end
        end

        # reabsorb test execution overhead as necessary
        if Dir[*reabsorb_file_globs].any? {|f| File.mtime(f) > @started_at }
          notify 'Overhead changed!'
          reload_master_process test_files
        end

        # fork workers to run the test files in parallel,
        # excluding test files that are already running
        test_files -= currently_running_test_files
        unless test_files.empty?
          @last_ran_at = Time.now
          test_files.each {|file| fork_worker Worker.new(file) }
        end

        pause_momentarily
      end
    end

    def currently_running_test_files
      @worker_by_pid.values.map(&:test_file)
    end

    def init_worker_queue
      # collect children (of which some may be workers) for reaping below
      @exited_child_infos = []
      trap :CHLD do
        finished_at = Time.now
        begin
          while wait2_array = Process.wait2(-1, Process::WNOHANG)
            @exited_child_infos.push [wait2_array, finished_at]
          end
        rescue SystemCallError
          # raised by wait() when there are no child processes at all
        end
      end
    end

    # reap finished workers from previous iterations of the loop
    def reap_worker_queue
      while info = @exited_child_infos.shift
        (child_pid, exit_status), finished_at = info
        if worker = @worker_by_pid.delete(child_pid)
          worker.exit_status = exit_status
          worker.finished_at = finished_at
          reap_worker worker
        end
      end
    end

    def stop_worker_queue
      notify 'Stopping tests...'
      trap :CHLD, 'DEFAULT'
      @worker_by_pid.each_key do |worker_pid|
        begin
          Process.kill :TERM, -worker_pid
        rescue SystemCallError
          # worker is already terminated
        end
      end
      Process.waitall
    end

    def fork_worker worker
      notify "TEST #{worker.test_file}"

      worker.log_file = worker.test_file + '.log'

      # cache the contents of the test file for diffing below
      new_lines = File.readlines(worker.test_file)
      old_lines = @lines_by_file[worker.test_file] || new_lines
      @lines_by_file[worker.test_file] = new_lines

      worker.started_at = Time.now
      pid = fork do
        # detach worker from master's terminal device so that
        # it does not receieve the user's control-key presses
        Process.setsid

        # unregister signal handlers inherited from master process
        [:INT, :TSTP, :QUIT].each {|sig| trap sig, 'DEFAULT' }

        # detach worker from master's standard input stream
        STDIN.reopen IO.pipe.first

        # capture test output in log file because tests are run in parallel
        # which makes it difficult to understand interleaved output thereof
        STDERR.reopen(STDOUT.reopen(worker.log_file, 'w')).sync = true

        # determine which test blocks have changed inside the test file
        test_names = Diff::LCS.diff(old_lines, new_lines).flatten.map do |change|
          catch :found do
            # search backwards from the line that changed up to
            # the first line in the file for test definitions
            change.position.downto(0) do |i|
              if test_name = test_name_parser.call(new_lines[i])
                throw :found, test_name
              end
            end; nil # prevent unsuccessful search from returning an integer
          end
        end.compact.uniq

        # tell the testing framework to run only the changed test blocks
        before_each_test.each do |hook|
          hook.call worker.test_file, worker.log_file, test_names
        end

        # make the process title Test::Unit friendly and ps(1) searchable
        $0 = "test-loop #{worker.test_file}"

        # after loading the user's test file, the at_exit() hook of the
        # user's testing framework will take care of running the tests and
        # reflecting any failures in the worker process' exit status
        load worker.test_file
      end

      @worker_by_pid[pid] = worker
    end

    def reap_worker worker
      # report test results along with any failure logs
      if worker.exit_status.success?
        notify ANSI_GREEN % "PASS #{worker.test_file}"
      elsif worker.exit_status.exited?
        notify ANSI_RED % "FAIL #{worker.test_file}"
        STDERR.print File.read(worker.log_file)
      end

      after_each_test.each do |hook|
        hook.call worker.test_file, worker.log_file, worker.exit_status,
                  worker.started_at, worker.finished_at - worker.started_at
      end
    end
  end
end
