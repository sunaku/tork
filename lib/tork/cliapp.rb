require 'tork/server'

module Tork
class CLIApp < Server

  def loop
    tell @clients, 'Absorbing test execution overhead...'
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

  BACKTRACE_CENSOR = /\n\s+(?:from\s)?#{
    Regexp.union(File.expand_path('../../..', __FILE__), TORK_DOLLAR_ZERO)
  }[^:]*:\d+:.+$/

  # remove Ruby's built-in Kernel#test() method so our test() method works
  undef test

  def recv client, message
    case client
    when @driver
      event, *details = message

      case event_sym = event.to_sym
      when :boot
        tell @clients, 'Test execution overhead absorbed; ready to test!'

      when :boot!
        tell @clients, 'Test execution overhead changed; re-absorbing...'

      when :test, :pass, :fail
        test_file, line_numbers, log_file, worker_number, exit_status = details
        message = [event.upcase, [test_file, *line_numbers].join(':'),
                   exit_status].compact.join(' ')

        color = case event_sym
                when :pass then "\e[34m%s\e[0m" # blue
                when :fail then "\e[31m%s\e[0m" # red
                end
        message = color % message if color and STDOUT.tty?

        if event_sym == :fail
          # censor Tork internals from test failure backtraces
          log = File.read(log_file).gsub(BACKTRACE_CENSOR, '')
          message = [message, log, message]
        end

        tell @clients, message, false

      when :done
        tested, passed, failed = details.map(&:length)
        tell @clients, "#{tested} tested, #{passed} passed, #{failed} failed"
      end

    else
      key = message.shift.lstrip[0,1].downcase
      cmd = Array(COMMANDS.fetch(key, [:help, client])) + message
      if respond_to? cmd.first, true
        __send__(*cmd)
      else
        tell @clients, "Sending #{cmd.inspect} command..."
        send @driver, cmd
      end
    end
  end

private

  COMMANDS = {
    't' => :test,
    'a' => :test!,
    's' => :stop,
    'k' => [:stop, :SIGKILL],
    'p' => :pass!,
    'f' => :fail!,
    'l' => :fail?,
    'b' => :boot!,
    'q' => :quit,
  }

  def help client
    tell client, <<HELP
Type a then ENTER to run all available test files.
Type t then SPACE then a filename then ENTER to run a specific test file.
Type s then ENTER to stop currently running test files.
Type k then ENTER to kill currently running test files.
Type p then ENTER to re-run currently passing test files.
Type f then ENTER to re-run currently failing test files.
Type l then ENTER to list currently failing test files.
Type b then ENTER to re-absorb test execution overhead.
Type h then ENTER to see this help message.
Type q then ENTER to quit.
HELP
  end

end
end
