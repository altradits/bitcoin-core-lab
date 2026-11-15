#!/usr/bin/env bash
# check_15.sh — Stage 15 outcome checker.
#   ./check_15.sh reorg   checks your reorg drill on the node (BTC_CLI, reads answers.env)
#   ./check_15.sh test    runs YOUR feature_kisumu_reorg_mempool.py
#   ./check_15.sh         both
# Env: BTC_CLI (default "bitcoin-cli -regtest"), BITCOIN_ROOT, MY_WORK, TEST_FILE
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
BITCOIN_ROOT="${BITCOIN_ROOT:-/Users/mac/bitcoin}"
WORK="${MY_WORK:-$LAB_DIR/my-work/$STAGE}"; export WORK

check_reorg() {
python3 - <<'PY'
import json, os, shlex, subprocess, sys
CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))
ANS = os.environ.get("ANSWERS", os.path.join(os.environ["WORK"], "answers.env"))
res = []
def check(n, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + n + ("" if ok or not why else f" -- {why}"))
def cli(*a):
    p = subprocess.run(CLI + [str(x) for x in a], capture_output=True, text=True)
    if p.returncode: raise RuntimeError(p.stderr.strip())
    try: return json.loads(p.stdout)
    except ValueError: return p.stdout.strip()
A = {}
if os.path.exists(ANS):
    for l in open(ANS):
        if "=" in l and not l.startswith("#"):
            k, v = l.strip().split("=", 1); A[k] = v.strip('"')
check("answers.env exists", A, f"write {ANS}")
try: cli("getblockcount")
except Exception as e: check("node reachable", False, str(e)); print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(1)
def hdr(h):
    try: return cli("getblockheader", h)
    except Exception: return None
orph, old, new = hdr(A.get("ORPHANED_BLOCK", "")), hdr(A.get("OLD_TIP", "")), hdr(A.get("NEW_TIP", ""))
check("ORPHANED_BLOCK known", orph); check("OLD_TIP known", old); check("NEW_TIP known", new)
if orph and old and new:
    check("FORK_HEIGHT matches ORPHANED_BLOCK", str(orph["height"]) == A.get("FORK_HEIGHT"))
    check("OLD_TIP is 2 blocks above the orphaned block", old["height"] == orph["height"] + 2)
    check("NEW_TIP is 4 blocks above the fork parent", new["height"] == orph["height"] - 1 + 4)
    check("old branch is not in the active chain", orph["confirmations"] == -1)
    check("NEW_TIP is in the active chain", new["confirmations"] >= 1)
    tips = {t["hash"]: t["status"] for t in cli("getchaintips")}
    check("OLD_BRANCH_STATUS recorded correctly", A.get("OLD_BRANCH_STATUS") == "invalid", "what did getchaintips say right after invalidateblock?")
    check("OLD_BRANCH_STATUS_AFTER matches the node", A.get("OLD_BRANCH_STATUS_AFTER") == tips.get(old["hash"]), "run getchaintips again")
    check("TIP_AFTER_RECONSIDER is the more-work tip", A.get("TIP_AFTER_RECONSIDER") == cli("getbestblockhash") or A.get("TIP_AFTER_RECONSIDER") == new["hash"])
txid = A.get("REORG_TXID", "")
try:
    tx = cli("getrawtransaction", txid, "1")
    in_mp = True
    try: cli("getmempoolentry", txid)
    except Exception: in_mp = False
    blk = tx.get("blockhash")
    active = blk and cli("getblockheader", blk)["confirmations"] >= 1
    check("REORG_TXID survived the reorg (mempool or re-mined on the new chain)", in_mp or active)
    check("REORG_TXID is NOT only in the orphaned block", not (blk == A.get("ORPHANED_BLOCK") and not in_mp))
except Exception as e:
    check("REORG_TXID found (txindex=1?)", False, str(e))
print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if all(res) else 1)
PY
}

check_test() {
  local f="${TEST_FILE:-$WORK/feature_kisumu_reorg_mempool.py}" pass=0 total=0
  ok() { total=$((total+1)); pass=$((pass+1)); echo "PASS: $1"; }; bad() { total=$((total+1)); echo "FAIL: $1${2:+ -- $2}"; }
  [ -f "$f" ] || { echo "FAIL: copy exercises/03_feature_kisumu_reorg_mempool.py to $f"; return 1; }
  grep -qE "TODO|NotImplementedError" "$f" && bad "no TODO left" || ok "no TODO left"
  for api in disconnect_nodes connect_nodes sync_blocks getrawmempool; do grep -q "$api" "$f" && ok "uses $api" || bad "uses $api"; done
  local tmp; tmp="$(mktemp -d)"
  echo "… running your test (~30 s)"
  if python3 "$f" --configfile="$BITCOIN_ROOT/build/test/config.ini" --tmpdir="$tmp/run" >"$tmp/log" 2>&1; then ok "your test passes"; else bad "your test passes"; tail -20 "$tmp/log"; fi
  rm -rf "$tmp"; echo; echo "$pass/$total checks passed."; [ "$pass" -eq "$total" ]
}

case "${1:-all}" in
  reorg) check_reorg ;;
  test) check_test ;;
  all) rc=0; check_reorg || rc=1; check_test || rc=1; exit $rc ;;
  *) echo "usage: $0 reorg|test|all"; exit 2 ;;
esac
