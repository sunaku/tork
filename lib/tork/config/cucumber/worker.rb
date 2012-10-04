if $tork_test_file.end_with? '.feature'
  original_argv = ARGV.dup
  begin
    # pass the feature file to cucumber(1) in ARGV
    ARGV.push [$tork_test_file, *$tork_line_numbers].join(':')
    require 'rubygems'
    require 'cucumber'
    load Gem.bin_path('cucumber', 'cucumber')
  ensure
    # restore ARGV for other at_exit hooks.  otherwise, RSpec's hook will
    # try to load the non-Ruby feature file from ARGV and fail accordingly.
    ARGV.replace original_argv
  end
end
