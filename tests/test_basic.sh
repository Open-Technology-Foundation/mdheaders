#!/bin/bash
set -euo pipefail

# Test script for basic mdheaders functionality

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

# Test 1: Basic upgrade
test_start "Basic upgrade by 1 level"
output=$("$CHMD" upgrade -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "## Main Title" ]] && [[ "$output" =~ "### Section One" ]]; then
  test_pass "Headers upgraded correctly"
else
  test_fail "Headers not upgraded correctly"
fi

# Test 2: Basic downgrade
test_start "Basic downgrade by 1 level"
output=$("$CHMD" downgrade -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "## Section One" ]]; then
  test_fail "H2 should become H1, not H2"
elif [[ "$output" =~ "# Section One" ]]; then
  test_pass "H2 correctly downgraded to H1"
else
  test_fail "Unexpected output"
fi

# Test 3: Code blocks preserved
test_start "Code blocks are preserved"
output=$("$CHMD" upgrade -q "$FIXTURES/sample1.md")
if [[ "$output" =~ $'```bash\n# This is a comment' ]]; then
  test_pass "Bash code block preserved"
else
  test_fail "Bash code block not preserved"
fi

if [[ "$output" =~ $'~~~python\n# Python comment' ]]; then
  test_pass "Python code block preserved"
else
  test_fail "Python code block not preserved"
fi

# Test 4: Multiple level upgrade
test_start "Upgrade by 2 levels"
output=$("$CHMD" upgrade -l 2 -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "### Main Title" ]] && [[ "$output" =~ "#### Section One" ]]; then
  test_pass "Multi-level upgrade works"
else
  test_fail "Multi-level upgrade failed"
fi

# Test 5: Edge cases - maximum level
test_start "Cannot upgrade beyond H6"
output=$("$CHMD" upgrade -q "$FIXTURES/edge_cases.md" 2>&1) || true
if [[ "$output" =~ "Already Maximum" ]]; then
  # H6 should remain H6
  if [[ "$output" =~ "###### Already Maximum" ]]; then
    test_pass "H6 remains H6 (not upgraded)"
  else
    test_fail "H6 was incorrectly modified"
  fi
else
  test_fail "Could not find test header"
fi

# Test 6: Edge cases - minimum level
test_start "Cannot downgrade below H1"
output=$("$CHMD" downgrade -q "$FIXTURES/edge_cases.md" 2>&1) || true
# H1 should remain H1
if [[ "$output" =~ "# Minimum Level Header" ]] && [[ "$output" =~ "# Back to H1" ]]; then
  test_pass "H1 remains H1 (not downgraded)"
else
  test_fail "H1 was incorrectly modified"
fi

# Test 7: In-place modification
test_start "In-place modification with backup"
temp_file=$(mktemp)
cp "$FIXTURES/sample1.md" "$temp_file"
"$CHMD" upgrade -i -b -q "$temp_file"

if [[ -f "${temp_file}.bak" ]]; then
  test_pass "Backup file created"
else
  test_fail "Backup file not created"
fi

if [[ -f "$temp_file" ]]; then
  content=$(<"$temp_file")
  if [[ "$content" =~ "## Main Title" ]]; then
    test_pass "In-place modification successful"
  else
    test_fail "In-place modification failed"
  fi
fi

rm -f "$temp_file" "${temp_file}.bak"

# Test 8: Output to file
test_start "Output to specified file"
temp_file=$(mktemp)
"$CHMD" downgrade -o "$temp_file" -q "$FIXTURES/sample1.md"

if [[ -f "$temp_file" ]]; then
  content=$(<"$temp_file")
  if [[ "$content" =~ "# Section One" ]]; then
    test_pass "Output to file successful"
  else
    test_fail "Output file content incorrect"
  fi
else
  test_fail "Output file not created"
fi

rm -f "$temp_file"

# Test 9: Help message
test_start "Help message"
if "$CHMD" --help &>/dev/null; then
  test_pass "Help message displayed"
else
  test_fail "Help message failed"
fi

# Test 10: Invalid arguments
test_start "Invalid arguments handling"
if ! "$CHMD" upgrade -l 0 "$FIXTURES/sample1.md" &>/dev/null; then
  test_pass "Rejects invalid level (0)"
else
  test_fail "Should reject level 0"
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
