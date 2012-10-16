require 'set'
require 'tork/engine'
require 'tork/server'
require 'tork/config'

module Tork
class Driver < Server

  REABSORB_FILE_GREPS = []
  ALL_TEST_FILE_GLOBS = []
  TEST_FILE_GLOBBERS = {}

  def initialize
    super
    Tork.config :driver

    @herald = popen('tork-herald')
    @engine = popen('tork-engine')
  end

  def recv client, message
    case client
    when @engine
      send nil, message # propagate downstream
    when @herald
      message.each do |changed_file|
        # find and run the tests that correspond to the changed file
        visited = Set.new
        visitor = lambda do |source_file|
          TEST_FILE_GLOBBERS.each do |regexp, globber|
            if regexp =~ source_file and globs = globber.call($~)
              Dir[*globs].each do |test_file|
                if visited.add? test_file
                  run_test_file test_file
                  visitor.call test_file
                end
              end
            end
          end
        end
        visitor.call changed_file

        # reabsorb text execution overhead if overhead files changed
        overhead_changed = REABSORB_FILE_GREPS.any? do |pattern|
          if pattern.kind_of? Regexp
            pattern =~ changed_file
          else
            pattern == changed_file
          end
        end
        if overhead_changed
          send nil, [:reabsorb, changed_file]
          reabsorb_overhead
        end
      end
    else
      super
    end
  end

  def loop
    super
  ensure
    pclose @herald
    pclose @engine
  end

  def run_all_test_files
    all_test_files = Dir[*ALL_TEST_FILE_GLOBS]
    if all_test_files.empty?
      tell @client, 'There are no test files to run.'
    else
      all_test_files.each {|f| run_test_file f }
    end
  end

  # accept and delegate tork-engine(1) commands
  Engine.public_instance_methods(false).each do |name|
    unless method_defined? name
      define_method name do |*args|
        send @engine, [name, *args]
      end
    end
  end

end
end
