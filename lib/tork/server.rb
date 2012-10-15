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
    @stdout = STDOUT.dup
    STDOUT.reopen(STDERR).sync = true

    @clients = [STDIN]
  end

  def loop
    @server = UNIXServer.open(Server.address)
    catch :quit do
      while @clients.include? STDIN
        IO.select([@server, *@clients]).first.each do |reader|
          if reader.equal? @server
            @clients << reader.accept
          elsif (reader.eof? rescue true)
            @clients.delete reader
          elsif message = hear(client, reader.gets)
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
  end

protected

  # On failure to decode the message, warns the sender and returns nil.
  def hear sender, message
    JSON.load message
  rescue JSON::ParserError => error
    tell sender, "#{$0}: #{error.inspect}", STDERR
    nil
  end

  def recv client, command
    @command = command
    @client = client
    __send__(*command)
  rescue => error
    message = error.backtrace.unshift("#{$0}: #{error.inspect}").join("\n")
    tell reader, message, STDERR
  end

  # If client is nil, then message is sent to all clients.
  def send client, message
    tell client, JSON.dump(message)
  end

  # If client is nil, then all clients are told.
  def tell client, message, output_for_STDIN=@stdout
    (client ? [client] : @clients).each do |target|
      target = output_for_STDIN if target == STDIN
      target.puts message
      target.flush
    end
  end

  def popen *args
    child = IO.popen(*args)
    @clients << child
    child
  end

  def pclose child
    @clients.delete child and child.close
  end

end
end
