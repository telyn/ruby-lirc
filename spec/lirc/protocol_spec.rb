require "lirc/protocol"
require "faker/lirc"

module InitializeArgsTestModule
  def initialize(*args, **kwargs)
    @args = args
    @kwargs = kwargs
  end

  attr_reader :args, :kwargs
end

class TestProtocol
  include InitializeArgsTestModule
  include LIRC::Protocol

  def messages
    @messages ||= []
  end

  def send_data(data)
    sent_data << data
  end

  def sent_data
    @sent_data ||= []
  end
end

class ReceiveMessageTestProtocol < TestProtocol
  include LIRC::Protocol

  def receive_message(message)
    messages << message
  end
end


def fake_command(message)
  double(LIRC::Commands::Base).tap do |c|
    allow(c).to receive(:serialize).and_return(message)
  end
end

RSpec.describe LIRC::Protocol do
  subject(:protocol) { TestProtocol.new(logger: logger) }
  Messages = LIRC::Messages
  let(:logger) { instance_double(Logger) }

  # this is a simple sense-check that ensures that LineProtocol works
  # the receive_line method does .chomp just in case LineProtocol's semantics
  # change, which is why a_string_including is used in this test - to avoid
  # tying the test to those semantics.
  it "when included in another class, also includes LineProtocol" do
    expect(protocol).to respond_to(:receive_data)
    expect(protocol).to receive(:receive_line).with(a_string_including("jeff"))
    protocol.receive_data("j")
    protocol.receive_data("e")
    protocol.receive_data("f")
    protocol.receive_data("f")
    protocol.receive_data("\n")
  end

  describe ".connect!" do
    let(:server) { "server" }
    let(:port) { 1111 }

    it "calls EventMachine.connect correctly" do
      block = -> (_a, b, _c) { }
      expect(EventMachine).to(receive(:connect)
        .with(server, port, described_class) do |*args, &blk|
          expect(blk).to equal(block)
        end)
      described_class.connect!(server: server, port: port, &block)
    end

    context "when port is not specified" do
      it "calls EventMachine.connect correctly" do
        expect(EventMachine).to(receive(:connect)
          .with(server, LIRC::DEFAULT_PORT, described_class))
        described_class.connect!(server: server)
      end
    end
  end

  describe "#initialize" do
    subject { TestProtocol.new(*args, **params) }
    let(:params) { { logger: logger, server: "127.0.0.1", port: "8765" } }
    let(:expected) { params.dup.tap { |p| p.delete(:logger) } }
    let(:args) { ["this is a test"] }

    it "passes everything except the logger up to EM" do
      expect(subject.kwargs).to eq(expected)
      expect(subject.args).to eq(args)
    end

    it "sets logger to logger" do
      expect(subject.send(:logger)).to eq params[:logger]
    end

    context "when logger is not set" do
      let(:params) { {} }
      let(:args) { [] }

      let(:logger) { instance_double(Logger) }
      before { allow(Logger).to receive(:new).and_return(logger).once }

      it "defaults logger to one which uses STDERR" do
        subject
        expect(Logger).to have_received(:new).with(STDERR)
        expect(subject.send(:logger)).to eq(logger)
      end
    end
  end

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
    describe "mockist style" do
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
          expect(protocol).to receive(:receive_message).with(
            Messages::ButtonPress.new(code_number, repeats, name, remote_name)
          ).once
          subject
        end
      end

      context "when receiving some text" do
        let(:line) { "fake message here" }
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
            allow(parser).to receive(:message).and_return(message) if valid
          end
        end

        before do
          allow(Messages::ResponseParser).to receive(:new).and_return(parser)
        end

        context "when message is not begun yet" do
          let(:valid) { false }

          context "when line is BEGIN" do
            let(:line) { "BEGIN" }

            it "calls #parse_line" do
              subject
              expect(parser).to have_received(:parse_line).with(line).once
            end

            context "when it's in response to a prior command" do
              let(:command) { fake_command(original_command) }
              let!(:deferrable) do
                protocol.send_command(command).tap do |d|
                  allow(d).to receive(:succeed)
                  allow(d).to receive(:fail)
                end
              end

              it "doesn't call the deferrable" do
                subject
                expect(deferrable).not_to have_received(:succeed)
                expect(deferrable).not_to have_received(:fail)
              end
            end
          end

          context "when line is gibberish" do
            let(:line) { "gibberish" }

            it "warns" do
              expect(logger).to receive(:warn).with("Received unknown line from lirc: gibberish")
              subject
            end
          end
        end

        context "when message is already begun" do
          let(:parser) do
            instance_double(Messages::ResponseParser).tap do |parser|
              allow(parser).to receive(:valid?).and_return(false, valid)
              allow(parser).to receive(:parse_line).with("BEGIN").once
              allow(parser).to receive(:parse_line).with(line).once
              allow(parser).to receive(:message).and_return(message) if valid
            end
          end

          before do
            protocol.receive_line("BEGIN\n")
          end

          context "when this line makes the message valid" do
            let(:valid) { true }

            it "calls #parse_line" do
              subject
              expect(parser).to have_received(:parse_line).with(line)
            end

            context "when protocol has #receive_message" do
              let(:protocol) { TestProtocol.new(logger: logger) }

              it "calls #receive_message" do
                allow(protocol).to receive(:receive_message)
                subject
                expect(protocol).to have_received(:receive_message).with(message)
              end
            end

            context "when there's a different command waiting for a response" do
              let!(:deferrable) do
                protocol.send_command(fake_command("floobyjoob")).tap do |d|
                  allow(d).to receive(:succeed)
                  allow(d).to receive(:fail)
                end
              end

              it "doesn't call the deferrable" do
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
                  let(:first_parser) do
                    instance_double(Messages::ResponseParser).tap do |parser|
                      allow(parser).to receive(:valid?).and_return(false, true)
                      allow(parser).to receive(:parse_line).with("BEGIN").once
                      allow(parser).to receive(:parse_line).with(line).once
                      allow(parser).to receive(:message).and_return(message) if valid
                    end
                  end

                  before do
                    allow(Messages::ResponseParser).to receive(:new).and_return(first_parser, parser)
                    protocol.receive_line(line + "\n")
                    protocol.receive_line("BEGIN")
                  end

                  it "doesn't call deferrable" do
                    subject
                    expect(deferrable).to have_received(:succeed).once
                    expect(deferrable).not_to have_received(:fail)
                  end
                end
              end
            end
          end

          context "when this line does not make message valid" do
            let(:valid) { false }

            it "calls #parse_line" do
              subject
              expect(parser).to have_received(:parse_line).with(line)
            end

            context "when it's in response to a prior command" do
              let(:command) { fake_command(original_command) }
              let!(:deferrable) do
                protocol.send_command(command).tap do |d|
                  allow(d).to receive(:succeed)
                  allow(d).to receive(:fail)
                end
              end
            end
          end
        end
      end
    end
  end
end
