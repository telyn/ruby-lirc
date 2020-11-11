require "lirc/messages/response_parser"
require "faker"
require "faker/lirc"

RSpec.describe LIRC::Messages::ResponseParser do
  subject(:parser) { described_class.new(state) }

  let(:state) { :waiting_begin }

  describe "full parser lifecycle" do
    subject(:parser) { described_class.new }
    subject { parser.message }

    before { message.each { |line| parser.parse_line(line + "\n") } }
    let(:message) { [] }
    Response = LIRC::Messages::Response

    context "when message is a SIGHUP" do
      let(:message) { %w[BEGIN SIGHUP END] }

      it { is_expected.to eq Response.new("SIGHUP", nil, nil) }
    end

    context "when message is a LIST" do
      let(:message) { %w[BEGIN LIST SUCCESS DATA REMOTE_ONE REMOTE_TWO END] }

      it { is_expected.to eq Response.new("LIST", true, "REMOTE_ONE\nREMOTE_TWO") }
    end

    context "when message is an SEND_ONCE failure" do
      let(:message) { %w[BEGIN SEND_ONCE ERROR END] }

      it { is_expected.to eq Response.new("SEND_ONCE", false, nil) }
    end

    context "when message is a VERSION response with an empty data section" do
      let(:message) { %w[BEGIN VERSION SUCCESS DATA END] }

      it { is_expected.to eq Response.new("VERSION", true, "") }
    end
  end

  describe ".parse_line" do
    subject { parser.parse_line(line) }

    # per the usual recommendations from sandi metz et al, if this describe
    # block becomes a burden to altering the message parser due to peeking
    # inside the parser's instance variables, delete it. It was helpful when I
    # wrote the parser :-)
    describe "internals" do
      shared_examples_for "raises parse error" do
        it "raises parse error" do
          expect { subject }.to raise_error(LIRC::Messages::ParseError)
        end

        it "does not change state" do
          expect { subject rescue nil }.not_to change { parser.instance_variable_get(:@state) }
        end

        it "does not change message" do
          expect { subject rescue nil }.not_to change(parser, :message)
        end
      end

      shared_examples_for "changes state" do |to:|
        it "changes state to #{to}" do
          expect { subject }.to(
            change { parser.instance_variable_get(:@state) }.to(to)
          )
        end
      end

      shared_examples_for "raises parse error except when line is" do |*situations|
        unless situations.include? :begin
          context "when line is 'BEGIN'" do
            let(:line) { "BEGIN" }

            include_examples "raises parse error"
          end
        end

        unless situations.include? :type
          context "when line is some type" do
            let(:line) { Faker::LIRC.reply_type }

            include_examples "raises parse error"
          end

          context "when line is 'SIGHUP'" do
            let(:line) { "SIGHUP" }

            include_examples "raises parse error"
          end
        end

        unless situations.include? :success
          context "when line is 'SUCCESS'" do
            let(:line) { "SUCCESS" }

            include_examples "raises parse error"
          end

          context "when line is 'ERROR'" do
            let(:line) { "ERROR" }

            include_examples "raises parse error"
          end
        end

        unless situations.include? :data
          context "when line is 'DATA'" do
            let(:line) { "DATA" }

            include_examples "raises parse error"
          end
        end

        unless situations.include? :arbitrary_text
          context "when line is 'ham sandwich protocol initiated'" do
            let(:line) { "ham sandwich protocol initiated" }

            include_examples "raises parse error"
          end
        end

        unless situations.include? :end
          context "when line is 'END'" do
            let(:line) { "END" }

            include_examples "raises parse error"
          end
        end
      end

      context "when state is waiting_begin" do
        let(:state) { :waiting_begin }

        include_examples "raises parse error except when line is",
                         :begin

        context "when line is 'BEGIN'" do
          let(:line) { "BEGIN" }

          include_examples "changes state", to: :waiting_type

          it "does not change message" do
            expect { subject }.not_to change(parser, :message)
          end
        end
      end

      context "when state is waiting_type" do
        let(:state) { :waiting_type }

        include_examples "raises parse error except when line is",
                         :type

        context "when line is some type" do
          let(:line) { Faker::LIRC.reply_type }

          include_examples "changes state", to: :waiting_success

          it "changes message type" do
            expect { subject }.to change(parser.message, :type).to(line)
          end

          it "does not change message success" do
            expect { subject }.not_to change(parser.message, :success)
          end

          it "does not change message data" do
            expect { subject }.not_to change(parser.message, :data)
          end
        end

        context "when line is SIGHUP" do
          let(:line) { "SIGHUP" }

          include_examples "changes state", to: :waiting_end

          it "changes message type" do
            expect { subject }.to change(parser.message, :type).to(line)
          end

          it "does not change message success" do
            expect { subject }.not_to change(parser.message, :success)
          end

          it "does not change message data" do
            expect { subject }.not_to change(parser.message, :data)
          end
        end
      end

      context "when state is waiting_success" do
        let(:state) { :waiting_success }

        include_examples "raises parse error except when line is",
                         :success

        context "when line is SUCCESS" do
          let(:line) { "SUCCESS" }

          include_examples "changes state", to: :waiting_data

          it "doesn't change message type" do
            expect { subject }.not_to change(parser.message, :type)
          end

          it "does not change message success" do
            expect { subject }.to change(parser.message, :success).to(true)
          end

          it "does not change message data" do
            expect { subject }.not_to change(parser.message, :data)
          end
        end

        context "when line is ERROR" do
          let(:line) { "ERROR" }

          include_examples "changes state", to: :waiting_data

          it "doesn't change message type" do
            expect { subject }.not_to change(parser.message, :type)
          end

          it "does not change message success" do
            expect { subject }.to change(parser.message, :success).to(false)
          end

          it "does not change message data" do
            expect { subject }.not_to change(parser.message, :data)
          end
        end
      end

      context "when state is waiting_data" do
        let(:state) { :waiting_data }

        include_examples "raises parse error except when line is",
                         :data,
                         :end

        context "when line is DATA" do
          let(:line) { "DATA" }

          include_examples "changes state", to: :reading_data

          it "does not change message type" do
            expect { subject }.not_to change(parser.message, :type)
          end

          it "does not change message success" do
            expect { subject }.not_to change(parser.message, :success)
          end

          it "does not change message data" do
            expect { subject }.not_to change { parser.message.data || [] }
          end
        end

        context "when line is END" do
          let(:line) { "END" }

          include_examples "changes state", to: :valid

          it "does not change message type" do
            expect { subject }.not_to change(parser.message, :type)
          end

          it "does not change message success" do
            expect { subject }.not_to change(parser.message, :success)
          end

          it "does not change message data" do
            expect { subject }.not_to change(parser.message, :data)
          end
        end
      end

      context "when state is reading_data" do
        let(:state) { :reading_data }

        lines = %w[BEGIN SIGHUP SUCCESS ERROR DATA] + [Faker::LIRC.reply_type]
        lines.each do |line|
          context "when line is '#{line}'" do
            let(:line) { line }
            it "does not change state" do
              expect { subject rescue nil }.not_to change { parser.instance_variable_get(:@state) }
            end

            it "does not change message type" do
              expect { subject }.not_to change(parser.message, :type)
            end

            it "does not change message success" do
              expect { subject }.not_to change(parser.message, :success)
            end

            it "changes message data" do
              expect { subject }.to change { parser.message.data }.to([line])
            end
          end
        end

        context "when line is 'something I forgot about ham'" do
          let(:line) { "something I forgot about ham" }

          it "does not change state" do
            expect { subject rescue nil }.not_to change { parser.instance_variable_get(:@state) }
          end

          it "does not change message type" do
            expect { subject }.not_to change(parser.message, :type)
          end

          it "does not change message success" do
            expect { subject }.not_to change(parser.message, :success)
          end

          context "when there's not any data yet" do
            it "changes message data" do
              expect { subject }.to change { parser.message.data }.to(["something I forgot about ham"])
            end
          end

          context "when theres some data already" do
            before(:each) do
              parser.message.data = (1 + rand(5)).times
                                                 .map { Faker::Lorem.sentence }
            end

            it "doesn't mess with the old lines" do
              orig_count = parser.message.data.length
              expect { subject }.not_to change { parser.message.data[0...orig_count] }
            end

            it "adds new line" do
              expect { subject }.to change { parser.message.data.length }.by(1)
              expect(parser.message.data.last).to eq "something I forgot about ham"
            end
          end
        end

        context "when line is END" do
          let(:line) { "END" }

          include_examples "changes state", to: :valid

          it "does not change message type" do
            expect { subject }.not_to change(parser.message, :type)
          end

          it "does not change message success" do
            expect { subject }.not_to change(parser.message, :success)
          end

          context "when data is empty array" do
            it "finalises data into an empty string" do
              expect { subject }.to change(parser.message, :data).to("")
            end
          end

          context "when there's lots of data" do
            before { parser.message.data = [ "hey!", "", "how ya doing?" ] }

            it "finalises data" do
              expect { subject }.to change(parser.message, :data).to("hey!\n\nhow ya doing?")
            end
          end
        end
      end

      context "when state is waiting_end" do
        let(:state) { :waiting_end }

        include_examples "raises parse error except when line is",
                         :end

        context "when line is END" do
          let(:line) { "END" }

          include_examples "changes state", to: :valid

          it "does not change message type" do
            expect { subject }.not_to change(parser, :message)
          end
        end
      end
    end
  end
end
