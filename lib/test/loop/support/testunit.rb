if defined? Test::Unit::AutoRunner
  Test::Loop.before_each_test.push proc {
    Test::Unit::AutoRunner.prepare do |config|
      config.runner_options[:output] = $stdout
    end
  }
end
