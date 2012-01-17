require 'json'
require 'diff/lcs'
require 'testr/client'
require 'testr/server'
require 'testr/config'

module TestR
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

    @master = Client::Transceiver.new('testr-master') do |line|
      event, file, tests = JSON.load(line)

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

      @upstream.print line
    end

    @master.send [:load, Config.overhead_load_paths,
                  Dir[*Config.overhead_file_globs]]

    rerun_running_test_files
  end

  def loop
    reabsorb_overhead_files

    @herald = Client::Receiver.new('testr-herald') do |line|
      changed_file = line.chomp
      warn "testr-driver: herald: #{changed_file}" if $DEBUG

      # find and run the tests that correspond to the changed file
      Config.test_file_globbers.each do |regexp, globber|
        if regexp =~ changed_file and glob = globber.call(changed_file)
          run_test_files Dir[glob]
        end
      end

      # reabsorb text execution overhead if overhead files changed
      if Config.reabsorb_file_greps.any? {|r| r =~ changed_file }
        @upstream.puts JSON.dump([:over, changed_file])
        # NOTE: new thread because reabsorb_overhead_files will kill this one
        Thread.new { reabsorb_overhead_files }.join
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
      @master.send [:test, file, find_changed_test_names(file)]
    end
  end

  @lines_by_file = {}

  def find_changed_test_names test_file
    # cache the contents of the test file for diffing below
    new_lines = File.readlines(test_file)
    old_lines = @lines_by_file[test_file] || new_lines
    @lines_by_file[test_file] = new_lines

    # find which tests have changed inside the given test file
    Diff::LCS.diff(old_lines, new_lines).flatten.map do |change|
      catch :found do
        # search backwards from the line that changed up to
        # the first line in the file for test definitions
        change.position.downto(0) do |i|
          if test_name = Config.test_name_extractor.call(new_lines[i])
            throw :found, test_name
          end
        end; nil # prevent unsuccessful search from returning an integer
      end
    end.compact.uniq
  end

end
end
