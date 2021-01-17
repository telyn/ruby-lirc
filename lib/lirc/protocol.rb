require "lirc/messages/response_parser"
require "logger"
require "eventmachine"

module LIRC
  DEFAULT_PORT = 8765
  # EventMachine Protocol for LIRC.
  #
  # Internally relies on Messages for parsing.
  # Can send Commands to LIRC with send_command.
  module Protocol
    include EventMachine::Protocols::LineProtocol

    def self.connect!(server:, port: DEFAULT_PORT, &block)
      EventMachine.connect(server, port, self, &block)
    end

    def initialize(*args, logger: Logger.new(STDERR), **kwargs)
      @logger = logger

      super(*args, **kwargs)
    end

    def send_command(command)
      send_data "#{command.serialize}\n"
      response_deferrables[command.serialize] ||= EM::DefaultDeferrable.new
    end

    def receive_line(line)
      line = line.chomp
      if @response_parser
        parse_message_line(line)
      elsif line.eql?("BEGIN")
        parse_message_line(line)
      elsif line =~ /^[0-9a-f]/
        receive_message(Messages::ButtonPress.parse(line))
      else
        logger.warn "Received unknown line from lirc: #{line}"
      end
    end

    private

    def parse_message_line(line)
      @response_parser ||= Messages::ResponseParser.new
      @response_parser.parse_line(line)
      if @response_parser.valid?
        msg = @response_parser.message
        resolve_response(msg)
        receive_message(msg) if respond_to?(:receive_message)
        @response_parser = nil
      end
    end

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

    attr_reader :logger
  end
end
