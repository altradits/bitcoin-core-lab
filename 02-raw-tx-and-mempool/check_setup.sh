#!/usr/bin/env bash
# check_setup.sh — outcome checker for exercises/01-your-own-setup.md
# Runs YOUR my-work/02-raw-tx-and-mempool/setup.sh twice (it must be idempotent), then inspects the node.
#   BTC_CLI, MY_WORK as in the other checkers.  SETUP_SH overrides the script path.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$HERE")"
MY_WORK="${MY_WORK:-$LAB_DIR/my-work/$(basename "$HERE")}"
SETUP_SH="${SETUP_SH:-$MY_WORK/setup.sh}"
read -r -a CLI <<< "${BTC_CLI:-bitcoin-cli -regtest}"
fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 -- $2"; fails=$((fails+1)); }

[ -f "$SETUP_SH" ] || { fail "setup.sh exists" "write $SETUP_SH yourself"; exit 1; }
pass "setup.sh exists"
bash -n "$SETUP_SH" 2>/dev/null && pass "bash syntax is valid" || fail "bash syntax is valid" "bash -n reports an error"
grep -q "set -euo pipefail" "$SETUP_SH" && pass "uses strict mode" || fail "uses strict mode" "add set -euo pipefail"

if bash "$SETUP_SH" >/dev/null 2>&1; then pass "first run exits 0"; else fail "first run exits 0" "run it yourself and read the error"; fi
h1=$("${CLI[@]}" getblockcount 2>/dev/null || echo x)
if bash "$SETUP_SH" >/dev/null 2>&1; then pass "second run exits 0 (idempotent)"; else fail "second run exits 0 (idempotent)" "it fails when wallets already exist/are loaded"; fi
h2=$("${CLI[@]}" getblockcount 2>/dev/null || echo y)
[ "$h1" = "$h2" ] && pass "second run mined nothing (coins were already enough)" \
  || fail "second run mined nothing (coins were already enough)" "height went from $h1 to $h2; only mine when mature coins are short"

wallets=$("${CLI[@]}" listwallets 2>/dev/null || echo "[]")
for w in kisumu_miner kisumu_merchant; do
  echo "$wallets" | grep -q "\"$w\"" && pass "wallet $w loaded" || fail "wallet $w loaded" "your script must create or load it"
done
n=$("${CLI[@]}" -rpcwallet=kisumu_miner listunspent 2>/dev/null | grep -c '"txid"' || true)
[ "${n:-0}" -ge 5 ] && pass "kisumu_miner has >= 5 spendable UTXOs" || fail "kisumu_miner has >= 5 spendable UTXOs" "found ${n:-0}"

echo
[ "$fails" -eq 0 ] && echo "All checks passed." || echo "$fails check(s) failed."
[ "$fails" -eq 0 ]
