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

  def loop
    tell @clients, 'Absorbing test execution overhead...', false
    @driver = popen('tork-driver')
    super
  ensure
    pclose @driver
  end

protected

  def join client
    super
    help client
  end

  def recv client, message
    case client
    when @driver
      event, *details = message

      case event_sym = event.to_sym
      when :absorb
        tell @clients, 'Overhead absorbed. Ready for testing!', false

      when :reabsorb
        tell @clients, 'Reabsorbing changed overhead files...', false

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

        tell @clients, message, false
      end
    else
      key = message.shift.lstrip[0,1].downcase
      cmd = Array(COMMANDS.fetch(key, [:help, client])) + message
      if respond_to? cmd.first, true
        __send__(*cmd)
      else
        tell @clients, "Sending #{cmd.inspect} command...", false
        send @driver, cmd
      end
    end
  end

private

  def help client
    COMMANDS.each do |key, cmd|
      desc = Array(cmd).join(' with ').to_s.tr('_', ' ')
      tell client, "Type #{key} then ENTER to #{desc}.", false
    end
    tell client, 'Type h then ENTER to see this message.', false
  end

end
end
