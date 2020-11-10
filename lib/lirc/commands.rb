# frozen_string_literal: true

module LIRC
  module Commands
    def self.all_commands
      constants.keep_if do |x|
        const_get(x).is_a?(Class)
      end.map(&method(:serialize_command_name))
    end

    def self.serialize_command_name(klass)
      klass = klass.to_s.split(":")[-1]
      rest = klass[1..-1].gsub(/[A-Z]/) do |chr|
        "_#{chr}"
      end
      "#{klass[0]}#{rest.upcase}"
    end

    module Base
      def serialize
        return serialize_type unless respond_to?(:members)

        "#{serialize_type} #{serialize_args}"
      end

      private

      def serialize_type
        Commands.serialize_command_name(self.class.name)
      end

      def serialize_args
        return "" unless respond_to?(:members)

        members.map(&method(:send)).compact.join(" ")
      end
    end

    SendOnce = Struct.new(:remote, :button, :repeats) { include Base }
    SendStart = Struct.new(:remote, :button) { include Base }
    SendStop = Struct.new(:remote, :button) { include Base }
    List = Struct.new(:remote) { include Base }
    SetInputlog = Struct.new(:path) { include Base }
    DrvOption = Struct.new(:key, :value) { include Base }
    Simulate = Struct.new(:key, :data) { include Base }
    SetTransmitters = Struct.new(:transmitter, :mask) { include Base }
    Version = Class.new { include Base }
  end
end
