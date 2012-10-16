require 'set'
require 'diff/lcs'
require 'tork/server'
require 'tork/config'

module Tork
class Engine < Server

  def initialize
    super
    Tork.config :engine

    @waiting_test_files = Set.new # dispatched to master but not yet running
    @running_test_files = Set.new # dispatched to master and started running
    @passed_test_files = Set.new
    @failed_test_files = Set.new
    @lines_by_file = {}

    create_master
  end

  def loop
    super
  ensure
    destroy_master
  end

  def reabsorb_overhead
    destroy_master
    create_master

    # re-dispatch the previously dispatched files to the new master
    dispatched_test_files = @running_test_files + @waiting_test_files
    @waiting_test_files.clear
    run_test_files dispatched_test_files
  end

  def run_test_file test_file, *line_numbers
    if File.exist? test_file and @waiting_test_files.add? test_file
      if line_numbers.empty?
        line_numbers = find_changed_line_numbers(test_file)
      else
        line_numbers.map!(&:to_i)
        line_numbers.clear if line_numbers.any?(&:zero?)
      end
      send @master, [:test, test_file, line_numbers]
    end
  end

  def stop_running_test_files signal=nil
    if @running_test_files.empty?
      warn "#{$0}: There are no running test files to stop."
    else
      send @master, [:stop, signal].compact
      @running_test_files.clear
    end
  end

  def rerun_passed_test_files
    if @passed_test_files.empty?
      warn "#{$0}: There are no passed test files to re-run."
    else
      run_test_files @passed_test_files
    end
  end

  def rerun_failed_test_files
    if @failed_test_files.empty?
      warn "#{$0}: There are no failed test files to re-run."
    else
      run_test_files @failed_test_files
    end
  end

protected

  def recv client, message
    case client
    when @master
      send nil, message # propagate downstream

      event, file, line_numbers = message
      case event.to_sym
      when :test
        @waiting_test_files.delete file
        @running_test_files.add file

      when :pass
        @running_test_files.delete file

        # only whole test file runs qualify as pass
        if line_numbers.empty?
          was_fail = @failed_test_files.delete? file
          now_pass = @passed_test_files.add? file
          send nil, [:fail_now_pass, file, message] if was_fail and now_pass
        end

      when :fail
        @running_test_files.delete file
        was_pass = @passed_test_files.delete? file
        now_fail = @failed_test_files.add? file
        send nil, [:pass_now_fail, file, message] if was_pass and now_fail
      end
    else
      super
    end
  end

private

  def run_test_files files
    files.each {|f| run_test_file f }
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

  def create_master
    @master = popen('tork-master')
  end

  def destroy_master
    pclose @master
  end

end
end
