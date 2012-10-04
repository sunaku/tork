Tork::Driver::ALL_TEST_FILE_GLOBS.push 'features/**/*.feature'

Tork::Driver::TEST_FILE_GLOBBERS.update(
  # source files that correspond to test files
  %r{^(features/(.+/)?)step_definitions/.+\.rb$} => lambda do |matches|
    matches[1] + '*.feature'
  end,

  # the actual test files themselves
  %r{^features/.+\.feature$} => lambda {|matches| matches[0] }
)
