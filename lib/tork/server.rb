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
      if command.first != __method__ # prevent loops
        @command = command
        begin
          __send__(*command)
        rescue => error
          warn "#{$0}: #{error}"
          warn error.backtrace.join("\n")
        end
      end
    end.join
  end

end
end
