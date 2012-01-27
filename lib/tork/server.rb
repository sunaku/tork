require 'tork/client'

module Tork
module Server

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
  rescue Interrupt
    # forced quit
  end

  def self.extended server
    trap(:SIGTERM){ server.quit }
  end

end
end
