require 'test/loop'

Test::Loop.before_each_test.push lambda {
  |test_file, log_file, test_names, worker_id|

  require 'coco'
  Coco::HtmlDirectory::COVERAGE_DIR = test_file + '.cov'
}
