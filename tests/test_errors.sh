#!/bin/bash
set -euo pipefail

# Test script for error handling and edge cases

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

# Test 1: Missing input file
test_start "Missing input file"
output=$("$CHMD" up nonexistent_file.md 2>&1) || true
if [[ "$output" =~ "File not found" ]]; then
  test_pass "Reports 'File not found'"
else
  test_fail "Should report 'File not found'"
fi

# Test 2: Multiple input files
test_start "Multiple input files rejected"
output=$("$CHMD" up "$FIXTURES/sample1.md" "$FIXTURES/edge_cases.md" 2>&1) || true
if [[ "$output" =~ "Multiple input files" ]]; then
  test_pass "Rejects multiple input files"
else
  test_fail "Should reject multiple input files"
fi

# Test 3: Empty file handling
test_start "Empty file handling"
temp_file=$(mktemp)
touch "$temp_file"
output=$("$CHMD" up -q "$temp_file" 2>&1) && result=0 || result=$?
if ((result == 0)) && [[ -z "$output" ]]; then
  test_pass "Empty file produces empty output"
else
  test_fail "Empty file handling failed"
fi
rm -f "$temp_file"

# Test 4: No headers in document (normalize)
test_start "Normalize with no headers"
temp_file=$(mktemp)
echo "Just plain text, no headers." > "$temp_file"
output=$("$CHMD" normalize -q "$temp_file" 2>&1) || true
if [[ "$output" =~ "No headers found" ]]; then
  test_pass "Reports 'No headers found'"
else
  test_fail "Should report 'No headers found'"
fi
rm -f "$temp_file"

# Test 5: Unclosed code block warning
test_start "Unclosed code block warning"
output=$("$CHMD" up "$FIXTURES/errors.md" 2>&1)
if [[ "$output" =~ "unclosed code block" ]]; then
  test_pass "Warns about unclosed code block"
else
  test_fail "Should warn about unclosed code block"
fi

# Test 6: Headers without space are NOT modified (correct markdown behavior)
test_start "Headers without space preserved (not valid markdown headers)"
output=$("$CHMD" up -q "$FIXTURES/errors.md")
if [[ "$output" =~ "##NoSpaceHeader" ]] && [[ "$output" =~ "###AlsoNoSpace" ]]; then
  test_pass "Non-standard headers preserved unchanged"
else
  test_fail "Non-standard headers should not be modified"
fi

# Test 7: Indented code fences recognized
test_start "Indented code fences recognized"
output=$("$CHMD" up -q "$FIXTURES/errors.md")
# The # inside the indented fence should NOT be upgraded
if [[ "$output" =~ "# This fence is indented" ]]; then
  test_pass "Indented fence content preserved"
else
  test_fail "Indented fence not recognized"
fi

# Test 8: Multi-level downgrade causing H1 violation
test_start "Multi-level downgrade with H1 violation"
output=$("$CHMD" down -l 2 "$FIXTURES/sample1.md" 2>&1) || true
# H1 can't go below 1, H2 would become 0 (invalid)
if [[ "$output" =~ "Cannot downgrade" ]]; then
  test_pass "Warns about H1 boundary violation"
else
  test_fail "Should warn about boundary violation"
fi

# Test 9: Multi-level upgrade causing H6 violation
test_start "Multi-level upgrade with H6 violation"
output=$("$CHMD" up -l 3 "$FIXTURES/edge_cases.md" 2>&1) || true
# H5 + 3 = H8 (invalid), H6 + 3 = H9 (invalid)
if [[ "$output" =~ "Cannot upgrade" ]]; then
  test_pass "Warns about H6 boundary violation"
else
  test_fail "Should warn about boundary violation"
fi

# Test 10: Nested fences (backticks inside tildes)
test_start "Nested fences handled correctly"
output=$("$CHMD" up -q "$FIXTURES/errors.md")
# The # inside the tilde block should NOT be upgraded
if [[ "$output" =~ "# Header inside tilde block" ]]; then
  test_pass "Nested fence content preserved"
else
  test_fail "Nested fence handling failed"
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
