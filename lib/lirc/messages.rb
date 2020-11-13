module LIRC
  # LIRC has three kinds of messages.
  #
  # ButtonPresses are sent by LIRCD to a LIRC client - these notify the client
  #   that LIRCD has received an IR button press from some remote.
  #
  # Commands are sent by a LIRC client to LIRCD to get it to do something (e.g.
  #   transmit an IR button press, or send back a Response containing a list of
  #   remotes it supports)
  #
  # Responses are sent by LIRCD to a LIRC client - usually in response to a
  #   Command (hence the name), but there is a special type - SIGHUP - which is
  #   sent whenever the LIRCD process receives a SIGHUP
  #
  # To make life easier (if not the conceptual model of this library) - the
  # Messages module deals with ButtonPresses and Responses (things received from
  # LIRCD), but Commands live in their own LIRC::Commands module
  module Messages
    class ParseError < StandardError; end

    # Responses are received over the socket in response to Commands
    Response = Struct.new(:command, :success, :data)

    # code is the hex code sent by the remote
    # button is the name of the button (if found in lircd.conf)
    # remote is the name of the remote (if found)
    ButtonPress = Struct.new(:code, :repeat_count, :button, :remote) do
      def self.parse(line)
        bits = line.split(" ")
        if bits[0] =~ /[^0-9a-fA-F]/ || bits[1] =~ /[^0-9]/
          raise ParseError, "invalid button press message '#{line}'"
        end

        # convert hex chars to an integer
        bits[0] = bits[0].to_i(16)
        bits[1] = bits[1].to_i
        new(*bits)
      end
    end
  end
end

require "lirc/messages/response_parser"
