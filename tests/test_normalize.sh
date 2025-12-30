#!/bin/bash
set -euo pipefail

# Test script for normalize functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHMD="$SCRIPT_DIR/../mdheaders"
FIXTURES="$SCRIPT_DIR/fixtures"

declare -i passed=0
declare -i failed=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test helper functions
test_start() {
  printf '\n%s\n' "Testing: $1"
}

test_pass() {
  printf '%b%s%b\n' "$GREEN" "  ✓ $1" "$NC"
  ((passed+=1))
}

test_fail() {
  printf '%b%s%b\n' "$RED" "  ✗ $1" "$NC"
  ((failed+=1))
}

# Test 1: Basic normalize to H2
test_start "Normalize sample1.md to H2"
output=$("$CHMD" normalize -s 2 -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "## Main Title" ]] && [[ "$output" =~ "### Section One" ]]; then
  test_pass "Headers normalized to start at H2"
else
  test_fail "Headers not normalized correctly"
fi

# Test 2: Normalize using short form
test_start "Normalize using 'norm' alias"
output=$("$CHMD" norm -s 2 -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "## Main Title" ]]; then
  test_pass "'norm' alias works"
else
  test_fail "'norm' alias failed"
fi

# Test 3: Code blocks still preserved
test_start "Code blocks preserved during normalize"
output=$("$CHMD" normalize -s 2 -q "$FIXTURES/sample1.md")
if [[ "$output" =~ $'```bash\n# This is a comment' ]]; then
  test_pass "Code blocks preserved"
else
  test_fail "Code blocks not preserved"
fi

# Test 4: Already at target level
test_start "Document already at target level"
output=$("$CHMD" normalize -s 1 "$FIXTURES/sample1.md" 2>&1)
if [[ "$output" =~ "already normalized" ]] && [[ "$output" =~ "# Main Title" ]]; then
  test_pass "Correctly detects already normalized document"
else
  test_fail "Failed to detect already normalized document"
fi

# Test 5: Normalize to H3
test_start "Normalize to H3"
output=$("$CHMD" norm -s 3 -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "### Main Title" ]] && [[ "$output" =~ "#### Section One" ]]; then
  test_pass "Normalized to H3"
else
  test_fail "Failed to normalize to H3"
fi

# Test 6: Detect correct minimum level
test_start "Detection of minimum level"
output=$("$CHMD" normalize -s 2 "$FIXTURES/sample1.md" 2>&1)
if [[ "$output" =~ "Detected minimum level: H1" ]]; then
  test_pass "Correctly detected H1 as minimum"
else
  test_fail "Failed to detect minimum level"
fi

# Test 7: Edge case - would exceed H6
test_start "Normalize that would exceed H6"
output=$("$CHMD" normalize -s 3 "$FIXTURES/edge_cases.md" 2>&1)
if [[ "$output" =~ "Cannot upgrade H6" ]] || [[ "$output" =~ "Cannot upgrade H5" ]]; then
  test_pass "Correctly warns about H6 boundary"
else
  test_fail "Failed to warn about H6 boundary"
fi

# Test 8: Skip errors mode (default)
test_start "Skip errors mode (default)"
"$CHMD" normalize -s 3 "$FIXTURES/edge_cases.md" -q >/dev/null && result=0 || result=$?
if ((result == 0)); then
  test_pass "Skip errors mode allows completion"
else
  test_fail "Skip errors mode failed"
fi

# Test 9: Stop on error mode
test_start "Stop on error mode"
"$CHMD" normalize -s 3 --stop-on-error "$FIXTURES/edge_cases.md" -q >/dev/null 2>&1 && result=0 || result=$?
if ((result != 0)); then
  test_pass "Stop on error mode halts on boundary violation"
else
  test_fail "Stop on error mode should have failed"
fi

# Test 10: In-place modification
test_start "In-place normalize with backup"
temp_file=$(mktemp)
cp "$FIXTURES/sample1.md" "$temp_file"
"$CHMD" normalize -s 2 -i -b -q "$temp_file"

if [[ -f "${temp_file}.bak" ]]; then
  test_pass "Backup created"
else
  test_fail "Backup not created"
fi

if [[ -f "$temp_file" ]]; then
  content=$(<"$temp_file")
  if [[ "$content" =~ "## Main Title" ]]; then
    test_pass "In-place normalize successful"
  else
    test_fail "In-place normalize failed"
  fi
fi

rm -f "$temp_file" "${temp_file}.bak"

# Test 11: Output to file
test_start "Normalize with output to file"
temp_file=$(mktemp)
"$CHMD" normalize -s 2 -o "$temp_file" -q "$FIXTURES/sample1.md"

if [[ -f "$temp_file" ]]; then
  content=$(<"$temp_file")
  if [[ "$content" =~ "## Main Title" ]]; then
    test_pass "Output to file successful"
  else
    test_fail "Output file content incorrect"
  fi
else
  test_fail "Output file not created"
fi

rm -f "$temp_file"

# Test 12: Invalid target level
test_start "Invalid target level (0)"
if ! "$CHMD" normalize -s 0 "$FIXTURES/sample1.md" -q &>/dev/null; then
  test_pass "Rejects invalid level 0"
else
  test_fail "Should reject level 0"
fi

# Test 13: Invalid target level (7)
test_start "Invalid target level (7)"
if ! "$CHMD" normalize -s 7 "$FIXTURES/sample1.md" -q &>/dev/null; then
  test_pass "Rejects invalid level 7"
else
  test_fail "Should reject level 7"
fi

# Summary
printf '\n%s\n' "================================"
printf '%bPassed: %d%b\n' "$GREEN" "$passed" "$NC"
if ((failed > 0)); then
  printf '%bFailed: %d%b\n' "$RED" "$failed" "$NC"
  exit 1
else
  printf '%bAll tests passed!%b\n' "$GREEN" "$NC"
  exit 0
fi

#fin
