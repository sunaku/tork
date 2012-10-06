Tork::Driver::REABSORB_FILE_GREPS.push Regexp.quote('test/test_helper.rb')

Tork::Driver::ALL_TEST_FILE_GLOBS.push 'test/**/{test_*,*_test}.rb'

Tork::Driver::TEST_FILE_GLOBBERS.update(
  # source files that correspond to test files
  %r{^lib/.*?([^/]+)\.rb$} => lambda do |matches|
    target = matches[1]
    "test/**/{test_#{target},#{target}_test}.rb"
  end,

  # the actual test files themselves
  %r{^test/.+\.rb$} => lambda do |matches|
    target = matches[0]
    target if File.basename(target) =~ /^test_|_test\./
  end
)
