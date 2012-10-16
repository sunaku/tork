require 'socket'
require 'thread'
require 'json'

module Tork
class Server

  SUPPORTS_ABSTRACT_NAMESPACE = RbConfig::CONFIG['host_os'] =~ /linux/i

  def self.address program=$0
    # try using abstract namespace for UNIX domain sockets; see unix(7)
    prefix = "\0#{Dir.pwd}/" if SUPPORTS_ABSTRACT_NAMESPACE
    "#{prefix}.#{program}.sock"
  end

  def initialize
    trap(:SIGTERM){ quit }

    # only JSON messages are supposed to be emitted on STDOUT
    # so make puts() in the user code write to STDERR instead
    stdout = STDOUT.dup
    STDOUT.reopen STDERR

    @clients = [STDIN]
    @readers = []
    @pid_by_reader = {}
    @writer_by_reader = {STDIN => stdout}
  end

  def loop
    @server = UNIXServer.open(Server.address)
    catch :quit do
      @readers << @server
      while @clients.include? STDIN
        IO.select(@readers + @clients).first.each do |reader|
          if reader.equal? @server
            @clients << reader.accept
          elsif (reader.eof? rescue true)
            @clients.delete reader
          elsif message = hear(reader, reader.gets)
            recv reader, message
          end
        end
      end
    end
  ensure
    # UNIX domain socket files are not deleted automatically upon closing
    File.delete @server.path if @server unless SUPPORTS_ABSTRACT_NAMESPACE
  end

  def quit
    throw :quit
  rescue ArgumentError
    # ignore "uncaught throw :quit" (ArgumentError)
  end

protected

  # On failure to decode the message, warns the sender and returns nil.
  def hear sender, message
    JSON.load message
  rescue JSON::ParserError => error
    tell sender, error
    nil
  end

  def recv client, command
    @command = command
    @client = client
    __send__(*command)
  rescue => error
    tell client, error
    nil
  end

  # If client is nil, then message is sent to all clients.
  def send client, message
    tell client, JSON.dump(message)
  end

  # If client is nil, then all clients are told.
  def tell client, message
    (client ? [client] : @clients).each do |target|
      if message.kind_of? Exception
        message = ["#{$0}: #{message.inspect}", *message.backtrace].join(?\n)
        target = STDERR if target == STDIN
      end

      if @writer_by_reader.key? target
        target = @writer_by_reader[target]
      end

      target.puts message
      target.flush
    end
  end

  def popen command
    # the `writer` writes to child's STDIN
    # the `reader` reads from child's STDOUT
    child_stdin, writer = IO.pipe
    reader, child_stdout = IO.pipe
    pid = spawn(command, 0 => child_stdin, 1 => child_stdout)

    @pid_by_reader[reader] = pid
    @writer_by_reader[reader] = writer
    @readers << reader

    reader
  end

  def pclose reader
    return unless @readers.delete reader
    reader.close

    writer = @writer_by_reader.delete(reader)
    writer.close

    pid = @pid_by_reader.delete(reader)
    Process.kill :SIGTERM, pid
    Process.wait pid # reap zombie
  end

end
end
