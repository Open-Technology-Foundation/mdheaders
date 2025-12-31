# mdheaders

Manipulate markdown header levels while preserving code blocks.

## Quick Start

```bash
sudo curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/mdheaders/main/mdheaders -o /usr/local/bin/mdheaders && sudo chmod +x /usr/local/bin/mdheaders
```

```bash
mdheaders up README.md       # Upgrade:   # → ##
mdheaders down README.md     # Downgrade: ## → #
mdheaders norm -s 2 doc.md   # Normalize to start at H2
```

## Installation

### Quick Install

```bash
sudo curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/mdheaders/main/mdheaders -o /usr/local/bin/mdheaders && sudo chmod +x /usr/local/bin/mdheaders
```

### From Source

```bash
git clone https://github.com/Open-Technology-Foundation/mdheaders.git
cd mdheaders

# Install script
sudo cp mdheaders /usr/local/bin/

# Install manpage (optional)
sudo cp mdheaders.1 /usr/share/man/man1/

# Install bash completion (optional)
sudo cp mdheaders.bash_completion /etc/bash_completion.d/mdheaders
```

## Commands

| Command | Alias | Action |
|---------|-------|--------|
| `upgrade` | `up` | Increase header levels (`#` → `##`) |
| `downgrade` | `down` | Decrease header levels (`##` → `#`) |
| `normalize` | `norm` | Auto-adjust all headers to target level |

## Options

| Option | Description |
|--------|-------------|
| `-l, --levels=N` | Number of levels to shift (default: 1) |
| `-s, --start-level=N` | Target starting level for normalize (default: 1) |
| `-o, --output=FILE` | Output file (default: stdout) |
| `-i, --in-place` | Modify file in-place |
| `-b, --backup[=SUFFIX]` | Create backup before in-place edit (default: .bak) |
| `--skip-errors` | Skip invalid headers with warning (default) |
| `--stop-on-error` | Abort on first invalid header |
| `-q, --quiet` | Suppress warnings and progress messages |
| `-v, --verbose` | Show detailed processing information (default) |
| `-h, --help` | Show help message |
| `-V, --version` | Show version |

## Examples

### Basic Operations

```bash
# Upgrade all headers by 1 level
mdheaders upgrade README.md

# Downgrade all headers by 1 level
mdheaders downgrade README.md

# Upgrade by 2 levels
mdheaders upgrade -l 2 doc.md

# Normalize to start at H2
mdheaders normalize --start-level=2 doc.md
```

### In-Place Editing

```bash
# Modify file in-place
mdheaders up -i doc.md

# In-place with backup (.bak)
mdheaders down -i -b doc.md

# In-place with custom backup suffix
mdheaders up -i -b.orig README.md

# Bundled short options
mdheaders up -ib doc.md
```

### Output Control

```bash
# Output to stdout (default)
mdheaders upgrade doc.md

# Save to new file
mdheaders upgrade -o NEW.md OLD.md

# Quiet mode (suppress warnings)
mdheaders down -q doc.md
```

### Error Handling

```bash
# Skip invalid headers with warning (default)
mdheaders up --skip-errors doc.md

# Abort on first invalid header
mdheaders up --stop-on-error doc.md
```

## Features

- **Upgrade** headers: Increase header levels (e.g., `#` → `##`)
- **Downgrade** headers: Decrease header levels (e.g., `##` → `#`)
- **Normalize** headers: Auto-detect minimum level and normalize to target
- **Code block awareness**: Preserves fenced code blocks (``` and ~~~)
- **Flexible output**: stdout, file, or in-place modification
- **Safety features**: Validates H1-H6 boundaries, optional backups
- **Single-file**: Self-contained script with no dependencies

## How It Works

### State Machine Algorithm

The tool uses a state machine to track whether it's inside a code block:

1. **Track code fences**: Detects ``` and ~~~ fences
2. **Match fence types**: Ensures closing fence matches opening type
3. **Process headers**: Only modifies headers outside code blocks
4. **Preserve content**: Maintains exact formatting and whitespace

### Normalize Algorithm

The `normalize` command uses a two-pass approach:

1. **First pass**: Scan document to detect minimum header level
2. **Calculate delta**: Determine shift needed (target - current_min)
3. **Second pass**: Apply delta to all headers

**Example**:
- Document has: H1, H2, H3, H4
- Run: `mdheaders normalize --start-level=2 doc.md`
- Result: H2, H3, H4, H5 (all shifted up by 1)

### Validation Rules

- **Downgrade**: Cannot go below H1 (`#`)
- **Upgrade**: Cannot exceed H6 (`######`)
- **Invalid headers**: Skipped by default (use `--stop-on-error` to abort)

### What Gets Preserved

- Code blocks (fenced with ``` or ~~~)
- Code comments containing `#`
- Inline code with backticks
- Exact whitespace after `#` symbols
- All non-header content

## Development

### Requirements

- Bash 5.0+ (uses `${var@Q}` quoting, `local --`)
- Standard coreutils (`mktemp`, `cp`, `mv`, `cat`)

### Testing

```bash
# Basic upgrade/downgrade tests (12 tests)
./tests/test_basic.sh

# Normalize functionality tests (14 tests)
./tests/test_normalize.sh

# Run all tests
./tests/test_basic.sh && ./tests/test_normalize.sh
```

Test fixtures are in `tests/fixtures/`.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error or all headers skipped |
| 2 | Invalid arguments |

## Limitations

- Only handles fenced code blocks (``` and ~~~), not indented code blocks
- Doesn't process inline code spans for headers
- Assumes well-formed markdown (unclosed fences may produce unexpected results)

## License

GPL-3. See [LICENSE](LICENSE).

## Author

Biksu Okusi
Okusi Group
