require "lirc/messages/response_parser"

module LIRC
  # EventMachine Protocol for LIRC.
  #
  # Internally relies on Messages for parsing.
  # Can send Commands to LIRC with send_command.
  module Protocol
    include EventMachine::Protocols::LineProtocol
    def initialize(*args, **kwargs)
      @response_parser = nil
      super(*args, **kwargs)
    end

    def self.included(klass)
      klass.instance_exec { include EventMachine::Protocols::LineProtocol }
    end

    def send_command(command)
      send_data "#{command.serialize}\n"
      message_deferrables[command.serialize] ||= EM::DefaultDeferrable.new
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
        receive_message(@response_parser.message)
        @response_parser = nil
      end
    end

    private

    # resolve here means like Promises - Deferrables are pretty much promises
    def resolve_message(message)
      deferrable = message_deferrables[message]
      return if deferrable.nil?

      if message.success
        deferrable.fail(message)
      else
        deferrable.succeed(message)
      end
    end

    def message_deferrables
      @message_deferrables ||= {}
    end
  end
end
