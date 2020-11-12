require "lirc/protocol"
require "faker/lirc"

class TestProtocol
  include LIRC::Protocol

  def messages
    @messages ||= []
  end

  def receive_message(message)
    messages << message
  end
end

RSpec.describe LIRC::Protocol do
  subject(:protocol) { TestProtocol.new }

  subject do
    Array(lines).each do |line|
      protocol.receive_line(line + "\n")
    end
  end

  context "when receiving a button press" do
    KNOWN_HEX_NUMBERS = [
      { hex: "deadbeef", number: 0xDEADBEEF },
      { hex: "cafed00d", number: 0xCAFED00D },
    ]
    let(:code) { KNOWN_HEX_NUMBERS.sample }
    let(:code_hex) { "00000000#{code[:hex]}" }
    let(:code_number) { code[:number] }
    let(:repeats) { Faker::Number.number(digits: 3) }
    let(:name) { Faker::LIRC.button_name }
    let(:remote_name) { Faker::LIRC.remote_name }
    let(:lines) { [code_hex, repeats, name, remote_name].join(" ") }

    it "emits send_message" do
      expect { subject }.to change(protocol, :messages).from([]).to([
        LIRC::Messages::ButtonPress.new(code_number, repeats, name, remote_name)
      ])
    end
  end

end
