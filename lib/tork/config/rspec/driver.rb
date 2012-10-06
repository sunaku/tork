Tork::Driver::REABSORB_FILE_GREPS.push Regexp.quote('spec/spec_helper.rb')

Tork::Driver::ALL_TEST_FILE_GLOBS.push 'spec/**/{spec_*,*_spec}.rb'

Tork::Driver::TEST_FILE_GLOBBERS.update(
  # source files that correspond to test files
  %r{^lib/.*?([^/]+)\.rb$} => lambda do |matches|
    target = matches[1]
    "spec/**/{spec_#{target},#{target}_spec}.rb"
  end,

  # the actual test files themselves
  %r{^spec/.+\.rb$} => lambda do |matches|
    target = matches[0]
    target if File.basename(target) =~ /^spec_|_spec\./
  end
)
