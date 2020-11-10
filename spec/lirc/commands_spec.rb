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
