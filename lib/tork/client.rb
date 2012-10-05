require 'rbconfig'
require 'thread'
require 'json'

module Tork
module Client

  class Transmitter < Thread
    def initialize output_stream
      @outbox = Queue.new
      super() do
        while command = @outbox.deq
          warn "#{$0}(#{$$}): SEND #{command.inspect}" if $DEBUG
          output_stream.puts JSON.dump(command)
          output_stream.flush
        end
      end
    end

    def send command
      @outbox.enq command
    end
  end

  class Receiver < Thread
    def initialize input_stream
      super() do
        while command = JSON.load(input_stream.gets)
          warn "#{$0}(#{$$}): RECV #{command.inspect}" if $DEBUG
          yield command
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
