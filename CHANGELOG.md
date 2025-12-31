# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.2.1] - 2025-12-31

### Added
- Extended test suite from 26 to 46 tests
- `test_errors.sh` - 10 tests for error paths and edge cases
- `test_options.sh` - 10 tests for options and command aliases
- `tests/run_all.sh` - unified test runner with summary
- `tests/fixtures/errors.md` - edge case test fixture

## [1.2.0] - 2025-12-31

### Added
- Unix manpage (`mdheaders.1`) with full documentation
- Bash completion (`mdheaders.bash_completion`) for commands, options, and files
- Behavior section in help text explaining code block handling
- GitHub URL in help output and script header

### Changed
- Standardized function docstrings with Args/Input/Output/Returns format
- Enhanced help text with clearer option descriptions
- README restructured with Quick Start sections at top

## [1.1.0] - 2025-12-31

### Added
- Quick install via curl one-liner
- From-source installation instructions
- `.gitignore` for local development files

### Changed
- README reorganized with quick starts first, technical content below
- Installation changed from symlink to direct copy
- Options displayed as markdown table instead of code block

## [1.0.0] - 2025-12-31

### Added
- Single-file architecture (merged `libmdheaders.bash` into `mdheaders`)
- `nullglob` to shopt settings for BCS compliance
- `#fin` markers to test fixture files

### Changed
- Replaced `seq` with pure bash parameter expansion for hash generation
- Moved local variable declarations outside loops
- Moved `s()` pluralizer function to script level (was nested)

### Removed
- `libmdheaders.bash` library file (merged into main script)
- Unused `y()` function
- Unused `remblanks()` function
- Unused `YELLOW` variable from test files

### Fixed
- Test scripts referencing non-existent `chmdheaders` (now `mdheaders`)
- Stale comments in test files

## [0.x] - Pre-release

Initial development with separate library file architecture.

[1.2.1]: https://github.com/Open-Technology-Foundation/mdheaders/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/Open-Technology-Foundation/mdheaders/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Open-Technology-Foundation/mdheaders/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Open-Technology-Foundation/mdheaders/releases/tag/v1.0.0
