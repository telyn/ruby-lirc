require "lirc/messages"

module LIRC
  # EventMachine Protocol for LIRC.
  #
  # Internally relies on Messages for parsing.
  # Can send Commands to LIRC with send_command.
  module Protocol
    def initialize(*args, **kwargs)
      @message = nil
      super(*args, **kwargs)
    end

    def send_command(command)
      # TODO: implement
    end

    def receive_line(line)
      puts "parsing '#{line}'"
      line = line.chomp
      if @message
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
      @message ||= Response.new
      @message.parse_line(line)
      if @message.valid?
        receive_message(@message)
        @message = nil
      end
    end
  end
end
