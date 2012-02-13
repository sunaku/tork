require 'tork/config'

Tork::Config.all_test_file_globs << 'features/**/*.feature'

Tork::Config.test_file_globbers.update(
  # source files that correspond to test files
  %r<^(features/(.+/)?)step_definitions/.+\.rb$> => lambda do |matches|
    matches[1] + '*.feature'
  end,

  # the actual test files themselves
  %r<^features/.+\.feature$> => lambda {|matches| matches[0] }
)

Tork::Config.after_fork_hooks.push lambda {
  |test_file, line_numbers, log_file, worker_number|

  if test_file.end_with? '.feature'
    original_argv = ARGV.dup
    begin
      # pass the feature file to cucumber(1) in ARGV
      ARGV.push [test_file, *line_numbers].join(':')
      require 'rubygems'
      require 'cucumber'
      load Gem.bin_path('cucumber', 'cucumber')
    ensure
      # Restore ARGV for other at_exit hooks.  Otherwise, RSpec's hook will
      # try to load the non-Ruby feature file from ARGV and fail accordingly.
      ARGV.replace original_argv
    end
  end
}
