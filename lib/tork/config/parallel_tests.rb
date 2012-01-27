require 'tork/config'

Tork::Config.after_fork_hooks.push lambda {
  |test_file, line_numbers, log_file, worker_number|

  # for compatitibilty with parallel_tests gem,
  # store numbers as strings: "", "2", "3", "4"
  ENV['TEST_ENV_NUMBER'] = (worker_number + 1).to_s if worker_number > 0
}
