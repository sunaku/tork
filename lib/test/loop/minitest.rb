require 'test/loop'

Test::Loop.before_each_test.push proc {
  require 'minitest/unit'
  MiniTest::Unit.output = $stdout
}
