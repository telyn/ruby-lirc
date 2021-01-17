# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2021-01-17

### Added
- Finally got round to writing a changelog.
- Released to rubygems.org
- First version released to Github releases
- 100% mutation coverage
- Note: Versions prior to 0.3.0 were never tagged, built, nor released.

### Changed
- Correctly specified rubies supported for the first time.
- Dropped support for Ruby 2.4

### Fixed
- Fixed issue where `LIRC::Messages::ResponseParser#parse_line` could return
  `ArgumentError` instead of `ParseError` in rare circumstances.


## [0.2.0] - 2020-ish [YANKED]

### Added

- `irsend` executable in `bin` dir, as an example for usage
- `LIRC::Protocol`, including response parsing and command-sending.
  `#send_command` returns an `EM::Deferrable` that succeeds/fails after the LIRC
  server responds.


## [0.1.0] - 2020-ish [YANKED]

### Added

- Sketch of project structure
- Note: A 0.1.0 release was never made (nor a tag) - so it has been marked as
  [YANKED] above.


[0.3.0]: https://github.com/telyn/ruby-lirc/releases/v0.3.0
