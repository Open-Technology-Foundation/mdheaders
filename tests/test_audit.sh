#!/bin/bash
# Regression suite for the 2026-06-13 audit findings (AUDIT-BASH.md).
# Each assertion pins a confirmed defect; run RED before the fix, GREEN after.
set -uo pipefail
shopt -s extglob

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHMD="$SCRIPT_DIR/../mdheaders"

TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT   # L19: trap-based cleanup

declare -i passed=0 failed=0
RED=$'\033[0;31m' GREEN=$'\033[0;32m' NC=$'\033[0m'

ok() { printf '%b  ✓ %s%b\n' "$GREEN" "$1" "$NC"; passed+=1; }
no() { printf '%b  ✗ %s%b\n' "$RED" "$1" "$NC"; failed+=1; }

# run ARGS... -> globals OUT, ERR, RC (streams captured separately: M13/M14)
OUT='' ERR='' RC=0
run() { OUT=$("$CHMD" "$@" 2>"$TMPD/e"); RC=$?; ERR=$(<"$TMPD/e"); }

F="$TMPD/doc.md"
mk()  { printf '%s\n' "$@" > "$F"; }   # newline-terminated fixture
mkn() { printf '%s' "$1" > "$F"; }     # NO trailing newline

printf '\n=== Audit regression suite ===\n'

# --- C1 / H1 / M9 / M10: arithmetic-eval injection + numeric validation -----
mk '# Title'
for opt in '--levels=' '--start-level='; do
  s="$TMPD/PWNED"; rm -f "$s"
  cmd=up; [[ $opt == --start* ]] && cmd=norm
  run "$cmd" "${opt}HOME[\$(touch $s)]" "$F"
  if [[ ! -e $s ]]; then ok "C1 injection blocked via $opt"; else no "C1 injection blocked via $opt"; fi
  if ((RC == 2)); then ok "C1 $opt non-int exits 2"; else no "C1 $opt non-int exits 2"; fi
done
s="$TMPD/PWNED"; rm -f "$s"; run up -l "HOME[\$(touch $s)]" "$F"
if [[ ! -e $s ]] && ((RC == 2)); then ok "C1 injection blocked via -l"; else no "C1 injection blocked via -l"; fi
run up -l abc "$F"
if ((RC == 2)); then ok "H1 -l abc exits 2 (not 1)"; else no "H1 -l abc exits 2 (not 1)"; fi
if [[ $ERR != *"unbound variable"* ]]; then ok "H1 -l abc: no raw bash error"; else no "H1 -l abc: no raw bash error"; fi
run up -l '1+1' "$F"
if ((RC == 2)); then ok "C1 arithmetic '1+1' rejected"; else no "C1 arithmetic '1+1' rejected"; fi

# --- C2 / H3: newline-less last line preserved ------------------------------
mkn $'# Alpha\n## Beta'; run up -q "$F"
if [[ $OUT == *"### Beta"* ]]; then ok "C2 last line (no newline) survives up"; else no "C2 last line (no newline) survives up"; fi
if (( $(printf '%s' "$OUT" | grep -c '#') == 2 )); then ok "C2 both lines present"; else no "C2 both lines present"; fi
mkn $'## sub\n# toplevel'; run norm -s 1 -q "$F"
if [[ $OUT == *"# toplevel"* ]]; then ok "H3 normalize keeps newline-less min-level last line"; else no "H3 normalize keeps newline-less min-level last line"; fi
if [[ $OUT == *"## sub"* ]]; then ok "H3 normalize did not wrong-shift survivor"; else no "H3 normalize did not wrong-shift survivor"; fi

