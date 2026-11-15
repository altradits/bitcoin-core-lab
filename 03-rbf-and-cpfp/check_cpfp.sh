#!/usr/bin/env bash
# check_cpfp.sh — outcome checker for exercises/03-cpfp-package-feerate.md
#   BTC_CLI (default "bitcoin-cli -regtest"), MY_WORK, ANSWERS
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, math, os, re, shlex, subprocess, sys

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

def done():
    print(f"\n{sum(results)}/{len(results)} checks passed.")
    sys.exit(0 if results and all(results) else 1)

A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            A[k.strip()] = v.strip().strip('"').strip("'")
check("answers file exists", os.path.exists(ANS_PATH), f"copy exercises/answers.env.template to {ANS_PATH}")

def num(key):
    try:
        return float(A.get(key, ""))
    except ValueError:
        return None

def wtx(txid, wallet):
    if not re.fullmatch(r"[0-9a-f]{64}", txid or ""):
        return None
    try:
        return cli("gettransaction", txid, "true", "true", wallet=wallet)
    except Exception:
        return None

try:
    cli("getblockcount")
except Exception as e:
    check("node reachable via BTC_CLI", False, str(e)); done()

p = wtx(A.get("PARENT_TXID", "").lower(), "kisumu_miner")
c = wtx(A.get("CHILD_TXID", "").lower(), "kisumu_merchant")
check("PARENT known to kisumu_miner", p, "fill PARENT_TXID")
check("CHILD known to kisumu_merchant", c, "fill CHILD_TXID; the merchant wallet must sign the child")
if not (p and c):
    done()

pfee = round(-p["fee"] * 1e8)
pv = p["decoded"]["vsize"]
# child fee: input value (parent output) minus outputs
spent = [i for i in c["decoded"]["vin"] if i["txid"] == p["txid"]]
check("CHILD spends an output of PARENT", spent, "the child's input must be the parent's merchant output")
if not spent:
    done()
in_val = sum(round(p["decoded"]["vout"][i["vout"]]["value"] * 1e8) for i in spent)
check("CHILD spends only PARENT outputs", len(spent) == len(c["decoded"]["vin"]), "one input, from the parent")
out_val = sum(round(o["value"] * 1e8) for o in c["decoded"]["vout"])
cfee = in_val - out_val
cv = c["decoded"]["vsize"]

check("PARENT feerate is between 1 and 2 sat/vB", 1.0 <= pfee / pv <= 2.0, "the parent must be 'stuck': 1.0-2.0 sat/vB")
check("PARENT_FEE_SATS matches", num("PARENT_FEE_SATS") == pfee)
check("PARENT_VSIZE matches", num("PARENT_VSIZE") == pv)
check("CHILD_VSIZE prediction within 1 vB", num("CHILD_VSIZE") is not None and abs(num("CHILD_VSIZE") - cv) <= 1,
      "1-in-1-out P2WPKH; count base bytes and witness bytes, weight = base*3 + total")
want_child = math.ceil(50 * (pv + (num("CHILD_VSIZE") or cv))) - pfee
check("CHILD_FEE_SATS follows your own arithmetic", num("CHILD_FEE_SATS") is not None and abs(num("CHILD_FEE_SATS") - want_child) <= 50,
      "ceil(50 x (parent vsize + child vsize)) - parent fee")
check("child really paid CHILD_FEE_SATS", num("CHILD_FEE_SATS") == cfee, "the fee on the node differs from your answer")
pkg_rate = (pfee + cfee) / (pv + cv)
check("package feerate >= 50 sat/vB", pkg_rate >= 50)
check("PKG_FEE_SATS", num("PKG_FEE_SATS") == pfee + cfee)
check("PKG_VSIZE", num("PKG_VSIZE") == pv + cv)
check("PKG_FEERATE_SAT_VB (2 decimals)", num("PKG_FEERATE_SAT_VB") is not None and abs(num("PKG_FEERATE_SAT_VB") - pkg_rate) < 0.011)

pb, cb = p.get("blockhash"), c.get("blockhash")
check("parent and child are mined", pb and cb, "mine exactly one block after broadcasting the child")
if pb and cb:
    check("parent and child are in the SAME block", pb == cb, "the child must pull the parent in; mine only after both are in the mempool")
    blk = cli("getblock", pb, "1")
    check("CPFP_BLOCK_HEIGHT", num("CPFP_BLOCK_HEIGHT") == blk["height"])
    order = blk["tx"]
    check("parent appears before child in the block", order.index(p["txid"]) < order.index(c["txid"]))
done()
PY
