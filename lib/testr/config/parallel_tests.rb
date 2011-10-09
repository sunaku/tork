require 'testr/config'

TestR::Config.after_fork_hooks << lambda {
  |worker_number, log_file, test_file, test_names|

  # for compatitibilty with parallel_tests gem,
  # store numbers as strings: "", "2", "3", "4"
  ENV['TEST_ENV_NUMBER'] = (worker_number + 1).to_s if worker_number > 0
}