# --- H2 / M2 / M3: in-place preserves inode/symlink/perms -------------------
printf '# H\n' > "$TMPD/real.md"; ln -s real.md "$TMPD/link.md"
"$CHMD" up -i -q "$TMPD/link.md"
if [[ -L "$TMPD/link.md" ]]; then ok "H2 in-place keeps symlink a symlink"; else no "H2 in-place keeps symlink a symlink"; fi
if grep -q '## H' "$TMPD/real.md"; then ok "H2 in-place writes through to target"; else no "H2 in-place writes through to target"; fi
printf '# H\n' > "$TMPD/perm.md"; chmod 0644 "$TMPD/perm.md"
"$CHMD" up -i -q "$TMPD/perm.md"
if [[ $(stat -c %a "$TMPD/perm.md") == 644 ]]; then ok "M3 in-place preserves mode 0644"; else no "M3 in-place preserves mode 0644"; fi
printf '# H\n' > "$TMPD/a.md"; ln "$TMPD/a.md" "$TMPD/b.md"
"$CHMD" up -i -q "$TMPD/a.md"
if grep -q '## H' "$TMPD/b.md"; then ok "M2 in-place keeps hardlink in sync"; else no "M2 in-place keeps hardlink in sync"; fi

# --- H4 / L12: closing-fence run-length ------------------------------------
mk '````' 'inner' '```' '# STILL inside' '````'; run up -q "$F"
if [[ $OUT == *"# STILL inside"* && $OUT != *"## STILL inside"* ]]; then ok "H4 short fence does not close long fence"; else no "H4 short fence does not close long fence"; fi
mk '     ```' '# not really code' '     ```'; run up -q "$F"
if [[ $OUT == *"## not really code"* ]]; then ok "L12 4+-space-indented fence is not a fence"; else no "L12 4+-space-indented fence is not a fence"; fi

# --- H5: 7+ hashes are a paragraph, not a header ---------------------------
mk '####### seven hashes'
run down -q "$F"
if [[ $OUT == *"####### seven hashes"* ]]; then ok "H5 7-hash line not corrupted by down"; else no "H5 7-hash line not corrupted by down"; fi
run up -q "$F"
if [[ $OUT == *"####### seven hashes"* ]]; then ok "H5 7-hash line not corrupted by up"; else no "H5 7-hash line not corrupted by up"; fi

# --- H6: output not discarded when all headers at boundary -----------------
mk '# Top' 'body text'; run down -q "$F"
if [[ $OUT == *"# Top"* && $OUT == *"body text"* ]]; then ok "H6 all-skipped still emits content"; else no "H6 all-skipped still emits content"; fi
if ((RC == 0)); then ok "H6 no-op pass-through exits 0"; else no "H6 no-op pass-through exits 0"; fi

# --- H7 / M4: temp file not leaked on stdout run ---------------------------
mkdir -p "$TMPD/tdir"; mk '# H'
TMPDIR="$TMPD/tdir" "$CHMD" up -q "$F" >/dev/null 2>&1
if (( $(find "$TMPD/tdir" -type f | wc -l) == 0 )); then ok "H7 stdout run leaves no temp file"; else no "H7 stdout run leaves no temp file"; fi

# --- H8 / L18: backup not silently overwritten -----------------------------
printf '# H\n' > "$TMPD/bk.md"; printf 'PRECIOUS\n' > "$TMPD/bk.md.bak"
run up -i -b -q "$TMPD/bk.md"
if ((RC != 0)) && [[ $(<"$TMPD/bk.md.bak") == PRECIOUS ]]; then ok "H8 refuses to overwrite existing backup"; else no "H8 refuses to overwrite existing backup"; fi

# --- H9 / H10: option-parsing crashes become clean exit 2 ------------------
run up -qlo "$TMPD/out.md" "$F"
if ((RC == 2)); then ok "H9 bundled value-option fails cleanly (rc2)"; else no "H9 bundled value-option fails cleanly (rc2)"; fi
run up -l -q "$F"
if ((RC == 2)); then ok "H10 -l followed by option fails cleanly (rc2)"; else no "H10 -l followed by option fails cleanly (rc2)"; fi
printf '# H\n' > "$TMPD/iq.md"; run up -iq "$TMPD/iq.md"
if ((RC == 0)) && grep -q '## H' "$TMPD/iq.md"; then ok "H9 valid bundle -iq still works"; else no "H9 valid bundle -iq still works"; fi

# --- M1: -o directory rejected ---------------------------------------------
mk '# H'; run up -q -o "$TMPD" "$F"
if ((RC == 2)); then ok "M1 -o <dir> rejected (rc2)"; else no "M1 -o <dir> rejected (rc2)"; fi

