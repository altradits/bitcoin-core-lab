#!/usr/bin/env bash
# check_18.sh — Stage 18 outcome checker.
#   ./check_18.sh pkgrbf   run YOUR mempool_pkgrbf_cluster.py (CONFIG= path to a build's test/config.ini)
#   ./check_18.sh coinsel  check your coin-selection predictions against the wallet (BTC_CLI)
#   ./check_18.sh unit     find and run your kisumu_bnb_exact_match unit test (WORKTREE=)
#   ./check_18.sh          all three
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$HERE")"; STAGE="$(basename "$HERE")"
WORK="${MY_WORK:-$LAB_DIR/my-work/$STAGE}"; export WORK
pass=0; total=0
ok()  { total=$((total+1)); pass=$((pass+1)); echo "PASS: $1"; }
bad() { total=$((total+1)); echo "FAIL: $1${2:+ -- $2}"; }

if [ "${1:-all}" = all ]; then rc=0; for m in pkgrbf coinsel unit; do echo "=== $m"; "$0" $m || rc=1; done; exit $rc; fi
case "${1}" in
pkgrbf)
  f="${TEST_FILE:-$WORK/mempool_pkgrbf_cluster.py}"; CONFIG="${CONFIG:-$HOME/bitcoin/build/test/config.ini}"
  [ -f "$f" ] && ok "test file exists" || { bad "test file exists" "copy exercises/mempool_pkgrbf_cluster_skeleton.py to $f"; }
  if [ -f "$f" ]; then
    grep -qE "TODO|NotImplementedError" "$f" && bad "no TODO left" || ok "no TODO left"
    grep -q "replaced-transactions" "$f" && ok "asserts replaced-transactions" || bad "asserts replaced-transactions"
    grep -q "getmempoolcluster" "$f" && ok "detects cluster mempool support" || bad "detects cluster mempool support"
    tmp="$(mktemp -d)"; echo "… running your test against $(dirname "$(dirname "$CONFIG")")"
    if python3 "$f" --configfile="$CONFIG" --tmpdir="$tmp/run" >"$tmp/log" 2>&1; then ok "your test passes"
      grep -q "SKIP Part B" "$tmp/log" && echo "NOTE: Part B was skipped (no cluster mempool in this build). Run again with CONFIG= a master build."
    else bad "your test passes"; tail -20 "$tmp/log"; fi
    rm -rf "$tmp"
  fi ;;
coinsel)
  python3 - <<'PY' || exit 1
import json, os, shlex, subprocess, sys
CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))
ENV = os.path.join(os.environ["WORK"], "coinsel.env")
res = []
def check(n, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + n + ("" if ok or not why else f" -- {why}"))
def cli(*a, w=None):
    p = subprocess.run(CLI + ([f"-rpcwallet={w}"] if w else []) + [str(x) for x in a], capture_output=True, text=True)
    if p.returncode: raise RuntimeError(p.stderr.strip())
    try: return json.loads(p.stdout)
    except ValueError: return p.stdout.strip()
A = {}
if os.path.exists(ENV):
    for l in open(ENV):
        if "=" in l and not l.startswith("#"):
            k, v = l.strip().split("=", 1); A[k] = v
check("coinsel.env exists", A, f"write {ENV}")
w = A.get("COINSEL_WALLET", "")
try: utxos = cli("listunspent", 1, w=w)
except Exception as e: check("wallet loaded", False, str(e)); print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(1)
vals = sorted(round(u["amount"] * 1e8) for u in utxos)
check("wallet holds exactly the five coins", vals == [10_000_000, 20_000_000, 30_000_000, 50_000_000, 100_000_000], f"found {len(vals)} coins")
dest = cli("getnewaddress", w="kisumu_miner")
check("A_MAX_AMOUNT_SATS", A.get("A_MAX_AMOUNT_SATS") == str(30_000_000 - 110 * 10), "1-in-1-out P2WPKH vsize x 10 sat/vB, taken from the 0.30 coin")
try: a_amt = f"{int(A.get('A_AMOUNT_SATS', '0')) / 1e8:.8f}"
except ValueError: a_amt = "0"
for tag, amt in (("A", a_amt), ("B", "0.45")):
    psbt = cli("walletcreatefundedpsbt", "[]", json.dumps([{dest: amt}]), 0, json.dumps({"fee_rate": 10}), w=w)
    d = cli("decodepsbt", psbt["psbt"])
    n_in = len(d["tx"]["vin"]); has_change = psbt["changepos"] != -1; fee = round(psbt["fee"] * 1e8)
    if tag == "A":
        check("A_AMOUNT_SATS is paid by one coin with no change (BnB exact match)", n_in == 1 and not has_change, "pick an amount closer to your maximum")
        check("A_INPUTS / A_HAS_CHANGE match the wallet", A.get("A_INPUTS") == str(n_in) and A.get("A_HAS_CHANGE", "").lower() == str(has_change).lower())
        check("A_FEE_SATS matches the wallet", A.get("A_FEE_SATS") == str(fee))
    else:
        check("B_HAS_CHANGE recorded (true/false)", A.get("B_HAS_CHANGE", "").lower() in ("true", "false"), "B can vary between runs; record what you saw")
print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if all(res) else 1)
PY
  exit $? ;;
unit)
  WT="${WORKTREE:-$HOME/bitcoin-fuzz}"
  f="$WT/src/wallet/test/coinselector_tests.cpp"
  [ -f "$f" ] && ok "worktree has coinselector_tests.cpp" || { bad "worktree has coinselector_tests.cpp" "set WORKTREE= to your master worktree"; }
  grep -q "BOOST_AUTO_TEST_CASE(kisumu_bnb_exact_match)" "$f" 2>/dev/null && ok "your test case exists" || bad "your test case exists" "name it kisumu_bnb_exact_match"
  grep -A60 "kisumu_bnb_exact_match" "$f" 2>/dev/null | grep -q "SelectCoinsBnB" && ok "it calls SelectCoinsBnB" || bad "it calls SelectCoinsBnB"
  [ "$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null)" != master ] && ok "you are on a topic branch" || bad "you are on a topic branch" "never work on master"
  tb="$WT/build/bin/test_bitcoin"
  if [ -x "$tb" ]; then
    "$tb" --run_test=coinselector_tests/kisumu_bnb_exact_match >/dev/null 2>&1 && ok "test_bitcoin runs your case and it passes" || bad "test_bitcoin runs your case and it passes" "rebuild test_bitcoin and run the filter yourself to see the error"
  else bad "test_bitcoin is built in the worktree" "cmake --build build --target test_bitcoin -j3"; fi ;;
*) echo "usage: $0 pkgrbf|coinsel|unit"; exit 2 ;;
esac
echo; echo "$pass/$total checks passed."; [ "$pass" -eq "$total" ]
