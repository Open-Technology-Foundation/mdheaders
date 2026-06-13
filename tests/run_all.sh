#!/bin/bash
set -euo pipefail

# Unified test runner for mdheaders

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

declare -a failed_suites=()

run_suite() {
  local -- suite="$1"
  local -- name="${suite##*/}"

  printf '\n%b━━━ %s ━━━%b\n' "$CYAN" "$name" "$NC"

  if "$suite"; then
    return 0
  else
    failed_suites+=("$name")
    return 1
  fi
}

printf '%b%s%b\n' "$CYAN" "╔═══════════════════════════════════════╗" "$NC"
printf '%b%s%b\n' "$CYAN" "║     mdheaders Test Suite Runner       ║" "$NC"
printf '%b%s%b\n' "$CYAN" "╚═══════════════════════════════════════╝" "$NC"

# Lint gate: ShellCheck must be clean (CLAUDE.md mandate)
printf '\n%b━━━ shellcheck ━━━%b\n' "$CYAN" "$NC"
if command -v shellcheck &>/dev/null; then
  if shellcheck -x "$SCRIPT_DIR/../mdheaders" "$SCRIPT_DIR"/*.sh; then
    printf '%b  ✓ shellcheck clean%b\n' "$GREEN" "$NC"
  else
    failed_suites+=('shellcheck')
  fi
else
  printf '%b  ▲ shellcheck not installed; skipping%b\n' "$CYAN" "$NC"
fi

# Run all test suites
run_suite "$SCRIPT_DIR/test_basic.sh" || true
run_suite "$SCRIPT_DIR/test_normalize.sh" || true
run_suite "$SCRIPT_DIR/test_errors.sh" || true
run_suite "$SCRIPT_DIR/test_options.sh" || true
run_suite "$SCRIPT_DIR/test_audit.sh" || true

# Final summary
printf '\n%b%s%b\n' "$CYAN" "═══════════════════════════════════════" "$NC"
printf '%b%s%b\n' "$CYAN" "           FINAL SUMMARY" "$NC"
printf '%b%s%b\n' "$CYAN" "═══════════════════════════════════════" "$NC"

if ((${#failed_suites[@]} == 0)); then
  printf '%b✓ All test suites passed!%b\n' "$GREEN" "$NC"
  exit 0
else
  printf '%b✗ Failed suites: %s%b\n' "$RED" "${failed_suites[*]}" "$NC"
  exit 1
fi

#fin
