require 'set'
require 'diff/lcs'
require 'tork/server'
require 'tork/config'

module Tork
class Engine < Server

  def initialize
    super
    Tork.config :engine

    @queued_test_files = Set.new
    @passed_test_files = Set.new
    @failed_test_files = Set.new
    @lines_by_file = {}
  end

  def loop
    create_master
    super
  ensure
    destroy_master
  end

  def reabsorb_overhead
    destroy_master
    create_master

    # re-dispatch the previously dispatched files to the new master
    previous = @queued_test_files.to_a
    @queued_test_files.clear
    run_test_files previous
  end

  def run_test_file test_file, *line_numbers
    if File.exist? test_file and @queued_test_files.add? test_file
      if line_numbers.empty?
        line_numbers = find_changed_line_numbers(test_file)
      else
        line_numbers.map!(&:to_i)
        line_numbers.clear if line_numbers.any?(&:zero?)
      end
      send @master, [:test, test_file, line_numbers]
    end
  end

  def run_test_files test_files_with_optional_line_numbers
    test_files_with_optional_line_numbers.each {|f| run_test_file(*f) }
  end

  def stop_running_test_files signal=nil
    if @queued_test_files.empty?
      tell @client, 'There are no running test files to stop.'
    else
      send @master, [:stop, signal].compact
      @queued_test_files.clear
    end
  end

  def rerun_passed_test_files
    if @passed_test_files.empty?
      tell @client, 'There are no passed test files to re-run.'
    else
      run_test_files @passed_test_files
    end
  end

  def rerun_failed_test_files
    if @failed_test_files.empty?
      tell @client, 'There are no failed test files to re-run.'
    else
      run_test_files @failed_test_files
    end
  end

protected

  def recv client, message
    case client
    when @master
      send @clients, message # propagate downstream

      event, file, line_numbers = message
      case event.to_sym
      when :test
        @queued_test_files.delete file

      when :pass
        finished = true
        # only whole test file runs should qualify as pass
        if line_numbers.empty?
          was_fail = @failed_test_files.delete? file
          now_pass = @passed_test_files.add? file
          send @clients, [:fail_now_pass, file, message] if was_fail and now_pass
        end

      when :fail
        finished = true
        was_pass = @passed_test_files.delete? file
        now_fail = @failed_test_files.add? file
        send @clients, [:pass_now_fail, file, message] if was_pass and now_fail
      end

      send @clients, [:idle] if finished and @queued_test_files.empty?
    else
      super
    end
  end

private

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

  def create_master
    @master = popen('tork-master')
  end

  def destroy_master
    pclose @master
  end

end
end
