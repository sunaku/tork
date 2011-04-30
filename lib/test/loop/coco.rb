require 'test/loop'

Test::Loop.before_each_test.push lambda {
  |test_file, log_file, test_names|

  require 'coco'
  Coco::HtmlDirectory::COVERAGE_DIR = test_file + '.cov'
}
