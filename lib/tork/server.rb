require 'tork/client'

module Tork
class Server

  def initialize
    trap(:SIGTERM){ quit }
  end

  def quit
    Thread.exit # kill Client::Receiver in loop()
  end

  def loop
    @client = Client::Transmitter.new(STDOUT.dup)
    STDOUT.reopen(STDERR).sync = true

    Client::Receiver.new(STDIN) do |command|
      method = command.first
      if respond_to? method and method != __method__ # prevent loops
        @command = command
        __send__(*command)
      else
        warn "#{self}: invalid command: #{method}"
      end
    end.join
  end

end
end
