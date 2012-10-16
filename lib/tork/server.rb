require 'socket'
require 'thread'
require 'json'
require 'shellwords'

module Tork
class Server

  def self.address program=$0
    ".#{program}.sock"
  end

  def initialize
    # only JSON messages are supposed to be emitted on STDOUT
    # so make puts() in the user code write to STDERR instead
    @stdout = STDOUT.dup
    STDOUT.reopen STDERR

    @clients = [STDIN]
    @readers = []
  end

  def loop
    @server = UNIXServer.open(Server.address)
    catch :quit do
      @readers << @server
      while @clients.include? STDIN
        IO.select(@readers + @clients).first.each do |reader|
          @client = reader
          if reader.equal? @server
            @clients << reader.accept
          elsif (reader.eof? rescue true)
            @clients.delete reader
          else
            @message = reader.gets
            if @command = hear(reader, @message)
              recv reader, @command
            end
          end
        end
      end
    end
  ensure
    # UNIX domain socket files are not deleted automatically upon closing
    File.delete @server.path if @server
  end

  def quit
    throw :quit
  end

protected

  JSON_REGEXP = /\A\s*[\[\{]/.freeze

  # On failure to decode the message, warns the sender and returns nil.
  def hear sender, message
    if message =~ JSON_REGEXP
      JSON.load message

    # accept non-JSON "command lines" from clients
    elsif @clients.include? sender
      Shellwords.split message

    # forward tell() output from children to clients
    elsif @readers.include? sender
      tell nil, message, false
      nil
    end
  rescue JSON::ParserError => error
    tell sender, error
    nil
  end

  def recv client, command
    __send__(*command)
  rescue => error
    tell client, error
    nil
  end

  # If client is nil, then message is sent to all clients.
  def send client, message
    tell client, JSON.dump(message), false
  end

  # If client is nil, then all clients are told.
  def tell client, message, prefix=true
    (client ? [client] : @clients).each do |target|
      if message.kind_of? Exception
        message = [message.inspect, message.backtrace]
        target = STDERR if target == STDIN
      end

      target = @stdout if target == STDIN
      target.print "#{$0}: " if prefix
      target.puts message
      target.flush
    end
  end

  def popen command
    child = IO.popen(command, 'r+')
    @readers << child
    child
  end

  def pclose child
    return unless @readers.delete child

    # this should be enough to stop programs that use Tork::Server#loop
    # because their IO.select() loop terminates on the closing of STDIN
    child.close_write

    # but some programs like tork-herald(1) need to be killed explicitly
    # because they do not follow this convention of exiting on STDIN close
    Process.kill :SIGTERM, child.pid
    Process.waitpid child.pid

    # this will block until the child process has exited so we must kill it
    # explicitly (as above) to ensure that this program does not hang here
    child.close_read
  end

end
end
