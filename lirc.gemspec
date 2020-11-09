# frozen_string_literal: true

require_relative "lib/lirc/version"

Gem::Specification.new do |spec|
  spec.name          = "lirc"
  spec.version       = Lirc::VERSION
  spec.authors       = ["Telyn Z."]
  spec.email         = ["175827+telyn@users.noreply.github.com"]

  spec.summary       = "lirc client library (focused on sending ir signals"
  spec.homepage      = "https://github.com/telyn/ruby-lirc"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/telyn/ruby-lirc"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
