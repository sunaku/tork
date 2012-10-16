require 'tork/server'

module Tork
class CLIApp < Server

  COMMANDS = {
    't' => :run_test_file,
    'a' => :run_all_test_files,
    's' => :stop_running_test_files,
    'k' => [:stop_running_test_files, :SIGKILL],
    'p' => :rerun_passed_test_files,
    'f' => :rerun_failed_test_files,
    'o' => :reabsorb_overhead,
    'q' => :quit,
  }

  def initialize
    super
    warn "#{$0}: Absorbing test execution overhead..."
    @driver = popen('tork-driver')
  end

  def quit
    drive [:quit]
    pclose @driver
    super
  end

protected

  def hear sender, message
    if sender == STDIN
      key, *args = message.split
      key &&= key.lstrip[0,1].downcase

      if cmd = COMMANDS[key]
        quit if cmd == :quit
        drive Array(cmd) + args
      else # invalid command
        COMMANDS.each do |key, cmd|
          desc = Array(cmd).first.to_s.tr('_', ' ')
          warn "#{$0}: Type #{key} then ENTER to #{desc}."
        end
      end

      nil # don't process this message any further
    else
      super
    end
  end

  def recv client, message
    if client == @driver
      event, *details = message

      case event_sym = event.to_sym
      when :absorb   then warn "#{$0}: Overhead absorbed. Ready for testing!"
      when :reabsorb then warn "#{$0}: Reabsorbing changed overhead files..."
      when :test, :pass, :fail
        test_file, line_numbers, log_file, worker_number, exit_status = details
        message = [event.upcase, [test_file, *line_numbers].join(':'),
                   exit_status].compact.join(' ')

        color = case event_sym
                when :pass then "\e[34m%s\e[0m" # blue
                when :fail then "\e[31m%s\e[0m" # red
                end
        message = color % message if color and STDOUT.tty?
        message = [message, File.read(log_file), message] if event_sym == :fail

        puts message
      end
    end
  end

private

  def drive command
    warn "#{$0}: Sending #{command.inspect} command..."
    send @driver, command
  end

end
end
