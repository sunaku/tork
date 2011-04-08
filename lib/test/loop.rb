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
      @running_files = []
      @running_files_lock = Mutex.new
      @lines_by_file = {} # path => readlines
      @last_ran_at = @started_at = Time.now

      catch self do
        register_signals
        load_user_config
        absorb_overhead
        run_test_loop
      end

      kill_workers
      notify 'Goodbye!'

    rescue Exception => error
      STDERR.puts error.inspect, error.backtrace
      pause_momentarily
      reload_master_process
    end

    private

    EXEC_VECTOR = [$0, *ARGV].map {|s| s.dup.freeze }.freeze
    RESUME_ENV_KEY = 'TEST_LOOP_RESUME_FILES'.freeze

    ANSI_CLEAR_LINE = "\e[2K\e[0G".freeze
    ANSI_GREEN = "\e[32m%s\e[0m".freeze
    ANSI_RED = "\e[31m%s\e[0m".freeze

    def notify message
      # using print() because puts() is not an atomic operation.
      # also, clear the line before printing because some shells emit
      # text when control-key combos are pressed (to trigger signals)
      print "#{ANSI_CLEAR_LINE}test-loop: #{message}\n"
    end

    def register_signals
      # this signal is ignored in master and honored in workers, so all
      # workers can be killed by sending it to the entire process group
      trap :TERM, :IGNORE

      master_pid = $$
      master_trap = lambda do |signal, &handler|
        trap signal do
          if $$ == master_pid
            handler.call
          else
            # ignore future ocurrences of this signal in worker processes
            trap signal, :IGNORE
          end
        end
      end

      master_trap.call(:INT)  { throw self }
      master_trap.call(:QUIT) { reload_master_process }
      master_trap.call(:TSTP) { forcibly_run_all_tests }
    end

    def kill_workers
      notify 'Stopping tests...'
      Process.kill :TERM, -$$
      Process.waitall
    end

    # The given test files are passed down (along with currently running
    # test files) to the next incarnation of test-loop for resumption.
    def reload_master_process test_files = []
      @running_files_lock.synchronize { test_files.concat @running_files }
      kill_workers
      exec({RESUME_ENV_KEY => test_files.inspect}, *EXEC_VECTOR)
    end

    def load_user_config
      if File.exist? config_file = File.join(Dir.pwd, '.test-loop')
        notify 'Loading configuration...'
        load config_file
      end
    end

    def absorb_overhead
      notify 'Absorbing overhead...'
      $LOAD_PATH.unshift 'lib', 'test', 'spec'
      Dir[*overhead_file_globs].each do |file|
        require File.basename(file, File.extname(file))
      end
    end

    def pause_momentarily
      sleep 1
    end

    def forcibly_run_all_tests
      notify 'Running all tests...'
      @last_ran_at = Time.at(0)
      @lines_by_file.clear
    end

    def run_test_loop
      notify 'Ready for testing!'
      loop do
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
        test_files = @running_files_lock.
          synchronize { test_files - @running_files }

        unless test_files.empty?
          @last_ran_at = Time.now
          test_files.each {|file| run_test_file file }
        end

        pause_momentarily
      end
    end

    def run_test_file test_file
      @running_files_lock.synchronize { @running_files.push test_file }
      log_file = test_file + '.log'

      # cache the contents of the test file for diffing below
      new_lines = File.readlines(test_file)
      old_lines = @lines_by_file[test_file] || new_lines
      @lines_by_file[test_file] = new_lines

      worker_pid = fork do
        # this signal is ignored in master and honored in workers, so all
        # workers can be killed by sending it to the entire process group
        trap :TERM, :DEFAULT

        # capture test output in log file because tests are run in parallel
        # which makes it difficult to understand interleaved output thereof
        $stdout.reopen log_file, 'w'
        $stdout.sync = true
        $stderr.reopen $stdout

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
        before_each_test.each {|f| f.call test_file, log_file, test_names }

        # make the process title Test::Unit friendly and ps(1) searchable
        $0 = "test-loop #{test_file}"

        # after loading the user's test file, the at_exit() hook of the
        # user's testing framework will take care of running the tests and
        # reflecting any failures in the worker process' exit status
        load test_file
      end

      # monitor and report on the worker's progress
      Thread.new do
        notify "TEST #{test_file}"

        # wait for worker to finish
        Process.waitpid worker_pid
        run_status = $?
        elapsed_time = Time.now - @last_ran_at

        # report test results along with any failure logs
        if run_status.success?
          notify ANSI_GREEN % "PASS #{test_file}"
        else
          notify ANSI_RED % "FAIL #{test_file}"
          STDERR.print File.read(log_file)
        end

        after_each_test.each do |f|
          f.call test_file, log_file, run_status, @last_ran_at, elapsed_time
        end

        @running_files_lock.synchronize { @running_files.delete test_file }
      end
    end
  end
end
