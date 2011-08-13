require 'test/loop'

Test::Loop.before_each_test.push lambda {
  |test_file, log_file, test_names, worker_id|

  # for compatitibilty with parallel_tests gem,
  # use numbers as strings: "", "2", "3", "4"
  ENV['TEST_ENV_NUMBER'] = worker_id.next.to_s if worker_id > 0
}
