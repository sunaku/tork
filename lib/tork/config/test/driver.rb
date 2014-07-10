Tork::Driver::REABSORB_FILE_GREPS.push /\btest_helper\.rb$/

Tork::Driver::ALL_TEST_FILE_GLOBS.push $tork_config_test_glob

Tork::Driver::TEST_FILE_GLOBBERS.update(
  # source files that correspond to test files
  %r{([^/]+)\.rb$} => lambda do |matches|
    $tork_config_test_glob.gsub(/(?<=_)\*|\*(?=_)/, matches[1])
  end,

  # the actual test files themselves
  $tork_config_test_grep => lambda {|matches| matches[0] }
)
