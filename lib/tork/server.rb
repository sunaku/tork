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
    @servers = []
  end

  def loop
    server = UNIXServer.open(Server.address)
    @servers << server
    catch :quit do
      while @clients.include? STDIN
        IO.select(@servers + @clients).first.each do |stream|
          @client = stream

          if stream == server
            @clients << stream.accept

          elsif (stream.eof? rescue true)
            @clients.delete stream

          elsif @command = hear(stream, stream.gets)
            recv stream, @command
          end
        end
      end
    end
  ensure
    # UNIX domain socket files are not deleted automatically upon closing
    File.delete server.path if server
  end

  def quit
    throw :quit
  end

protected

  # On failure to decode the message, warns the sender and returns nil.
  def hear sender, message
    JSON.load message
  rescue JSON::ParserError => error
    # accept non-JSON "command lines" from clients
    if @clients.include? sender
      Shellwords.split message

    # forward tell() output from servers to clients
    elsif @servers.include? sender
      tell @clients, message, false
      nil

    else
      tell sender, error
      nil
    end
  end

  def recv client, command
    __send__(*command)
  rescue => error
    tell client, error
    nil
  end

  def send one_or_more_clients, message
    tell one_or_more_clients, JSON.dump(message), false
  end

  def tell one_or_more_clients, message, prefix=true
    if message.kind_of? Exception
      message = [message.inspect, message.backtrace]
    end

    if prefix
      message = Array(message).join("\n").gsub(/^/, "#{$0}: ")
    end

    targets =
      if one_or_more_clients.kind_of? IO
        [one_or_more_clients]
      else
        Array(one_or_more_clients)
      end

    targets.each do |target|
      target = @stdout if target == STDIN
      target.puts message
      target.flush
    end
  end

  def popen command
    child = IO.popen(command, 'r+')
    @servers << child
    child
  end

  def pclose child
    return unless @servers.delete child

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
