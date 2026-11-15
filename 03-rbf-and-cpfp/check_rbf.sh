#!/usr/bin/env bash
# check_rbf.sh — outcome checker for exercises/01-rbf-by-hand.md and 02-full-rbf-no-signal.md
# Inspects YOUR transactions on the node. Never prints an answer.
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
try:
    cli("getblockcount")
except Exception as e:
    check("node reachable via BTC_CLI", False, str(e)); done()

def wtx(txid):
    """Wallet view of a tx (works for replaced txs too)."""
    if not re.fullmatch(r"[0-9a-f]{64}", txid or ""):
        return None
    try:
        return cli("gettransaction", txid, "true", "true", wallet="kisumu_miner")
    except Exception:
        return None

def outpoints(t):
    return {(i["txid"], i["vout"]) for i in t["decoded"]["vin"]}

def sats(btc):
    return round(abs(btc) * 100_000_000)

def in_mempool(txid):
    try:
        cli("getmempoolentry", txid); return True
    except Exception:
        return False

def num(key):
    try:
        return float(A.get(key, ""))
    except ValueError:
        return None

inc = round(cli("getnetworkinfo")["incrementalfee"] * 100_000_000 / 1000, 3)  # sat/vB

# ---------------- Worksheet 1 ----------------
print("== Worksheet 1")
v1, v2 = wtx(A.get("V1_TXID", "").lower()), wtx(A.get("V2_TXID", "").lower())
check("V1 known to kisumu_miner", v1, "fill V1_TXID with the txid you broadcast first")
check("V2 known to kisumu_miner", v2, "fill V2_TXID with your winning replacement")
if v1 and v2:
    seqs = [i["sequence"] for i in v1["decoded"]["vin"]]
    check("V1 signals BIP125 on every input", all(s <= 0xfffffffd for s in seqs), "the worksheet asks for an explicit sequence of 0xfffffffd")
    check("V1 fee is 200 sat", sats(v1["fee"]) == 200, "exactly 200 sat, computed from input minus outputs")
    check("V2 conflicts with V1 (shares an input)", outpoints(v1) & outpoints(v2), "a replacement must spend at least one of the same outpoints")
    check("V1 is no longer in the mempool", not in_mempool(v1["txid"]), "after V2 is accepted, V1 must be evicted")
    check("V1 never confirmed", v1.get("confirmations", 0) <= 0, "V1 should have been replaced, not mined")
    check("V2 is in the mempool or a block", in_mempool(v2["txid"]) or v2.get("confirmations", 0) > 0)
    v2fee = sats(v2["fee"])
    check("V2 fee is 5000 sat", v2fee == 5000)
    v2vsize = v2["decoded"]["vsize"]
    check("V2_VSIZE matches the node", num("V2_VSIZE") == v2vsize, "read vsize from getmempoolentry or decoderawtransaction")
    check("V1_VSIZE recorded", num("V1_VSIZE") and abs(num("V1_VSIZE") - v1["decoded"]["vsize"]) < 0.5)
    want_min = 200 + math.ceil(inc * (num("V1_VSIZE") or v1["decoded"]["vsize"]))
    got = num("MIN_REPLACEMENT_FEE_SATS")
    check("MIN_REPLACEMENT_FEE_SATS (rule 3 + rule 4 arithmetic)", got is not None and abs(got - want_min) <= 1,
          "old fee + ceil(incrementalfee in sat/vB x replacement vsize); read incrementalfee from getnetworkinfo")
check("RULE_FOR_MIN_ADDITIONAL", A.get("RULE_FOR_MIN_ADDITIONAL", "").strip() == "4", "which numbered rule talks about the additional fee paying for bandwidth?")
check("BAD_REJECT_REASON", A.get("BAD_REJECT_REASON", "").strip().lower() == "insufficient fee", "copy the short reject-reason exactly")
check("BAD_ADDITIONAL_SATS", num("BAD_ADDITIONAL_SATS") == 50, "the first number in the long message, converted to sat")
req = num("BAD_REQUIRED_SATS")
check("BAD_REQUIRED_SATS is incrementalfee x vsize", req is not None and v1 is not None and abs(req - inc * v1["decoded"]["vsize"]) <= 1,
      "the second number in the long message, converted to sat")

# ---------------- Worksheet 2 ----------------
print("== Worksheet 2")
n1, n2 = wtx(A.get("NS1_TXID", "").lower()), wtx(A.get("NS2_TXID", "").lower())
check("NS1 known to kisumu_miner", n1)
check("NS2 known to kisumu_miner", n2)
if n1 and n2:
    check("NS1 does not signal BIP125", all(i["sequence"] > 0xfffffffd for i in n1["decoded"]["vin"]), "use nSequence 0xfffffffe")
    check("NS2 conflicts with NS1", outpoints(n1) & outpoints(n2))
    check("NS1 was replaced (not in mempool, never confirmed)", not in_mempool(n1["txid"]) and n1.get("confirmations", 0) <= 0)
    check("NS1_BIP125_FIELD", A.get("NS1_BIP125_FIELD", "").lower() == "false", "what did getmempoolentry print for bip125-replaceable?")
check("FULLRBF_DEFAULT_VERSION", A.get("FULLRBF_DEFAULT_VERSION", "").rstrip(".0") in ("28",), "see the History section of doc/policy/mempool-replacements.md")
check("FULLRBF_DEFAULT_PR", A.get("FULLRBF_DEFAULT_PR", "").lstrip("#") == "30493")
done()
PY
