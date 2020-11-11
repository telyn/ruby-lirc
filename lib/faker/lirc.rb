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
      #   Faker::Book.title #=> "SEND_ONCE"
      #
      # @faker.version 1.9.3
      def reply_type
        fetch('lirc.reply_type')
      end
    end
  end
end

I18n.load_path += ::Dir[::File.join(__dir__, '*.yml')]
