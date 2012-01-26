require 'json'
require 'tork/client'

module Tork
module Server

  def quit
    throw :tork_server_quit
  end

  def loop
    (output = STDOUT.dup).sync = true
    @client = Tork::Client::Transmitter.new(output)
    STDOUT.reopen(STDERR).sync = true

    catch :tork_server_quit do
      while line = STDIN.gets
        warn "#{caller[2]} RECV #{line.chomp}" if $DEBUG

        command = JSON.load(line)
        method = command.first

        if respond_to? method and method != __method__ # prevent loops
          @command, @command_line = command, line
          __send__(*command)
        else
          warn "#{self}: bad command: #{method}"
        end
      end
    end
  rescue Interrupt
    # forced quit
  end

  def self.extended server
    trap(:SIGTERM){ server.quit }
  end

end
end
