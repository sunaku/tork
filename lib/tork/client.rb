require 'rbconfig'
require 'thread'
require 'json'

module Tork
module Client

  class Transmitter < Thread
    def initialize output_stream
      @outbox = Queue.new
      super() do
        while message = @outbox.deq
          warn "#{$0}(#{$$}): SEND #{message.inspect}" if $DEBUG
          output_stream.puts message
          output_stream.flush
        end
      end
    end

    def send message
      @outbox.enq JSON.dump(message)
    end
  end

  class Receiver < Thread
    def initialize input_stream
      super() do
        while message = JSON.load(input_stream.gets)
          warn "#{$0}(#{$$}): RECV #{message.inspect}" if $DEBUG
          yield message
        end
      end
    end
  end

  class Transceiver < Transmitter
    def initialize *popen_args, &receive_block
      popen_args[1] = 'w+'
      @popen_io = IO.popen(*popen_args)
      @receiver = Receiver.new(@popen_io, &receive_block)
      super @popen_io
    end

    def quit
      kill # stop transmit loop
      @receiver.kill # stop receive loop
      Process.kill :SIGTERM, @popen_io.pid
      Process.wait @popen_io.pid # reap zombie
      @popen_io.close # prevent further I/O
    end
  end

end
end
