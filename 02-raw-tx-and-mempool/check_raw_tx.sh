#!/usr/bin/env bash
# check_raw_tx.sh — outcome checker for exercises/03-build-sign-broadcast.md
# Finds YOUR RAW_TXID on the node and checks it against the spec and your predictions.
#   BTC_CLI, MY_WORK, ANSWERS as in the other checkers.
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

def check(name, ok, why=""):
    results.append(bool(ok))
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))

def cli(*args, wallet=None):
    cmd = CLI + ([f"-rpcwallet={wallet}"] if wallet else []) + [str(a) for a in args]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    try:
        return json.loads(p.stdout)
    except ValueError:
        return p.stdout.strip()

A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            A[k.strip()] = v.strip().strip('"').strip("'")
check("answers file exists", os.path.exists(ANS_PATH), f"copy exercises/answers.env.template to {ANS_PATH}")

txid = A.get("RAW_TXID", "").lower()
if not re.fullmatch(r"[0-9a-f]{64}", txid):
    check("RAW_TXID is a 64-hex txid", False, "fill RAW_TXID")
    print(f"\n{sum(results)}/{len(results)} checks passed."); sys.exit(1)

try:
    wtx = cli("gettransaction", txid, "true", "true", wallet="kisumu_miner")
except Exception as e:
    check("kisumu_miner knows RAW_TXID", False, f"{e}")
    print(f"\n{sum(results)}/{len(results)} checks passed."); sys.exit(1)
check("kisumu_miner knows RAW_TXID", True)
tx = wtx["decoded"]
fee = round(-wtx.get("fee", 0) * 100_000_000)

check("exactly one input", len(tx["vin"]) == 1, "the spec asks for one coinbase UTXO")
prev_is_cb = False
if len(tx["vin"]) == 1:
    try:
        prev = cli("gettransaction", tx["vin"][0]["txid"], wallet="kisumu_miner")
        prev_is_cb = prev.get("generated", False)
    except Exception:
        pass
check("the input is a kisumu_miner coinbase output", prev_is_cb, "spend a mature coinbase from listunspent")
check("exactly two outputs", len(tx["vout"]) == 2, "merchant payment + change")

to_merchant = change_ok = False
for o in tx["vout"]:
    addr = o["scriptPubKey"].get("address")
    if not addr:
        continue
    try:
        im = cli("getaddressinfo", addr, wallet="kisumu_merchant")
        if im.get("ismine") and round(o["value"] * 1e8) == 100_000_000:
            to_merchant = True
        mi = cli("getaddressinfo", addr, wallet="kisumu_miner")
        if mi.get("ismine") and mi.get("ischange"):
            change_ok = True
    except Exception:
        pass
check("pays exactly 1 BTC to a kisumu_merchant address", to_merchant, "check the amount and which wallet made the address")
check("change goes to a kisumu_miner CHANGE address", change_ok, "use the RPC that makes internal (change) addresses")
check("fee is exactly 10,000 sat", fee == 10_000, "redo the change subtraction digit by digit")

def num(k):
    try:
        return float(A.get(k, ""))
    except ValueError:
        return None
check("PREDICTED_WEIGHT equals the real weight", num("PREDICTED_WEIGHT") == tx["weight"],
      "count base and witness bytes again (is the signature 71 or 72 bytes?)")
check("PREDICTED_VSIZE equals the real vsize", num("PREDICTED_VSIZE") == tx["vsize"], "vsize = ceil(weight/4)")
fr = num("FEERATE_SAT_VB_RAW")
check("FEERATE_SAT_VB_RAW is fee/vsize (2 decimals)", fr is not None and abs(fr - fee / tx["vsize"]) < 0.006, "sat divided by vB")
check("RAW_WTXID matches", A.get("RAW_WTXID", "").lower() == tx["hash"], "wtxid is the 'hash' field; it commits to the witness")

conf = wtx.get("confirmations", 0)
check("the tx is confirmed", conf >= 1, "mine a block (Step 5)")
if conf >= 1:
    check("RAW_TX_BLOCK_HEIGHT is the block that confirmed it",
          A.get("RAW_TX_BLOCK_HEIGHT") == str(wtx.get("blockheight")), "read it from getrawtransaction/gettransaction")
    try:
        cli("getrawtransaction", txid, 1)
        check("getrawtransaction finds it without a blockhash (txindex on)", True)
    except Exception:
        check("getrawtransaction finds it without a blockhash (txindex on)", False, "enable txindex=1 (Stage 01) and restart")

print(f"\n{sum(results)}/{len(results)} checks passed.")
sys.exit(0 if all(results) else 1)
PY
