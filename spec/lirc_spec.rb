# frozen_string_literal: true

RSpec.describe Lirc do
  it "has a version number" do
    expect(Lirc::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
