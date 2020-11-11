require "lirc/messages"
require "lirc/commands"

module LIRC
  module Messages
    class ResponseParser
      STATES = %i[waiting_begin
                  waiting_type
                  waiting_success
                  waiting_data
                  reading_data
                  valid].freeze

      PARSER_METHOD_FOR = {
        waiting_begin: :parse_begin,
        waiting_type: :parse_type,
        waiting_success: :parse_success,
        waiting_data: :parse_data,
        reading_data: :read_data,
        waiting_end: :parse_end,
        valid: :raise_already_valid,
      }.freeze

      attr_reader :message

      def initialize(state = :waiting_begin)
        @state = state
        @message = Response.new(nil, nil, nil)
      end

      # returns true when #message is ready
      def valid?
        @state == :valid
      end

      def parse_line(line)
        line = line.chomp
        unless (meth = PARSER_METHOD_FOR[@state])
          raise ParseError, "unknown state #{@state}"
        end

        send(meth, line)
      end

      private

      def parse_begin(line)
        unless line == "BEGIN"
          raise ParseError, "unexpected line, expecting BEGIN, got #{line}"
        end

        @state = :waiting_type
      end

      def parse_type(line)
        if LIRC::Commands.all_commands.include?(line)
          @message.type = line
          @state = :waiting_success
        elsif line == "SIGHUP"
          @message.type = line
          @state = :waiting_end
        else
          raise ParseError,
            "invalid type #{line}, expecting one of " \
            "LIRC::Commands.all_commands, or SIGHUP"
        end
      end

      def parse_success(line)
        unless %w[SUCCESS ERROR].include?(line)
          raise ParseError, "Expecting SUCCESS or ERROR, got #{line}"
        end

        @message.success = line == "SUCCESS"
        @state = :waiting_data
      end

      def parse_data(line)
        case line
        when "DATA"
          @state = :reading_data
        when "END"
          @state = :valid
        else
          raise ParseError, "Expecting DATA or END, got #{line}"
        end
      end

      def parse_end(line)
        unless line == "END"
          raise ParseError, "Expecting END, got #{line}"
        end

        @state = :valid
      end

      def read_data(line)
        @message.data ||= []

        if line == "END"
          @message.data = @message.data.join("\n").freeze
          @state = :valid
          return
        end

        @message.data << line.to_s
      end

      def raise_already_valid(_)
        raise ParseError,
          "Response was successfully parsed, " \
          "but #parse was called again with #{line}"
      end
    end
  end
end
