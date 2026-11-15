#!/usr/bin/env bash
# check_node_procedure.sh — outcome checker for exercises/02-start-stop-procedure.md
# Tests YOUR my-work/01-node-foundations/node.sh. Without flags it only runs "status" and "log".
# With --cycle it also runs "stop", "status" (must fail), "start", "start" again (must be a no-op)
# and "status" — i.e. it restarts your node through your own script.
#   MY_WORK : your work folder (default my-work/01-node-foundations)
#   NODE_SH : path to the script (default $MY_WORK/node.sh)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$HERE")"
MY_WORK="${MY_WORK:-$LAB_DIR/my-work/$(basename "$HERE")}"
NODE_SH="${NODE_SH:-$MY_WORK/node.sh}"
CYCLE=0; [ "${1:-}" = "--cycle" ] && CYCLE=1
fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1 -- $2"; fails=$((fails+1)); }
run() { timeout_s=$1; shift; perl -e 'alarm shift; exec @ARGV' "$timeout_s" "$@"; }

[ -f "$NODE_SH" ] || { fail "node.sh exists" "write $NODE_SH yourself"; exit 1; }
pass "node.sh exists"
[ -x "$NODE_SH" ] && pass "node.sh is executable" || fail "node.sh is executable" "set the execute bit"
bash -n "$NODE_SH" 2>/dev/null && pass "bash syntax is valid" || fail "bash syntax is valid" "bash -n reports an error"
grep -Eq '^[[:space:]]*set -[a-z]*e[a-z]*u[a-z]* *-?o? *pipefail|set -euo pipefail' "$NODE_SH" \
  && pass "uses strict mode" || fail "uses strict mode" "the worksheet asks for set -euo pipefail"
grep -Eq 'DATADIR=\$\{DATADIR:-' "$NODE_SH" && pass "datadir is overridable" \
  || fail "datadir is overridable" "define DATADIR=\${DATADIR:-...} at the top"
grep -Eq 'kill +-9|kill +-KILL|pkill +-9' "$NODE_SH" && fail "never uses kill -9" "stop the node through RPC" \
  || pass "never uses kill -9"

if out=$(run 60 "$NODE_SH" status 2>&1); then
  pass "status exits 0 while the node runs"
  echo "$out" | grep -qi "regtest" && pass "status prints the chain" || fail "status prints the chain" "no 'regtest' in output"
  echo "$out" | grep -Eq '[0-9]+' && pass "status prints a number (height)" || fail "status prints a number (height)" "no height in output"
else
  fail "status exits 0 while the node runs" "is the node running? output: $(echo "$out" | tail -1)"
fi
if out=$(run 30 "$NODE_SH" log 2>&1) && [ "$(echo "$out" | wc -l)" -ge 5 ]; then
  pass "log shows the debug.log tail"
else
  fail "log shows the debug.log tail" "expected ~20 lines from the regtest debug.log"
fi

if [ "$CYCLE" -eq 1 ]; then
  run 120 "$NODE_SH" stop >/dev/null 2>&1 && pass "stop exits 0" || fail "stop exits 0" "stop failed"
  if run 30 "$NODE_SH" status >/dev/null 2>&1; then fail "status fails after stop" "status still exits 0"; else pass "status fails after stop"; fi
  run 120 "$NODE_SH" start >/dev/null 2>&1 && pass "start exits 0" || fail "start exits 0" "start failed"
  run 60 "$NODE_SH" status >/dev/null 2>&1 && pass "status succeeds after start (RPC ready)" \
    || fail "status succeeds after start (RPC ready)" "start returned before RPC was ready"
  run 60 "$NODE_SH" start >/dev/null 2>&1 && pass "second start is a no-op" || fail "second start is a no-op" "start fails when already running"
  n=$(pgrep -x bitcoind | wc -l | tr -d ' ')
  [ "$n" -le 1 ] && pass "only one bitcoind process" || fail "only one bitcoind process" "$n bitcoind processes are running"
else
  echo "(info) run with --cycle to test stop/start through your script"
fi

echo
[ "$fails" -eq 0 ] && echo "All checks passed." || echo "$fails check(s) failed."
[ "$fails" -eq 0 ]
