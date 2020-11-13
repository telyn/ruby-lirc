require "lirc/messages/response_parser"

module LIRC
  # EventMachine Protocol for LIRC.
  #
  # Internally relies on Messages for parsing.
  # Can send Commands to LIRC with send_command.
  module Protocol
    def initialize(*args, **kwargs)
      @response_parser = nil
      super(*args, **kwargs)
    end

    def send_command(command)
      # TODO: implement
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
  end
end
