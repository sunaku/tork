module Tork
module Client

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
      @io_write_lock = Mutex.new
      popen_args[1] = 'w+'
      super
    end

    def send command
      @io_write_lock.synchronize do
        warn "#{caller[2]} SEND #{command.inspect}" if $DEBUG
        @io.puts JSON.dump(command)
      end
    end
  end

end
end
