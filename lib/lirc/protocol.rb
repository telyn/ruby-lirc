require "lirc/messages/response_parser"

module LIRC
  # EventMachine Protocol for LIRC.
  #
  # Internally relies on Messages for parsing.
  # Can send Commands to LIRC with send_command.
  module Protocol
    include EventMachine::Protocols::LineProtocol

    def self.connect!(server:, port: 8765, &block)
      EventMachine.connect(server, port, self, &block)
    end

    def initialize(*args, **kwargs)
      @response_parser = nil
      super(*args, **kwargs)
    end

    def self.included(klass)
      klass.instance_exec { include EventMachine::Protocols::LineProtocol }
    end

    def send_command(command)
      send_data "#{command.serialize}\n"
      response_deferrables[command.serialize] ||= EM::DefaultDeferrable.new
    end

    def receive_line(line)
      line = line.chomp
      if @response_parser
        parse_message_line(line)
      elsif line == "BEGIN"
        parse_message_line(line)
      elsif line =~ /^[0-9a-f]/
        receive_message(Messages::ButtonPress.parse(line))
      else
        STDERR.puts "Received unknown line from lirc: #{line}"
      end
    end

    def parse_message_line(line)
      @response_parser ||= Messages::ResponseParser.new
      @response_parser.parse_line(line)
      if @response_parser.valid?
        msg = @response_parser.message
        resolve_response(msg) if msg.is_a? Messages::Response
        receive_message(msg) if defined?(receive_message)
        @response_parser = nil
      end
    end

    private

    # resolve here means like Promises - Deferrables are pretty much promises
    def resolve_response(response)
      deferrable = response_deferrables[response.command]
      return if deferrable.nil?

      if response.success
        deferrable.succeed(response)
      else
        deferrable.fail(response)
      end
      response_deferrables.delete(response.command)
    end

    def response_deferrables
      @response_deferrables ||= {}
    end
  end
end
