module Faker
  # LIRC-related faker stuff
  class LIRC < Base
    class << self
      ##
      # Produces a random LIRC response type
      #
      # @return [String]
      #
      # @example
      #   Faker::LIRC.button_name #=> "KEY_GREEN"
      def button_name
        fetch('lirc.button_name')
      end

      ##
      # Produces a random LIRC response type
      #
      # @return [String]
      #
      # @example
      #   Faker::LIRC.remote_name #=> "RMT-V189-KARAOKE"
      def remote_name
        fetch('lirc.remote_name')
      end

      ##
      # Produces a random LIRC response type
      #
      # @return [String]
      #
      # @example
      #   Faker::LIRC.reply_type #=> "SEND_ONCE"
      def reply_type
        fetch('lirc.reply_type')
      end

      ##
      # Produces a random LIRC response success
      #
      # @return [String]
      #
      # @example
      #   Faker::LIRC.reply_type #=> "SUCCESS"
      def reply_success
        fetch('lirc.reply_success')
      end
    end
  end
end

I18n.load_path += ::Dir[::File.join(__dir__, '*.yml')]
