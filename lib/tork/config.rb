module Tork

  Config = Struct.new(:max_forked_workers, :overhead_load_paths,
                      :overhead_file_globs, :reabsorb_file_greps,
                      :all_test_file_globs, :test_file_globbers,
                      :before_fork_hooks, :after_fork_hooks,
                      :test_event_hooks).new

  #---------------------------------------------------------------------------
  # defaults
  #---------------------------------------------------------------------------

  Config.max_forked_workers = [
    # http://stackoverflow.com/questions/891537#6420817
    'fgrep -c processor /proc/cpuinfo', # Linux
    'sysctl -n hw.ncpu',                # BSD
    'hwprefs cpu_count',                # Darwin 9
    'hwprefs thread_count',             # Darwin 10
  ].map {|cmd| `#{cmd} 2>/dev/null`.to_i }.push(1).max

  Config.overhead_load_paths = ['lib', 'test', 'spec']

  Config.overhead_file_globs = ['{test,spec}/{test,spec}_helper.rb']

  Config.reabsorb_file_greps = [%r<^(test|spec)/\1_helper\.rb$>]

  Config.all_test_file_globs = ['{test,spec}/**/*_{test,spec}.rb',
                                '{test,spec}/**/{test,spec}_*.rb']

  Config.test_file_globbers = {
    # source files that correspond to test files
    %r<^lib/.+\.rb$> => lambda do |path, matches|
      base = File.basename(path, '.rb')
      ["{test,spec}/**/#{base}_{test,spec}.rb",
       "{test,spec}/**/{test,spec}_#{base}.rb"]
    end,

    # the actual test files themselves
    %r<^(test|spec)/.*(\1_[^/]+|[^/]+_\1)\.rb$> => proc {|path| path }
  }

  Config.before_fork_hooks = []

  Config.after_fork_hooks = [
    # instruct the testing framework to only run those
    # tests that are defined on the given line numbers
    lambda do |test_file, line_numbers, log_file, worker_number|
      case File.basename(test_file)
      when /(\b|_)spec(\b|_).*\.rb$/ # RSpec
        line_numbers.each {|line| ARGV.push '--line_number', line.to_s }

      when /(\b|_)test(\b|_).*\.rb$/ # Test::Unit
        # find which tests have changed inside the test file
        test_file_lines = File.readlines(test_file)
        test_names = line_numbers.map do |line|
          catch :found do
            # search backwards from the line that changed up to
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
      end
    end
  ]

  Config.test_event_hooks = []

  #---------------------------------------------------------------------------
  # overrides
  #---------------------------------------------------------------------------

  if File.exist? user_config_file = '.tork.rb'
    load user_config_file
  end

  if ENV.key? 'TORK_CONFIGS'
    require 'json'
    JSON.load(ENV['TORK_CONFIGS']).each do |config|
      if File.exist? config
        load File.expand_path(config)
      else
        require "tork/config/#{config}"
      end
    end
  end

end
