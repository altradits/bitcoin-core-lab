#!/usr/bin/env bash
# check_first_app.sh — outcome checker for Micro-Step 4.
# Builds and runs YOUR program (my-work/00-start-small/first_app.go, or the path given as $1)
# against your regtest node and checks what it printed. It never shows a solution.
# Running it sends 0.21 regtest BTC and mines 1 block: that is expected.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$HERE")"
SRC="${1:-$LAB_DIR/my-work/00-start-small/first_app.go}"
fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 -- $2"; fails=$((fails+1)); }

if [ ! -f "$SRC" ]; then
  fail "program exists" "copy exercises/first_app.go to my-work/00-start-small/first_app.go first"
  exit 1
fi
pass "program exists"

if grep -q "TODO(you)" "$SRC"; then
  fail "no TODO(you) markers left" "$(grep -c 'TODO(you)' "$SRC") marker(s) still in the file"
else
  pass "no TODO(you) markers left"
fi

if ! command -v go >/dev/null 2>&1; then
  fail "go toolchain installed" "install Go to run this step"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cp "$SRC" "$TMP/main.go"
if (cd "$TMP" && go mod init firstapp >/dev/null 2>&1 && go vet ./... >"$TMP/vet.txt" 2>&1); then
  pass "go vet is clean"
else
  fail "go vet is clean" "$(head -3 "$TMP/vet.txt")"
fi

if (cd "$TMP" && go run . >"$TMP/out.txt" 2>&1); then
  pass "program exits with status 0"
else
  fail "program exits with status 0" "last lines: $(tail -2 "$TMP/out.txt" | tr '\n' ' ')"
fi

OUT="$(cat "$TMP/out.txt")"
if echo "$OUT" | grep -q "Error:"; then fail "no RPC errors in output" "an askBitcoin call returned Error:"; else pass "no RPC errors in output"; fi
if echo "$OUT" | grep -Eq "bcrt1[02-9ac-hj-np-z]{20,}"; then pass "prints a new regtest address"; else fail "prints a new regtest address" "no bcrt1... address found in output"; fi
if echo "$OUT" | grep -Eq "\b[0-9a-f]{64}\b"; then pass "prints a txid"; else fail "prints a txid" "no 64-hex-character txid found in output"; fi
if [ "$(echo "$OUT" | grep -Eo '\b[0-9]{3,7}\b' | sort -un | wc -l | tr -d ' ')" -ge 2 ]; then
  pass "prints heights before and after mining"
else
  fail "prints heights before and after mining" "expected two different block heights in the output"
fi

echo
[ "$fails" -eq 0 ] && echo "All checks passed." || echo "$fails check(s) failed."
[ "$fails" -eq 0 ]
