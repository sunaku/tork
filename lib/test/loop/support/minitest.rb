if defined? MiniTest::Unit
  Test::Loop.before_each_test.push proc {
    MiniTest::Unit.output = $stdout
  }
end
