require 'diff/lcs'
require 'tork/client'
require 'tork/server'
require 'tork/config'

module Tork
module Driver

  extend Server
  extend self

  def run_all_test_files
    run_test_files Dir[*Config.all_test_file_globs]
  end

  def stop_running_test_files
    @master.send [:stop]
    @running_test_files.clear
  end

  def rerun_passed_test_files
    run_test_files @passed_test_files
  end

  def rerun_failed_test_files
    run_test_files @failed_test_files
  end

  def reabsorb_overhead_files
    @master.quit if defined? @master

    @master = Client::Transceiver.new('tork-master') do |message|
      event, file, tests = message

      case event.to_sym
      when :test
        @waiting_test_files.delete file
        @running_test_files.push file

      when :pass
        @running_test_files.delete file
        @failed_test_files.delete file
        if tests.empty? and not @passed_test_files.include? file
          @passed_test_files.push file
        end

      when :fail
        @running_test_files.delete file
        @passed_test_files.delete file
        @failed_test_files.push file unless @failed_test_files.include? file
      end

      @client.send message
    end

    @master.send [:load, Config.overhead_load_paths,
                  Dir[*Config.overhead_file_globs]]

    rerun_running_test_files
  end

  def loop
    reabsorb_overhead_files

    @herald = Client::Transceiver.new('tork-herald') do |changed_files|
      warn "#{$0}(#{$$}): FILE BATCH #{changed_files.size}" if $DEBUG
      changed_files.each do |changed_file|
        warn "#{$0}(#{$$}): FILE #{changed_file}" if $DEBUG

        # find and run the tests that correspond to the changed file
        Config.test_file_globbers.each do |regexp, globber|
          if regexp =~ changed_file and glob = globber.call(changed_file, $~)
            run_test_files Dir[glob]
          end
        end

        # reabsorb text execution overhead if overhead files changed
        if Config.reabsorb_file_greps.any? {|r| r =~ changed_file }
          @client.send [:over, changed_file]
          # NOTE: new thread because reabsorb_overhead_files will kill this one
          Thread.new { reabsorb_overhead_files }.join
        end
      end
    end

    super

    @herald.quit
    @master.quit
  end

private

  @waiting_test_files = []
  @running_test_files = []
  @passed_test_files = []
  @failed_test_files = []

  def rerun_running_test_files
    run_test_files @running_test_files
  end

  def run_test_files files
    files.each {|f| run_test_file f }
  end

  def run_test_file file
    if File.exist? file and not @waiting_test_files.include? file
      @waiting_test_files.push file
      @master.send [:test, file, find_changed_line_numbers(file)]
    end
  end

  @lines_by_file = {}

  def find_changed_line_numbers test_file
    # cache the contents of the test file for diffing below
    new_lines = File.readlines(test_file)
    old_lines = @lines_by_file[test_file] || new_lines
    @lines_by_file[test_file] = new_lines

    # find which line numbers have changed inside the test file
    Diff::LCS.diff(old_lines, new_lines).flatten.
      # +1 because line numbers start at 1, not 0
      map {|change| change.position + 1 }.uniq
  end

end
end
