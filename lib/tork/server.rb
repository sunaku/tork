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

    @server = UNIXServer.open(Server.address)
    @clients = []
  end

  def loop
    catch :quit do
      @clients.unshift STDIN
      while @clients.include? STDIN
        IO.select([@server, *@clients]).first.each do |reader|
          if reader.equal? @server
            @clients << reader.accept
            next
          elsif reader.eof?
            @clients.delete reader
            next
          end

          begin
            command = JSON.load(reader.gets)
          rescue JSON::ParserError => error
            send_error_to reader, "#{$0}: #{error.inspect}"
            next
          end

          method = command.first
          unless respond_to? method and method != __method__.to_s # prevent recursion
            send_error_to reader, "#{$0}: illegal command: #{method}"
            next
          end

          @command = command
          @client = reader
          begin
            __send__(*command)
          rescue => error
            send_error_to reader, error.backtrace.
              unshift("#{$0}: #{error.inspect}").join("\n")
          end
        end
      end
    end
  end

  def quit
    throw :quit
  end

protected

  def send message
    send_raw JSON.dump(message)
  end

private

  def send_raw message
    @clients.each {|c| send_raw_to c, message }
  end

  def send_raw_to client, message, output_for_STDIN=@stdout
    client = output_for_STDIN if client == STDIN
    client.puts message
    client.flush
  end

  def send_error_to client, message
    send_raw_to client, message, STDERR
  end

end
end
