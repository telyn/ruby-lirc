# frozen_string_literal: true

RSpec.describe LIRC do
  it "has a version number" do
    expect(LIRC::VERSION).to match(/^\d+\.\d+\.\d+$/)
  end
end
