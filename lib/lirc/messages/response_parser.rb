require "lirc/messages"
require "lirc/commands"

module LIRC
  module Messages
    class ResponseParser
      STATES = %i[waiting_begin
                  waiting_command
                  waiting_success
                  waiting_data
                  waiting_data_length
                  reading_data
                  valid].freeze

      PARSER_METHOD_FOR = {
        waiting_begin: :parse_begin,
        waiting_command: :parse_command,
        waiting_success: :parse_success,
        waiting_data: :parse_data,
        waiting_data_length: :parse_data_length,
        reading_data: :read_data,
        waiting_end: :parse_end,
        valid: :raise_already_valid,
      }.freeze

      attr_reader :message

      def initialize(state = :waiting_begin)
        @state = state
        @message = Response.new
      end

      # returns true when #message is ready
      def valid?
        @state.equal?(:valid)
      end

      def parse_line(line)
        line = line.chomp

        __send__(PARSER_METHOD_FOR.fetch(@state), line)
      end

      private

      def parse_begin(line)
        unless line.eql?("BEGIN")
          raise ParseError, "unexpected line, expecting BEGIN, got #{line}"
        end

        @state = :waiting_command
      end

      def parse_command(line)
        if Commands.all_commands.include?(line.split.first)
          message.command = line
          @state = :waiting_success
        elsif line.eql?("SIGHUP")
          message.command = line
          @state = :waiting_end
        else
          raise ParseError,
            "invalid command #{line}, expecting first word to be one of " \
            "LIRC::Commands.all_commands, or SIGHUP"
        end
      end

      def parse_success(line)
        unless %w[SUCCESS ERROR].include?(line)
          raise ParseError, "Expecting SUCCESS or ERROR, got #{line}"
        end

        message.success = line.eql?("SUCCESS")
        @state = :waiting_data
      end

      def parse_data(line)
        case line
        when "DATA"
          @state = :waiting_data_length
        when "END"
          @state = :valid
        else
          raise ParseError, "Expecting DATA or END, got #{line}"
        end
      end

      def parse_data_length(line)
        if line.match?(/\A[^0-9]/)
          raise ParseError, "Expecting a number, got #{line}"
        end

        @data_lines_to_read = Integer(line)
        message.data = []
        @state = :reading_data
      end

      def parse_end(line)
        unless line.eql?("END")
          raise ParseError, "Expecting END, got #{line}"
        end

        @state = :valid
      end

      def read_data(line)
        if @data_lines_to_read.zero?
          unless line.eql?("END")
            raise ParseError, "Expecting END, got more data: '#{line}'"
          end

          message.data = message.data&.join("\n").freeze
          @state = :valid
          return
        end

        message.data ||= []

        @data_lines_to_read -= 1
        message.data << line
      end

      def raise_already_valid(line)
        raise ParseError,
          "Response was successfully parsed, " \
          "but #parse was called again with #{line}"
      end
    end
  end
end
