require 'set'
require 'diff/lcs'
require 'tork/client'
require 'tork/server'
require 'tork/config'

module Tork
class Engine < Server

  def initialize
    super
    @waiting_test_files = Set.new
    @running_test_files = Set.new
    @passed_test_files = Set.new
    @failed_test_files = Set.new
    @lines_by_file = {}
    @master = create_master_process
  end

  def quit
    @master.quit
    super
  end

  def absorb_overhead load_paths, overhead_files
    @master.quit
    @master = create_master_process
    @master.send [:load, load_paths, overhead_files]
    run_test_files @running_test_files # resume running them in the new master
  end

  def run_test_file test_file, line_numbers=nil
    if File.exist? test_file and @waiting_test_files.add? test_file
      line_numbers ||= find_changed_line_numbers(test_file)
      @master.send [:test, test_file, line_numbers]
    end
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

protected

  def run_test_files files
    files.each {|f| run_test_file f }
  end

private

  def create_master_process
    Client::Transceiver.new('tork-master') do |message|
      @client.send message # propagate output downstream

      event, file, line_numbers = message
      case event.to_sym
      when :test
        @waiting_test_files.delete file
        @running_test_files.add file

      when :pass
        @running_test_files.delete file

        # only whole test file runs qualify as pass
        if line_numbers.empty?
          @failed_test_files.delete file
          @passed_test_files.add file
        end

      when :fail
        @running_test_files.delete file
        @failed_test_files.add file
        @passed_test_files.delete file
      end

      Config.test_event_hooks.each {|hook| hook.call message }
    end
  end

  def find_changed_line_numbers test_file
    # cache test file contents for diffing below
    new_lines = File.readlines(test_file)
    old_lines = @lines_by_file[test_file] || new_lines
    @lines_by_file[test_file] = new_lines

    # find changed line numbers in the test file
    Diff::LCS.diff(old_lines, new_lines).flatten.
      # +1 because line numbers start at 1, not 0
      map {|change| change.position + 1 }.uniq
  end

end
end