# --- M5: no-args usage to stderr, rc2 --------------------------------------
run
if [[ -z $OUT && -n $ERR ]] && ((RC == 2)); then ok "M5 no-args usage goes to stderr, rc2"; else no "M5 no-args usage goes to stderr, rc2"; fi

# --- M7 / M8: normalize option validation ----------------------------------
mk '# A' '## B'
run norm -l 0 -s 2 -q "$F"
if ((RC == 0)); then ok "M7 norm ignores -l 0 (not rejected)"; else no "M7 norm ignores -l 0 (not rejected)"; fi
run norm -s 9 "$F"
if ((RC == 2)); then ok "M8 norm -s 9 out-of-range exits 2"; else no "M8 norm -s 9 out-of-range exits 2"; fi
run norm -s 0 "$F"
if ((RC == 2)); then ok "M8 norm -s 0 out-of-range exits 2"; else no "M8 norm -s 0 out-of-range exits 2"; fi

# --- M11 / L15: verbosity wired to VERBOSE ---------------------------------
mk '# H'
run up "$F"
if [[ -n $ERR ]]; then ok "M11 verbose default emits info on stderr"; else no "M11 verbose default emits info on stderr"; fi
run up -q "$F"
if [[ -z $ERR ]]; then ok "M11 -q suppresses stderr"; else no "M11 -q suppresses stderr"; fi
run up -q -v "$F"
if [[ -n $ERR ]]; then ok "M11 -v overrides preceding -q"; else no "M11 -v overrides preceding -q"; fi

# --- M12: stop-on-error + quiet still reports the abort --------------------
mk '# Top'; run down --stop-on-error -q "$F"
if ((RC == 1)) && [[ -n $ERR ]]; then ok "M12 stop-on-error emits diagnostic even with -q"; else no "M12 stop-on-error emits diagnostic even with -q"; fi

# --- L1: -b without -i warns -----------------------------------------------
mk '# H'; run up -b "$F"
if [[ $ERR == *[Ii]gnoring* || $ERR == *backup* ]]; then ok "L1 -b without -i warns"; else no "L1 -b without -i warns"; fi

# --- L3: -- end-of-options sentinel ----------------------------------------
printf '# H\n' > "$TMPD/-dash.md"; run up -q -- "$TMPD/-dash.md"
if ((RC == 0)) && [[ $OUT == *"## H"* ]]; then ok "L3 -- sentinel allows dash-named file"; else no "L3 -- sentinel allows dash-named file"; fi

# --- code-block preservation sanity (headline guarantee) -------------------
mk '# Real' '```bash' '# comment in code' '```' '## Real2'; run up -q "$F"
if [[ $OUT == *$'```bash\n# comment in code'* ]]; then ok "code-block header-like line untouched"; else no "code-block header-like line untouched"; fi
if [[ $OUT == *"## Real"* && $OUT == *"### Real2"* ]]; then ok "real headers still shifted"; else no "real headers still shifted"; fi

# --- BCS1002: locked PATH — runs even with a hostile/empty caller PATH -----
mk '# H'
locked_out=$(PATH=/nonexistent "$CHMD" up -q "$F" 2>/dev/null); locked_rc=$?
if ((locked_rc == 0)) && [[ $locked_out == *"## H"* ]]; then ok "BCS1002 runs with stripped caller PATH"; else no "BCS1002 runs with stripped caller PATH"; fi

# --- golden exactness (H15-style) ------------------------------------------
mk '# A' '## B'; run up -q "$F"
if [[ $OUT == $'## A\n### B' ]]; then ok "golden: up by 1 is exact"; else no "golden: up by 1 is exact"; fi

printf '\n================================\n'
printf '%bPassed: %d%b\n' "$GREEN" "$passed" "$NC"
if ((failed > 0)); then
  printf '%bFailed: %d%b\n' "$RED" "$failed" "$NC"
  exit 1
fi
printf '%bAll audit regression tests passed!%b\n' "$GREEN" "$NC"
exit 0

#fin
