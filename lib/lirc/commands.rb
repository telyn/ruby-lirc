# frozen_string_literal: true

module LIRC
  module Commands
    module Base
      def serialize
        "#{self.class.name} #{args}"
      end

      private

      def serialize_args
        members.map(&:send).compact.join(" ")
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
