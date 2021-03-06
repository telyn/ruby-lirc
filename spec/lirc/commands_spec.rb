require "lirc/commands"

RSpec.describe LIRC::Commands do
  describe ".all_commands" do
    subject { LIRC::Commands.all_commands }

    it do
      expect(Set.new(subject)).to eq(
        Set.new(%w[
                  SEND_ONCE
                  SEND_START
                  SEND_STOP
                  LIST
                  SET_INPUTLOG
                  DRV_OPTION
                  SIMULATE
                  SET_TRANSMITTERS
                  VERSION
                ])
      )
    end
  end

  describe ".serialize_command_name" do
    subject { described_class.serialize_command_name(klass) }
    context "when klass has lots of capitals" do
      let(:klass) { "LIRC::Commands::HypotheticalFutureCommand" }

      it { is_expected.to eq "HYPOTHETICAL_FUTURE_COMMAND" }
    end

    context "when klass is a Class" do
      let(:klass) { LIRC::Commands::SendOnce }
      it { is_expected.to eq "SEND_ONCE" }
    end
  end
end

RSpec.describe LIRC::Commands::SendOnce do
  subject(:cmd) { described_class.new(remote, button, repeats) }

  let(:remote) { "cool_remote" }
  let(:button) { "eject" }

  describe "#serialize" do
    subject { cmd.serialize }
    context "when repeats is set" do
      let(:repeats) { "100" }

      it { is_expected.to eq "SEND_ONCE cool_remote eject 100" }
    end

    context "when repeats is unset" do
      let(:repeats) { nil }

      it { is_expected.to eq "SEND_ONCE cool_remote eject" }
    end
  end
end

RSpec.describe LIRC::Commands::Base do
  TestClass = Class.new { include LIRC::Commands::Base }
  TestStruct = Struct.new(:field_1, :field_2) { include LIRC::Commands::Base }

  describe "#serialize" do
    subject { instance.serialize }
    context "when included in TestClass" do
      let(:instance) { TestClass.new }
      it { is_expected.to eq "TEST_CLASS" }
    end

    context "when included in a Struct" do
      let(:instance) { TestStruct.new("value1", "value2") }
      it { is_expected.to eq "TEST_STRUCT value1 value2" }

      context "when one of the values was set to nil" do
        let(:instance) { TestStruct.new(nil, "value2") }
        it { is_expected.to eq "TEST_STRUCT value2" }

      end
    end
  end
end

RSpec.describe LIRC::Commands::SendStart do
  subject(:cmd) { described_class.new(remote, button) }

  let(:remote) { "cool_remote" }
  let(:button) { "eject" }

  describe "#serialize" do
    subject { cmd.serialize }

    it { is_expected.to eq "SEND_START cool_remote eject" }
  end
end

RSpec.describe LIRC::Commands::SendStop do
  subject(:cmd) { described_class.new(remote, button) }

  let(:remote) { "cool_remote" }
  let(:button) { "eject" }

  describe "#serialize" do
    subject { cmd.serialize }

    it { is_expected.to eq "SEND_STOP cool_remote eject" }
  end
end

# I literally don't care about the other commands.
# TODO: care about them
