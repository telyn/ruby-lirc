require "lirc/messages"

module LIRC
  # EventMachine Protocol for LIRC.
  #
  # Internally relies on Messages for parsing.
  # Can send Commands to LIRC with send_command.
  module Protocol
    def initialize(*args, **kwargs)
      @receiving_message = false
      @message = ""
      super(*args, **kwargs)
    end

    def send_command(command)
    end

    def receive_line(line)
      line = line.chomp
      if @receiving_message
        receive_message_line(line)
      elsif line == "BEGIN"
        @receiving_message = true
        receive_message_line(line)
      elsif line =~ /^[0-9a-f]/
        receive_button_press(line)
      else
        STDERR.puts "Received unknown line from lirc: #{line}"
      end
    end

    def receive_button_press(line)
      received_button_press(ButtonPress.parse(line))
    end

    def receive_message_line(line)
      @message += line
      if line == "END"
        @receiving_message = false
        received_message(Message.parse(@message))
      end
      @message = ""
    end

    def received_message(message)
      case message.type
      when :sighup
        received_sighup
      else
        received_reply(message)
      end
    end
  end
end
