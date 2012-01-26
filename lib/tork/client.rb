require 'thread'

module Tork
module Client

  class Transmitter < Thread
    def initialize output_stream
      @outbox = Queue.new
      super do
        while message = @outbox.deq
          output_stream << message
        end
      end
    end

    def print string
      @outbox.enq string
    end

    def send command
      warn "#{$0}(#{$$}): SEND #{command.inspect}" if $DEBUG
      print JSON.dump(command) + "\n"
    end
  end

  class Receiver < Thread
    def initialize *popen_args
      (@io = IO.popen(*popen_args)).sync = true
      super() { loop { yield @io.gets } }
    end

    def quit
      kill # stop receive loop
      Process.kill :SIGTERM, @io.pid
      Process.wait @io.pid # reap zombie
      @io.close # prevent further I/O
    end
  end

  class Transceiver < Receiver
    def initialize *popen_args
      popen_args[1] = 'w+'
      super
      @transmitter = Transmitter.new(@io)
    end

    def send command
      @transmitter.send command
    end
  end

end
end
