#!/bin/bash
set -euo pipefail

# Test script for option handling and command aliases

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

# Test 1: Version output
test_start "Version output (-V)"
version_output=$("$CHMD" --version)
if [[ "$version_output" =~ "mdheaders" ]] && [[ "$version_output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
  test_pass "Version displayed correctly"
else
  test_fail "Version output incorrect"
fi

# Test 2: Short version flag
test_start "Short version flag (-V)"
if "$CHMD" -V | grep -qE '[0-9]+\.[0-9]+\.[0-9]+'; then
  test_pass "Short -V flag works"
else
  test_fail "Short -V flag failed"
fi

# Test 3: Custom backup suffix
test_start "Custom backup suffix (--backup=.orig)"
temp_file=$(mktemp)
cp "$FIXTURES/sample1.md" "$temp_file"
"$CHMD" up -i --backup=.orig -q "$temp_file"

if [[ -f "${temp_file}.orig" ]]; then
  test_pass "Custom backup suffix works"
else
  test_fail "Custom backup suffix failed"
fi
rm -f "$temp_file" "${temp_file}.orig"

# Test 4: 'up' alias
test_start "'up' command alias"
output=$("$CHMD" up -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "## Main Title" ]]; then
  test_pass "'up' alias works"
else
  test_fail "'up' alias failed"
fi

# Test 5: 'down' alias
test_start "'down' command alias"
output=$("$CHMD" down -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "# Section One" ]]; then
  test_pass "'down' alias works"
else
  test_fail "'down' alias failed"
fi

# Test 6: Bundled options (-qib)
test_start "Bundled options (-qib)"
temp_file=$(mktemp)
cp "$FIXTURES/sample1.md" "$temp_file"
"$CHMD" up -qib "$temp_file"

if [[ -f "${temp_file}.bak" ]]; then
  content=$(<"$temp_file")
  if [[ "$content" =~ "## Main Title" ]]; then
    test_pass "Bundled -qib works"
  else
    test_fail "Bundled options modification failed"
  fi
else
  test_fail "Bundled options backup not created"
fi
rm -f "$temp_file" "${temp_file}.bak"

# Test 7: Verbose vs quiet output
test_start "Verbose output shows info"
output=$("$CHMD" up -v "$FIXTURES/sample1.md" 2>&1)
if [[ "$output" =~ "Processed" ]] || [[ "$output" =~ "header" ]]; then
  test_pass "Verbose mode shows processing info"
else
  test_fail "Verbose mode should show info"
fi

# Test 8: Quiet suppresses output
test_start "Quiet mode suppresses warnings"
output=$("$CHMD" up -q "$FIXTURES/edge_cases.md" 2>&1) || true
# In quiet mode, should not see warning markers (▲) from stderr
if [[ ! "$output" =~ "▲" ]]; then
  test_pass "Quiet mode suppresses warnings"
else
  test_fail "Quiet mode should suppress warnings"
fi

# Test 9: Long-form levels option
test_start "Long-form --levels option"
output=$("$CHMD" up --levels=2 -q "$FIXTURES/sample1.md")
if [[ "$output" =~ "### Main Title" ]]; then
  test_pass "--levels=N works"
else
  test_fail "--levels=N failed"
fi

# Test 10: Unknown option rejected
test_start "Unknown option rejected"
output=$("$CHMD" up --invalid-option "$FIXTURES/sample1.md" 2>&1) || true
if [[ "$output" =~ "Unknown option" ]]; then
  test_pass "Rejects unknown option"
else
  test_fail "Should reject unknown option"
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
