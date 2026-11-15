#!/usr/bin/env bash
# check_14.sh — Stage 14 outcome checker.
#   ./check_14.sh nodes   inspects your two running nodes (reads my-work/.../nodes.env)
#   ./check_14.sh test    runs YOUR p2p_kisumu_handshake_test.py
#   ./check_14.sh all
# Env: BITCOIN_ROOT (default ~/bitcoin), MY_WORK, TEST_FILE
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$HERE")"; STAGE="$(basename "$HERE")"
BITCOIN_ROOT="${BITCOIN_ROOT:-$HOME/bitcoin}"
WORK="${MY_WORK:-$LAB_DIR/my-work/$STAGE}"
pass=0; total=0
ok()  { total=$((total+1)); pass=$((pass+1)); echo "PASS: $1"; }
bad() { total=$((total+1)); echo "FAIL: $1${2:+ -- $2}"; }

check_nodes() {
  echo "== nodes"
  local env="$WORK/nodes.env"
  [ -f "$env" ] || { bad "nodes.env exists" "write $env with NODE_A_CLI and NODE_B_CLI"; return; }
  NODE_A_CLI="$(grep '^NODE_A_CLI=' "$env" | cut -d= -f2-)"; NODE_B_CLI="$(grep '^NODE_B_CLI=' "$env" | cut -d= -f2-)"
  $NODE_A_CLI getblockcount >/dev/null 2>&1 && ok "node A answers RPC" || { bad "node A answers RPC" "is it running? is NODE_A_CLI right?"; return; }
  $NODE_B_CLI getblockcount >/dev/null 2>&1 && ok "node B answers RPC" || { bad "node B answers RPC"; return; }
  [ "$($NODE_A_CLI getblockchaininfo | python3 -c 'import sys,json;print(json.load(sys.stdin)["chain"])')" = regtest ] && ok "node A is regtest" || bad "node A is regtest"
  local types
  types="$($NODE_A_CLI getpeerinfo | python3 -c 'import sys,json; print(" ".join(sorted(p["connection_type"] for p in json.load(sys.stdin))))')"
  [[ " $types " == *" block-relay-only "* ]] && ok "A has a block-relay-only peer" || bad "A has a block-relay-only peer" "see Step 2 (addconnection)"
  [[ " $types " == *" outbound-full-relay "* ]] && ok "A has an outbound-full-relay peer" || bad "A has an outbound-full-relay peer" "see Step 3"
  local inb
  inb="$($NODE_B_CLI getpeerinfo | python3 -c 'import sys,json; print(sum(1 for p in json.load(sys.stdin) if p["inbound"]))')"
  [ "$inb" -ge 2 ] && ok "B sees both connections as inbound" || bad "B sees both connections as inbound" "B saw $inb inbound peers"
  $NODE_B_CLI logging | python3 -c 'import sys,json; sys.exit(0 if json.load(sys.stdin).get("net") else 1)' \
    && ok "B logs the net category" || bad "B logs the net category" "enable -debug=net in nodeB.conf"
  local brelay
  brelay="$($NODE_A_CLI getpeerinfo | python3 -c 'import sys,json; print([p["relaytxes"] for p in json.load(sys.stdin) if p["connection_type"]=="block-relay-only"][:1])')"
  [ "$brelay" = "[False]" ] && ok "block-relay-only peer does not relay txs" || bad "block-relay-only peer does not relay txs" "got $brelay"
  for f in nodeA.conf nodeB.conf journal.md; do [ -s "$WORK/$f" ] && ok "$f written" || bad "$f written"; done
}

run_test_file() {  # returns the test's exit code; keeps the log tail in LAST_LOG
  local tmp; tmp="$(mktemp -d)"
  python3 "$TEST_FILE" --configfile="$BITCOIN_ROOT/build/test/config.ini" --tmpdir="$tmp/run" >"$tmp/log" 2>&1
  local rc=$?; LAST_LOG="$(tail -20 "$tmp/log")"; rm -rf "$tmp"; return $rc
}

check_test() {
  echo "== test"
  TEST_FILE="${TEST_FILE:-$WORK/p2p_kisumu_handshake_test.py}"
  [ -f "$TEST_FILE" ] || { bad "test file exists" "copy exercises/03_p2p_kisumu_handshake_test.py to $TEST_FILE"; return; }
  grep -qE "TODO|NotImplementedError" "$TEST_FILE" && bad "no TODO left" || ok "no TODO left"
  for api in sync_with_ping msg_getheaders msg_wtxidrelay wait_for_disconnect; do
    grep -q "$api" "$TEST_FILE" && ok "uses $api" || bad "uses $api"
  done
  echo "… running your test (~30 s)"
  if run_test_file; then ok "your test passes"; else bad "your test passes"; echo "$LAST_LOG"; fi
}

case "${1:-all}" in
  nodes) check_nodes ;;
  test) check_test ;;
  all) check_nodes; check_test ;;
  *) echo "usage: $0 nodes|test|all"; exit 2 ;;
esac
echo; echo "$pass/$total checks passed."; [ "$pass" -eq "$total" ]
