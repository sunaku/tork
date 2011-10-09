require 'ostruct'

module TestR
  _user_config_file = '.testr.rb'

  Config = OpenStruct.new

  Config.max_forked_workers = [
    # http://stackoverflow.com/questions/891537#6420817
    'fgrep -c processor /proc/cpuinfo', # Linux
    'sysctl -n hw.ncpu',                # BSD
    'hwprefs cpu_count',                # Darwin 9
    'hwprefs thread_count',             # Darwin 10
  ].map {|cmd| `#{cmd} 2>/dev/null`.to_i }.push(1).max

  Config.overhead_load_paths = ['lib', 'test', 'spec']

  Config.overhead_file_globs = ['{test,spec}/{test,spec}_helper.rb']

  Config.reabsorb_file_greps = [/^#{Regexp.quote(_user_config_file)}$/,
                                %r<(test|spec)/\1_helper\.rb>]

  Config.all_test_file_globs = ['{test,spec}/**/*_{test,spec}.rb']

  Config.test_file_globbers = {
    # source files that correspond to test files
    %r<^lib/.+\.rb$> => lambda do |path|
      base = File.basename(path, '.rb')
      "{test,spec}/**/#{base}_{test,spec}.rb"
    end,

    # the actual test files themselves
    %r<^(test|spec)/.+_\1\.rb$> => lambda {|path| path }
  }

  Config.test_name_extractor = lambda do |line|
    case line
    when /^\s*def\s+test_(\w+)/ then $1
    when /^\s*(test|context|should|describe|it)\b.+?(['"])(.*?)\2/ then $3
    end
  end

  Config.before_fork_hooks = []

  Config.after_fork_hooks = [
    # tell testing framework to only run the named tests inside the test file
    lambda do |worker_number, log_file, test_file, test_names|
      unless test_names.empty?
        regexp = Regexp.union(test_names.map {|name|
          # sanitize string interpolations and invalid method name characters
          name.gsub(/\#\{.*?\}/, ' ').strip.gsub(/\W+/, '.*')
        })

        case File.basename(test_file)
        when /(\b|_)test(\b|_)/ then ARGV.push '--name', regexp.inspect
        when /(\b|_)spec(\b|_)/ then ARGV.push '--example', regexp.source
        end
      end
    end
  ]

  load _user_config_file if File.exist? _user_config_file
end
