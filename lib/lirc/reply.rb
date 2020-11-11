module LIRC
  module Reply
    class ParseError < StandardError; end
    # code is the hex code sent by the remote
    # button is the name of the button (if found in lircd.conf)
    # remote is the name of the remote (if found)
    ButtonPress = Struct.new(:code, :repeat_count, :button, :remote) do
      def self.parse(line)
        bits = line.split(" ")
        if bits[0] =~ /[^0-9a-f]/ || bits[1] =~ /[^0-9]/
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
