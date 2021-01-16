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

  def send_data(data)
    sent_data << data
  end

  def sent_data
    @sent_data ||= []
  end
end

def fake_command(message)
  double(LIRC::Commands::Base).tap do |c|
    allow(c).to receive(:serialize).and_return(message)
  end
end

RSpec.describe LIRC::Protocol do
  subject(:protocol) { TestProtocol.new }
  Messages = LIRC::Messages

  describe "#send_command" do
    subject { protocol.send_command(command) }

    context "with a Command" do
      let(:command) { fake_command(message) }
      let(:message) { "test message" }

      it "returns a deferrable" do
        is_expected.to be_a(EM::Deferrable)
      end

      it "sends the data" do
        expect { subject }.to change(protocol.sent_data, :size).from(0).to(1)
        expect(protocol.sent_data.first).to eq "test message\n"
      end
    end
  end

  describe "#receive_line" do
    describe "new style" do
      subject { protocol.receive_line(line + "\n") }

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
        let(:line) { [code_hex, repeats, name, remote_name].join(" ") }

        it "emits send_message" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::ButtonPress.new(code_number, repeats, name, remote_name)
          ])
        end
      end


      context "when receiving some text" do
        let(:line) { "BEGIN" }
        let(:original_command) { "main screen turn on" }
        let(:message) do
          Messages::Response.new(original_command, success, data)
        end
        let(:success) { true }
        let(:data) { "" }

        let(:parser) do
          instance_double(Messages::ResponseParser).tap do |parser|
            allow(parser).to receive(:valid?).and_return(valid)
            allow(parser).to receive(:parse_line).with(line)
            allow(parser).to receive(:message).and_return(message)
          end
        end

        before do
          allow(Messages::ResponseParser).to receive(:new).and_return(parser)
        end

        context "when this validates the message" do
          let(:valid) { true }

          it "calls #receive_message" do
            allow(protocol).to receive(:receive_message)
            subject
            expect(protocol).to have_received(:receive_message).with(message)
          end

          context "when there's a different command waiting for a response" do
            let!(:deferrable) do
              protocol.send_command(fake_command("floobyjoob")).tap do |d|
                allow(d).to receive(:succeed)
                allow(d).to receive(:fail)
              end
            end

            it "doesn't calls the deferrable" do
              subject
              expect(deferrable).not_to have_received(:succeed)
              expect(deferrable).not_to have_received(:fail)
            end
          end

          context "when it's in response to a prior command" do
            let(:command) { fake_command(original_command) }
            let!(:deferrable) do
              protocol.send_command(command).tap do |d|
                allow(d).to receive(:succeed)
                allow(d).to receive(:fail)
              end
            end

            context "when success is false" do
              let(:success) { false }
              it "calls the deferrable" do
                subject
                expect(deferrable).to have_received(:fail).with(message)
                expect(deferrable).not_to have_received(:succeed)
              end

            end

            context "when success is true" do
              let(:success) { true }
              it "calls the deferrable" do
                subject
                expect(deferrable).to have_received(:succeed).with(message)
                expect(deferrable).not_to have_received(:fail)
              end

              context "when prior command has had a response already" do
                before { protocol.receive_line(line + "\n") }

                it "doesn't call deferrable" do
                  subject
                  expect(deferrable).to have_received(:succeed).once
                  expect(deferrable).not_to have_received(:fail)
                end
              end
            end
          end
        end
      end
    end

    xdescribe "integration" do
      subject do
        Array(lines).each do |line|
          protocol.receive_line(line + "\n")
        end
      end

      let(:cmd) { Commands::SendOnce.new(*(lines[1].split(" ")[1..])) }

      context "when receiving a SEND_ONCE response" do
        context "with repeats" do
          let(:lines) do
            ["BEGIN", "SEND_ONCE PS2 Reset 10", success, "END"]
          end
          let(:success) { Faker::LIRC.reply_success }

          it "emits Response" do
            expect { subject }.to change(protocol, :messages).from([]).to([
              Messages::Response.new("SEND_ONCE PS2 Reset 10", success == "SUCCESS", nil)
            ])
          end
        end

        context "without repeats" do
          let(:lines) do
            ["BEGIN", "SEND_ONCE PS2 Reset", success, "END"]
          end
          let(:success) { Faker::LIRC.reply_success }

          it "emits Response" do
            expect { subject }.to change(protocol, :messages).from([]).to([
              Messages::Response.new("SEND_ONCE PS2 Reset", success == "SUCCESS", nil)
            ])
          end
        end
      end

      context "when receiving a SIGHUP response" do
        let(:lines) do
          ["BEGIN", "SIGHUP", "END"]
        end
        let(:success) { Faker::LIRC.reply_success }

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("SIGHUP", nil, nil)
          ])
        end
      end

      context "when receiving a SEND_START response" do
        let(:lines) do
          ["BEGIN", "SEND_START PS2 Reset", success, "END"]
        end
        let(:success) { Faker::LIRC.reply_success }

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("SEND_START PS2 Reset", success == "SUCCESS", nil)
          ])
        end
      end

      context "when receiving a SEND_STOP response" do
        let(:lines) do
          ["BEGIN", "SEND_STOP PS2 Reset", success, "END"]
        end
        let(:success) { Faker::LIRC.reply_success }

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("SEND_STOP PS2 Reset", success == "SUCCESS", nil)
          ])
        end
      end

      context "when receiving a LIST response" do
        context "when response lists remotes" do
          let(:lines) do
            ["BEGIN", "LIST", success, "DATA", items.length.to_s, items, "END"].flatten
          end

          let(:success) { Faker::LIRC.reply_success }

          context "with 6 items" do
            let(:items) { 6.times.map { Faker::LIRC.remote_name } }

            it "emits Response" do
              expect { subject }.to change(protocol, :messages).from([]).to([
                Messages::Response.new("LIST", success == "SUCCESS", items.join("\n"))
              ])
            end
          end

          context "with 0 items" do
            let(:items) { [] }

            it "emits Response" do
              expect { subject }.to change(protocol, :messages).from([]).to([
                Messages::Response.new("LIST", success == "SUCCESS", "")
              ])
            end
          end
        end

        context "when response lists buttons" do
          let(:lines) do
            ["BEGIN", "LIST PS2", success, "DATA", items.length.to_s, items, "END"].flatten
          end

          let(:success) { Faker::LIRC.reply_success }

          context "with 6 items" do
            let(:items) do
              <<~BUTTONS.split("\n")
            0000000000068b5b KEY_OPEN
            00000000000a8b5b Reset
            0000000000026b92 KEY_AUDIO
            00000000000acb92 Shuffle
            0000000000000b92 KEY_1
            0000000000080b92 KEY_2
              BUTTONS
            end

            it "emits Response" do
              expect { subject }.to change(protocol, :messages).from([]).to([
                Messages::Response.new("LIST PS2", success == "SUCCESS", items.join("\n"))
              ])
            end
          end

          context "with 0 items" do
            let(:items) { [] }

            it "emits Response" do
              expect { subject }.to change(protocol, :messages).from([]).to([
                Messages::Response.new("LIST PS2", success == "SUCCESS", "")
              ])
            end
          end
        end
      end

      context "when receiving a SET_INPUTLOG response" do
        let(:lines) do
          ["BEGIN", "SET_INPUTLOG", success, "END"].flatten
        end
        let(:success) { Faker::LIRC.reply_success }

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("SET_INPUTLOG", success == "SUCCESS", nil)
          ])
        end
      end

      context "when receiving a DRV_OPTION response" do
        let(:lines) do
          ["BEGIN", "DRV_OPTION", success, "END"].flatten
        end
        let(:success) { Faker::LIRC.reply_success }

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("DRV_OPTION", success == "SUCCESS", nil)
          ])
        end
      end

      context "when receiving a SIMULATE response" do
        let(:lines) do
          ["BEGIN",
           "SIMULATE 0000111144443333 1 TEST TEST",
           "ERROR",
           "DATA",
           "1",
           "SIMULATE command is disabled",
           "END"].flatten
        end

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("SIMULATE 0000111144443333 1 TEST TEST", false, "SIMULATE command is disabled")
          ])
        end
      end

      context "when receiving a SET_TRANSMITTERS response" do
        let(:lines) do
          ["BEGIN", "SET_TRANSMITTERS", success, "END"].flatten
        end
        let(:success) { Faker::LIRC.reply_success }

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("SET_TRANSMITTERS", success == "SUCCESS", nil)
          ])
        end
      end

      context "when receiving a VERSION response" do
        let(:lines) do
          ["BEGIN", "VERSION", success, "DATA", "1", "0.10.1", "END"].flatten
        end
        let(:success) { Faker::LIRC.reply_success }

        it "emits Response" do
          expect { subject }.to change(protocol, :messages).from([]).to([
            Messages::Response.new("VERSION", success == "SUCCESS", "0.10.1")
          ])
        end
      end
    end
  end
end
