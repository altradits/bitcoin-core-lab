#!/usr/bin/env bash
# check_mission6.sh — checks the regression test YOU wrote for Mission 6.
# A good test PASSES on the correct code and FAILS on every boundary mutant.
#   TEST_FILE (default: ./mission6_test.go in this stage)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$PATH:/usr/local/go/bin"
TEST_FILE="${TEST_FILE:-$HERE/mission6_test.go}"
pass=0; total=0
ok()  { total=$((total+1)); pass=$((pass+1)); echo "PASS: $1"; }
bad() { total=$((total+1)); echo "FAIL: $1${2:+ -- $2}"; }
[ -f "$TEST_FILE" ] || { echo "FAIL: write $TEST_FILE (package dojo, func TestMission6_...)"; exit 1; }
grep -q "CheckCoinbaseScriptSigLength" "$TEST_FILE" && ok "test calls CheckCoinbaseScriptSigLength" || bad "test calls CheckCoinbaseScriptSigLength"
grep -q "func TestMission6" "$TEST_FILE" && ok "test is named TestMission6_*" || bad "test is named TestMission6_*" "so './lab.sh dojo check 6' can select it"

run_with() {  # $1 = label, $2 = sed expression applied to the reference function (empty = unchanged)
  local tmp; tmp="$(mktemp -d)"
  cp "$HERE/go.mod" "$tmp/"
  cp "$HERE/solutions/dojo_missions_solved.go" "$tmp/dojo_missions.go"
  [ -n "$2" ] && sed -i '' "$2" "$tmp/dojo_missions.go"
  cp "$TEST_FILE" "$tmp/mission6_test.go"
  (cd "$tmp" && go test -run 'TestMission6' . >/dev/null 2>&1); local rc=$?
  rm -rf "$tmp"; return $rc
}
run_with correct "" && ok "passes on the correct code" || bad "passes on the correct code" "your test rejects valid lengths or does not compile"
for m in 's/scriptSigLen > 100/scriptSigLen >= 100/' 's/scriptSigLen > 100/scriptSigLen > 101/' \
         's/scriptSigLen < 2 /scriptSigLen < 1 /' 's/scriptSigLen < 2 /scriptSigLen <= 2 /'; do
  run_with mutant "$m" && bad "catches a boundary mutant" "some off-by-one at an edge still passes; test every edge on both sides" \
                       || ok "catches a boundary mutant"
done
echo; echo "$pass/$total checks passed."; [ "$pass" -eq "$total" ]
