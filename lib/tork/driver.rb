require 'set'
require 'pathname'
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
  end

  def loop
    @herald = popen('tork-herald')
    @engine = popen('tork-engine')
    super
  ensure
    pclose @herald
    pclose @engine
  end

  def run_all_test_files
    test_files_found = false
    Dir.glob(ALL_TEST_FILE_GLOBS) do |test_file|
      next if overhead_file? test_file
      run_test_file test_file
      test_files_found = true
    end
    tell @client, 'There are no test files to run.' unless test_files_found
  end

  # accept and delegate tork-engine(1) commands
  Engine.public_instance_methods(false).each do |name|
    unless method_defined? name
      define_method name do |*args|
        send @engine, [name, *args]
      end
    end
  end

protected

  def recv client, message
    case client
    when @engine
      send @clients, message # propagate downstream

    when @herald
      message.each do |changed_file|
        # make sure this path works with the GREPS and GLOBBERS below
        # by squashing relative directory traversal and extra slashes
        changed_file = Pathname.new(changed_file).cleanpath.to_s

        # reabsorb text execution overhead if overhead files changed
        if overhead_file? changed_file
          send @clients, [:reabsorb, changed_file]
          reabsorb_overhead
        else
          run_non_overhead_test_files find_dependent_test_files(changed_file)
        end
      end

    else
      super
    end
  end

private

  def run_non_overhead_test_files test_files
    run_test_files test_files.reject {|f| overhead_file? f }
  end

  def overhead_file? file
    REABSORB_FILE_GREPS.any? do |pattern|
      if pattern.kind_of? Regexp
        pattern =~ file
      else
        pattern == file
      end
    end
  end

  def find_dependent_test_files source_file, results=Set.new
    TEST_FILE_GLOBBERS.each do |regexp, globber|
      if regexp =~ source_file and globs = globber.call($~)
        Dir.glob(*globs) do |dependent_file|
          if results.add? dependent_file
            find_dependent_test_files dependent_file, results
          end
        end
      end
    end
    results
  end

end
end
