#!/usr/bin/env bash
# check_htlc_spends.sh — outcome checker for exercises/02-spend-both-branches.md
#   BTC_CLI (default "bitcoin-cli -regtest", node needs txindex=1), MY_WORK, ANSWERS
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, os, re, shlex, subprocess, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ANS_PATH = os.environ.get("ANSWERS", os.path.join(WORK, "answers.env"))
res = []
def check(n, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + n + ("" if ok or not why else f" -- {why}"))
def done():
    print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if res and all(res) else 1)
def cli(*a):
    p = subprocess.run(CLI + [str(x) for x in a], capture_output=True, text=True)
    if p.returncode: raise RuntimeError(p.stderr.strip())
    try: return json.loads(p.stdout)
    except ValueError: return p.stdout.strip()
A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1); A[k.strip()] = v.strip().strip('"').strip("'")
check("answers file exists", os.path.exists(ANS_PATH))
check("your script exists", os.path.exists(os.path.join(WORK, "htlc_spend.py")), "save your program as htlc_spend.py in your my-work folder")
if os.path.exists(os.path.join(WORK, "htlc_spend.py")):
    src = open(os.path.join(WORK, "htlc_spend.py")).read()
    check("no TODO / NotImplementedError left", "TODO" not in src and "NotImplementedError" not in src)
try: cli("getblockcount")
except Exception as e: check("node reachable", False, str(e)); done()
def tx(k):
    t = A.get(k, "").lower()
    if not re.fullmatch(r"[0-9a-f]{64}", t): return None
    try: return cli("getrawtransaction", t, "1")
    except Exception: return None
script = A.get("HTLC_SCRIPT_HEX", "").lower()
F, C, Rf = tx("FUND_TXID"), tx("CLAIM_TXID"), tx("REFUND_TXID")
check("FUND found (txindex=1?)", F); check("CLAIM found", C); check("REFUND found", Rf)
if not (F and C and Rf and script): done()
spk = cli("decodescript", script).get("segwit", {}).get("hex")
check("fund vout 0 and 1 are 1 BTC to YOUR P2WSH", len(F["vout"]) >= 2 and all(F["vout"][i]["scriptPubKey"]["hex"] == spk and round(F["vout"][i]["value"] * 1e8) == 100_000_000 for i in (0, 1)))
ci, ri = C["vin"][0], Rf["vin"][0]
check("CLAIM spends fund:0", ci["txid"] == F["txid"] and ci["vout"] == 0)
w = ci.get("txinwitness", [])
pre = A.get("PREIMAGE_HEX", "").lower()
check("claim witness = <sig> <preimage> 01 <script>", len(w) == 4 and w[1] == pre and w[2] == "01" and w[3] == script)
check("REFUND spends fund:1", ri["txid"] == F["txid"] and ri["vout"] == 1)
w = ri.get("txinwitness", [])
check("refund witness = <sig> <empty> <script>", len(w) == 3 and w[1] == "" and w[2] == script)
try: d = int(A.get("CSV_DELAY", ""))
except ValueError: d = -1
check("refund nSequence = CSV_DELAY and version >= 2", ri["sequence"] == d and Rf["version"] >= 2)
if Rf.get("blockhash") and F.get("blockhash"):
    hf = cli("getblockheader", F["blockhash"])["height"]; hr = cli("getblockheader", Rf["blockhash"])["height"]
    check("refund confirmed no earlier than BIP68 allows", hr - hf >= d)
else:
    check("fund and refund are mined", False, "mine a block after the refund")
check("WRONG_PREIMAGE_REASON", A.get("WRONG_PREIMAGE_REASON", "").startswith("mandatory-script-verify-flag-failed"), "copy the part before ' ('")
check("EARLY_REFUND_REASON", A.get("EARLY_REFUND_REASON", "") == "non-BIP68-final")
try: b = int(A.get("BLOCKS_TO_MINE", ""))
except ValueError: b = -99
check("BLOCKS_TO_MINE = delay - 1 after the 1 confirmation block", b == d - 1, "count: fund mined at h; refund valid in a block at height >= h + delay")
done()
PY
