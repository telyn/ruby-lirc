require "lirc/reply"

RSpec.describe LIRC::Reply::ButtonPress do
  describe ".parse" do
    subject { described_class.parse(reply) }
    context "with one message" do
      let(:reply) { "0000000000f40bf0 00 KEY_UP ANIMAX" }
    end

    context "with a different message" do
      let(:reply) { "1234567890abcdef 325 R1 PS2" }

      it "parses the message correctly" do
        is_expected.to eq(described_class.new(0x1234567890abcdef, 325, "R1", "PS2"))
      end
    end
  end
end
