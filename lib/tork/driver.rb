require 'set'
require 'tork/client'
require 'tork/engine'
require 'tork/server'
require 'tork/config'

module Tork
class Driver < Server

  OVERHEAD_FILE_GLOBS = []
  REABSORB_FILE_GREPS = []
  ALL_TEST_FILE_GLOBS = []
  TEST_FILE_GLOBBERS = {}

  def initialize
    Tork.config :driver
    super

    @engine = Client::Transceiver.new('tork-engine') do |message|
      send message # propagate downstream
    end

    @herald = Client::Transceiver.new('tork-herald') do |changed_files|
      changed_files.each do |changed_file|
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
        if REABSORB_FILE_GREPS.any? {|r| r =~ changed_file }
          send [:over, changed_file]
          reabsorb_overhead
        end
      end
    end
  end

  def quit
    @herald.quit
    super
  end

  def run_all_test_files
    all_test_files = Dir[*ALL_TEST_FILE_GLOBS]
    if all_test_files.empty?
      warn "#{$0}: There are no test files to run."
    else
      all_test_files.each {|f| run_test_file f }
    end
  end

  Engine.public_instance_methods(false).each do |name|
    unless method_defined? name
      define_method name do |*args|
        @engine.send [name, *args]
      end
    end
  end

end
end
