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
    tell nil, 'Absorbing test execution overhead...'
    @driver = popen('tork-driver')
    super
  ensure
    pclose @driver
  end

protected

  def recv client, message
    case client
    when @driver
      event, *details = message

      case event_sym = event.to_sym
      when :absorb   then tell nil, 'Overhead absorbed. Ready for testing!'
      when :reabsorb then tell nil, 'Reabsorbing changed overhead files...'
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

        tell nil, message
      end
    else
      key, *args = message
      key &&= key.lstrip[0,1].downcase

      if cmd = COMMANDS[key]
        quit if cmd == :quit
        call = Array(cmd) + args
        tell nil, "Sending #{call.inspect} command..."
        send @driver, call
      else
        # user typed an invalid command so help them along
        COMMANDS.each do |key, cmd|
          desc = Array(cmd).join(' with ').to_s.tr('_', ' ')
          tell @client, "Type #{key} then ENTER to #{desc}."
        end
      end
    end
  end

end
end
