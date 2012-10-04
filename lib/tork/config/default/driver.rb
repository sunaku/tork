Tork::Driver::OVERHEAD_FILE_GLOBS.push(
  '{test,spec}/{test,spec}_helper.rb'
)

Tork::Driver::REABSORB_FILE_GREPS.push(
  %r{^(test|spec)/\1_helper\.rb$}
)

Tork::Driver::ALL_TEST_FILE_GLOBS.push(
  '{test,spec}/**/*_{test,spec}.rb',
  '{test,spec}/**/{test,spec}_*.rb'
)

Tork::Driver::TEST_FILE_GLOBBERS.update(
  # source files that correspond to test files
  %r{^lib/.*?([^/]+)\.rb$} => lambda do |matches|
    name = matches[1]
    ["{test,spec}/**/#{name}_{test,spec}.rb",
     "{test,spec}/**/{test,spec}_#{name}.rb"]
  end,

  # the actual test files themselves
  %r{^(test|spec)/.*?(\1_[^/]+|[^/]+_\1)\.rb$} => lambda {|m| m[0] }
)
