require 'set'
require 'tork/client'
require 'tork/server'
require 'tork/engine'
require 'tork/config'

module Tork
module Driver

  extend Server
  extend self

  def run_all_test_files
    Dir[*Config.all_test_file_globs].each {|f| @engine.send [:run_test_file, f] }
  end

  def reabsorb_overhead_files
    @engine.send [:absorb_overhead, Config.overhead_load_paths,
                  Dir[*Config.overhead_file_globs]]
  end

  def loop
    @herald = Client::Transceiver.new('tork-herald') do |changed_files|
      warn "#{$0}(#{$$}): FILE BATCH #{changed_files.size}" if $DEBUG
      changed_files.each do |changed_file|
        warn "#{$0}(#{$$}): FILE #{changed_file}" if $DEBUG

        # find and run the tests that correspond to the changed file
        visited = Set.new
        visitor = lambda do |source_file|
          Config.test_file_globbers.each do |regexp, globber|
            if regexp =~ source_file and globs = globber.call(source_file, $~)
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
        if Config.reabsorb_file_greps.any? {|r| r =~ changed_file }
          @client.send [:over, changed_file]
          reabsorb_overhead_files
        end
      end
    end

    @engine = Client::Transceiver.new('tork-engine') do |message|
      @client.send message # propagate output downstream
    end

    reabsorb_overhead_files

    super

    @herald.quit
    @engine.quit
  end

  # accept tork-engine(1) commands and delegate them accordingly
  (Engine.instance_methods - instance_methods).each do |meth|
    define_method meth do |*args|
      @engine.send [meth, *args]
    end
  end

end
end
