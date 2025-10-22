# chmdheaders

A Bash tool for manipulating markdown header levels while preserving code blocks.

## Features

- **Upgrade** headers: Increase header levels (e.g., `#` → `##`)
- **Downgrade** headers: Decrease header levels (e.g., `##` → `#`)
- **Normalize** headers: Auto-detect minimum level and normalize to target (e.g., force H2 start)
- **Code block awareness**: Preserves fenced code blocks (``` and ~~~)
- **Flexible output**: stdout, file, or in-place modification
- **Safety features**: Validates H1-H6 boundaries, optional backups
- **Library + CLI**: Reusable functions and command-line interface

## Installation

```bash
# Make executable
chmod +x chmdheaders

# Optionally, symlink to a directory in your PATH
ln -s $(pwd)/chmdheaders /usr/local/bin/chmdheaders
```

## Usage

### Basic Commands

```bash
# Upgrade all headers by 1 level
chmdheaders upgrade README.md

# Downgrade all headers by 1 level
chmdheaders downgrade README.md

# Normalize document to start at H2 (auto-detect current minimum)
chmdheaders normalize --start-level=2 README.md

# Short forms
chmdheaders up file.md
chmdheaders down file.md
chmdheaders norm -s 2 file.md
```

### Options

```
-l, --levels=N         Number of levels to shift (default: 1)
-s, --start-level=N    Target starting level for normalize (default: 1)
-o, --output=FILE      Output file (default: stdout)
-i, --in-place         Modify file in-place
-b, --backup[=SUFFIX]  Create backup before in-place edit (default: .bak)
--skip-errors          Skip invalid headers with warning (default)
--stop-on-error        Abort on first invalid header
-q, --quiet            Suppress warnings and progress messages
-h, --help             Show help message
```

### Examples

```bash
# Upgrade by 2 levels, output to stdout
chmdheaders upgrade -l 2 doc.md

# Downgrade in-place with backup
chmdheaders down -i -b doc.md

# Custom backup suffix
chmdheaders up -i -b.orig README.md

# Save to new file
chmdheaders upgrade -o NEW.md OLD.md

# Quiet mode (suppress warnings)
chmdheaders down -q doc.md

# Stop on first error
chmdheaders up --stop-on-error doc.md

# Normalize to H2 (auto-detect current minimum and adjust)
chmdheaders normalize --start-level=2 doc.md

# Normalize in-place with backup
chmdheaders norm -s 2 -i -b doc.md

# Force H3 start, skip errors if some headers would exceed H6
chmdheaders norm -s 3 --skip-errors doc.md
```

## How It Works

### State Machine Algorithm

The tool uses a state machine to track whether it's inside a code block:

1. **Track code fences**: Detects ``` and ~~~ fences
2. **Match fence types**: Ensures closing fence matches opening type
3. **Process headers**: Only modifies headers outside code blocks
4. **Preserve content**: Maintains exact formatting and whitespace

### Normalize Feature

The `normalize` command automatically adjusts all headers to start at a specified level:

1. **First pass**: Scans document to detect minimum header level (e.g., H1, H2, etc.)
2. **Calculate delta**: Determines how many levels to shift (target - current_min)
3. **Second pass**: Applies the delta to all headers using existing upgrade/downgrade logic

**Example workflow**:
- Document has headers: H1, H2, H3, H4
- You run: `chmdheaders normalize --start-level=2 doc.md`
- Result: All headers shift up by 1 (H2, H3, H4, H5)

This is useful for:
- Normalizing documents from different sources
- Ensuring consistent header hierarchy
- Preparing documents for inclusion in larger documents

### Validation Rules

- **Downgrade**: Cannot go below H1 (`#`)
- **Upgrade**: Cannot exceed H6 (`######`)
- **Invalid headers**: Skipped by default with warning (use `--stop-on-error` to abort)

### What Gets Preserved

◉ Code blocks (fenced with ``` or ~~~)
◉ Code comments containing `#`
◉ Inline code with backticks
◉ Exact whitespace after `#` symbols
◉ All non-header content

## Library Usage

Source the library in your own Bash scripts:

```bash
#!/bin/bash
source /path/to/libchmdheaders.bash

# Upgrade by 1 level
chmd_upgrade 1 "skip" 0 < input.md > output.md

# Downgrade by 2 levels, stop on error, quiet mode
chmd_downgrade 2 "stop" 1 < input.md > output.md

# Normalize to H2, skip errors, quiet mode
chmd_normalize 2 "skip" 1 < input.md > output.md
```

### Library Functions

#### `chmd_upgrade LEVELS [ERROR_MODE] [QUIET]`
Increase header levels by N.

**Arguments:**
- `LEVELS` - Number of levels to upgrade (required)
- `ERROR_MODE` - "skip" or "stop" (default: "skip")
- `QUIET` - 0=verbose, 1=quiet (default: 0)

#### `chmd_downgrade LEVELS [ERROR_MODE] [QUIET]`
Decrease header levels by N.

**Arguments:**
- `LEVELS` - Number of levels to downgrade (required)
- `ERROR_MODE` - "skip" or "stop" (default: "skip")
- `QUIET` - 0=verbose, 1=quiet (default: 0)

#### `chmd_normalize TARGET_LEVEL [ERROR_MODE] [QUIET]`
Normalize document to start at specified header level.

**Arguments:**
- `TARGET_LEVEL` - Desired minimum header level 1-6 (required)
- `ERROR_MODE` - "skip" or "stop" (default: "skip")
- `QUIET` - 0=verbose, 1=quiet (default: 0)

**Behavior:**
- Detects current minimum header level
- Calculates delta needed to reach target
- Applies delta to all headers

#### `chmd_detect_min_level`
Detect the minimum header level in a document.

**Arguments:** None

**Returns:**
- Outputs minimum level (1-6) to stdout
- Returns 0 if headers found, 1 if no headers

## Testing

Run the test suites:

```bash
# Basic upgrade/downgrade tests (12 tests)
./tests/test_basic.sh

# Normalize functionality tests (14 tests)
./tests/test_normalize.sh

# Run all tests
./tests/test_basic.sh && ./tests/test_normalize.sh
```

Test fixtures are in `tests/fixtures/`:
- `sample1.md` - Basic markdown with code blocks
- `edge_cases.md` - Boundary conditions and edge cases

## Exit Codes

- `0` - Success
- `1` - Error or all headers skipped
- `2` - Invalid arguments

## Limitations

- Only handles fenced code blocks (``` and ~~~), not indented code blocks
- Doesn't process inline code spans for headers
- Assumes well-formed markdown (unclosed fences will be detected but may produce unexpected results)

## License

See repository license.

## Author

Gary Dean (Biksu Okusi)
Okusi Group

#fin
