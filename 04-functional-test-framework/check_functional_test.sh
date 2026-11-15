#!/usr/bin/env bash
# check_functional_test.sh — checker for exercises/02-write-your-test.md and 03-mutation.md
#   ./check_functional_test.sh             run YOUR test; PASS if it passes
#   ./check_functional_test.sh --mutation  run it against a node with -incrementalrelayfee=0;
#                                          PASS if your test FAILS (it caught the "bug")
# Env: BITCOIN_ROOT (default /Users/mac/bitcoin), MY_WORK, TEST_FILE (override the file path)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$HERE")"; STAGE="$(basename "$HERE")"
BITCOIN_ROOT="${BITCOIN_ROOT:-/Users/mac/bitcoin}"
WORK="${MY_WORK:-$LAB_DIR/my-work/$STAGE}"
TEST_FILE="${TEST_FILE:-$WORK/kisumu_pos_rbf_test.py}"
CONFIG="$BITCOIN_ROOT/build/test/config.ini"
MODE="${1:-normal}"
pass=0; total=0
ok()   { total=$((total+1)); pass=$((pass+1)); echo "PASS: $1"; }
bad()  { total=$((total+1)); echo "FAIL: $1${2:+ -- $2}"; }
finish() { echo; echo "$pass/$total checks passed."; [ "$pass" -eq "$total" ]; exit $?; }

[ -f "$TEST_FILE" ] && ok "test file exists" || { bad "test file exists" "copy exercises/kisumu_pos_rbf_test.py to $TEST_FILE"; finish; }
[ -f "$CONFIG" ] && ok "build/test/config.ini exists" || { bad "build/test/config.ini exists" "build Core with tests (Stage 13) or set BITCOIN_ROOT"; finish; }
python3 -m py_compile "$TEST_FILE" 2>/dev/null && ok "file compiles" || bad "file compiles" "python3 -m py_compile $TEST_FILE"
grep -q "TODO" "$TEST_FILE" && bad "no TODO left" "finish every TODO and delete the TODO markers" || ok "no TODO left"
grep -q "NotImplementedError" "$TEST_FILE" && bad "no NotImplementedError left" || ok "no NotImplementedError left"
for api in MiniWallet sync_mempools assert_raises_rpc_error assert_equal "self.generate"; do
  grep -q "$api" "$TEST_FILE" && ok "uses $api" || bad "uses $api" "the spec needs it; read test_framework/"
done
grep -qE "time\.sleep|^\s*sleep\(" "$TEST_FILE" && bad "no sleep() calls" "use sync_* or wait_until; sleeps make tests flaky" || ok "no sleep() calls"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if [ "$MODE" = "--mutation" ]; then
  cat > "$TMP/bitcoind" <<EOF
#!/usr/bin/env bash
exec "$BITCOIN_ROOT/build/bin/bitcoind" "\$@" -incrementalrelayfee=0
EOF
  chmod +x "$TMP/bitcoind"
  echo "… running your test against a MUTATED node (-incrementalrelayfee=0); this takes ~1 minute"
  if BITCOIND="$TMP/bitcoind" python3 "$TEST_FILE" --configfile="$CONFIG" --tmpdir="$TMP/run" >"$TMP/log" 2>&1; then
    bad "your test FAILS under mutation" "it still passed, so it does not really assert rule 4; see worksheet 3"
  else
    if grep -q "not enough additional fees\|No exception raised\|JSONRPC error\|AssertionError" "$TMP/log"; then
      ok "your test FAILS under mutation (it caught the bug)"
    else
      bad "your test fails for the RIGHT reason" "it failed, but not at the rule-4 assertion; read $TMP/log (kept below)"
      tail -20 "$TMP/log"
    fi
  fi
else
  echo "… running your test (~1 minute)"
  if python3 "$TEST_FILE" --configfile="$CONFIG" --tmpdir="$TMP/run" >"$TMP/log" 2>&1; then
    ok "your test passes"
  else
    bad "your test passes" "last lines of the log follow"; tail -25 "$TMP/log"
  fi
fi
finish
