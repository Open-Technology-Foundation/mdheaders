# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.3.0] - 2026-06-13

### Security
- Fixed arithmetic-evaluation command injection via `-l` / `-s` / `--levels=` /
  `--start-level=`. Option values are now validated as non-negative integers
  before any integer-context assignment, closing an arbitrary-code-execution
  vector (e.g. `--levels='HOME[$(cmd)]'`).

### Fixed
- Preserve a final line lacking a trailing newline (previously silently dropped;
  destructive with `--in-place`). Affects upgrade, downgrade and normalize.
- In-place edits now rewrite the existing file, preserving inode, mode, owner,
  symlinks and hardlinks (previously `mv` reset the mode to 0600 and replaced
  symlinks with regular files).
- Closing code fences honour the CommonMark run-length rule; a shorter fence no
  longer closes a longer one and corrupts code-block content.
- Lines with 7 or more leading `#` are treated as text, not headers.
- Indented ATX headers (1-3 leading spaces) are now recognised and shifted.
- Output is no longer discarded when every header is at a boundary; a no-op
  pass-through emits the content unchanged and exits 0.
- The temp file is no longer leaked on stdout/error runs (EXIT trap path fixed);
  cleanup is also signal-safe (SIGINT/SIGTERM) via a recursion-guarded handler.
- Backup (`-b`) refuses to overwrite an existing backup instead of destroying it.
- Bundled value-options (`-qlo`), `-l`/`-s` followed by another option,
  non-numeric values, and `-o <directory>` now produce a clean usage error
  (exit 2) instead of crashing.
- `normalize` no longer rejects `-l 0`; out-of-range `--start-level` exits 2 (was 1).
- `--stop-on-error` reports the aborting line even with `-q`.

### Added
- `--` end-of-options sentinel (filenames may begin with `-`).
- `tests/test_audit.sh` - 41-assertion regression suite covering the above.
- ShellCheck lint gate in `tests/run_all.sh`.

### Changed
- `-q` / `-v` set the `VERBOSE` flag directly; removed the dead verbosity gate.
- Exit code 1 now means "processing error"; an all-skipped no-op is success (0).
- Documented the ATX-only limitation (setext `===` / `---` left unchanged).

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

[1.3.0]: https://github.com/Open-Technology-Foundation/mdheaders/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/Open-Technology-Foundation/mdheaders/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/Open-Technology-Foundation/mdheaders/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Open-Technology-Foundation/mdheaders/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Open-Technology-Foundation/mdheaders/releases/tag/v1.0.0
