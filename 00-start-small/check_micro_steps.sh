#!/usr/bin/env bash
# check_micro_steps.sh — outcome checker for exercises/01-micro-steps.md
# Looks at node state and my-work/00-start-small/answers.env. Prints PASS/FAIL with a reason.
# It never prints the expected answer.
#   BTC_CLI  : how to reach your node (default: "bitcoin-cli -regtest")
#   MY_WORK  : your work folder (default: my-work/00-start-small)
#   ANSWERS  : path to answers file (default: $MY_WORK/answers.env)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, os, re, shlex, subprocess, sys

LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ANS_PATH = os.environ.get("ANSWERS", os.path.join(WORK, "answers.env"))
results = []

def cli(*args, wallet=None):
    cmd = CLI + ([f"-rpcwallet={wallet}"] if wallet else []) + [str(a) for a in args]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip() or p.stdout.strip())
    out = p.stdout.strip()
    try:
        return json.loads(out)
    except ValueError:
        return out

def answers():
    a = {}
    if os.path.exists(ANS_PATH):
        for line in open(ANS_PATH):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                a[k.strip()] = v.strip().strip('"').strip("'")
    return a

def check(name, ok, why=""):
    results.append(ok)
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))

A = answers()
check("answers file exists", os.path.exists(ANS_PATH), f"create {ANS_PATH} from exercises/answers.env.template")

try:
    info = cli("getblockchaininfo")
except Exception as e:
    check("node answers RPC", False, f"cannot reach node ({e}); start it, or export BTC_CLI")
    sys.exit(1)
check("node answers RPC", True)
check("node is on regtest", info.get("chain") == "regtest", "these exercises only run on regtest")
check("chain height is at least 101", info["blocks"] >= 101, "a coinbase needs 100 more blocks on top before it can be spent")

loaded = cli("listwallets")
for w in ("kisumu_miner", "kisumu_merchant"):
    check(f"wallet {w} is loaded", w in loaded, "create it (or load it if it already exists)")

g = A.get("GENESIS_HASH", "").lower()
check("GENESIS_HASH is the regtest genesis block", g != "" and g == cli("getblockhash", 0),
      "ask the node for the hash at height 0")

check("SPENDABLE_UTXO_COUNT explains coinbase maturity", A.get("SPENDABLE_UTXO_COUNT") == "1",
      "after exactly 101 blocks, how many coinbase outputs are 100 or more blocks deep?")

txid = A.get("MY_FIRST_TXID", "").lower()
ok_tx = False
why = "MY_FIRST_TXID must be the 0.5 BTC send from kisumu_miner to kisumu_merchant"
if re.fullmatch(r"[0-9a-f]{64}", txid) and "kisumu_merchant" in loaded:
    try:
        t = cli("gettransaction", txid, wallet="kisumu_merchant")
        recv = sum(d["amount"] for d in t.get("details", []) if d["category"] == "receive")
        if abs(recv - 0.5) > 1e-9:
            why = "that tx does not pay 0.5 BTC to kisumu_merchant"
        elif t.get("confirmations", 0) < 1:
            why = "the tx is still in the mempool: mine a block"
        else:
            ok_tx = True
    except Exception:
        why = "kisumu_merchant does not know this txid"
check("MY_FIRST_TXID is a confirmed 0.5 BTC payment to kisumu_merchant", ok_tx, why)

if "kisumu_merchant" in loaded:
    bal = cli("getbalances", wallet="kisumu_merchant")["mine"]
    check("kisumu_merchant has a confirmed balance", bal["trusted"] > 0, "mine a block after sending")

j = os.path.join(WORK, "journal.md")
n = 0
if os.path.exists(j):
    n = sum(1 for line in open(j) if "bitcoin-cli" in line or re.search(r"\b(getblock|generatetoaddress|sendtoaddress|listunspent|createwallet)", line))
check("journal.md records the commands you typed (>= 8 lines)", n >= 8,
      f"found {n} command lines in {j}")

print(f"\n{sum(results)}/{len(results)} checks passed.")
sys.exit(0 if all(results) else 1)
PY
