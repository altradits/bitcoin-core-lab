#!/usr/bin/env bash
# check_truc.sh — outcome checker for exercises/01..03 (TRUC package, sibling eviction, ephemeral dust)
#   BTC_CLI (default "bitcoin-cli -regtest"), MY_WORK, ANSWERS
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

def cli(*args):
    p = subprocess.run(CLI + [str(a) for a in args], capture_output=True, text=True)
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

def tx(key):
    """Decoded tx from the node (needs txindex=1, which your Stage 01 bitcoin.conf sets)."""
    t = A.get(key, "").lower()
    if not re.fullmatch(r"[0-9a-f]{64}", t):
        return None
    try:
        return cli("getrawtransaction", t, "1")
    except Exception:
        pass
    try:  # evicted txs are not in txindex; the miner wallet still remembers them
        w = subprocess.run(CLI + ["-rpcwallet=kisumu_miner", "gettransaction", t, "true", "true"], capture_output=True, text=True)
        if w.returncode == 0:
            j = json.loads(w.stdout)
            d = j["decoded"]
            if j.get("blockhash"):
                d["blockhash"] = j["blockhash"]
            return d
    except Exception:
        pass
    return None

def in_mempool(txid):
    try:
        cli("getmempoolentry", txid); return True
    except Exception:
        return False

def fee_sats(t):
    total_in = 0
    for i in t["vin"]:
        prev = cli("getrawtransaction", i["txid"], "1")
        total_in += round(prev["vout"][i["vout"]]["value"] * 1e8)
    return total_in - sum(round(o["value"] * 1e8) for o in t["vout"])

def num(key):
    try:
        return float(A.get(key, ""))
    except ValueError:
        return None

def eq(key, want, why):
    check(key, A.get(key, "").strip().lower() == want.lower(), why)

print("== Worksheet 1")
P, C3 = tx("P_TXID"), tx("C3_TXID")
check("P found on node", P, "fill P_TXID; is txindex=1 in your bitcoin.conf?")
check("C3 found on node", C3, "fill C3_TXID")
eq("P_ALONE_REASON", "min relay fee not met", "copy the short reject-reason")
eq("V2_CHILD_ERROR", "TRUC-violation", "the word before the first comma of package_msg")
if P and C3:
    check("P is version 3", P["version"] == 3, "edit the first 4 bytes")
    check("P has two outputs", len(P["vout"]) == 2, "Worksheet 2 needs output 1")
    check("P pays 0 fee", fee_sats(P) == 0)
    check("C3 is version 3", C3["version"] == 3)
    check("C3 spends P", any(i["txid"] == P["txid"] for i in C3["vin"]))
    rate = fee_sats(C3) / (P["vsize"] + C3["vsize"])
    p = num("PKG_FEERATE_PREDICTED_SAT_VB")
    check("PKG_FEERATE_PREDICTED_SAT_VB within 0.5 sat/vB", p is not None and abs(p - rate) <= 0.5, "fee / (vsize P + vsize C3)")
    e = num("PKG_EFFECTIVE_FEERATE_SAT_VB")
    check("PKG_EFFECTIVE_FEERATE_SAT_VB", e is not None and abs(e - rate) <= 0.06, "convert BTC/kvB to sat/vB: x 100,000")

print("== Worksheet 2")
S = tx("S_TXID")
check("S found on node", S, "fill S_TXID")
eq("S_CHEAP_REASON", "insufficient fee (including sibling eviction)", "copy reject-reason exactly, including the part in brackets")
if P and C3 and S:
    check("S is version 3", S["version"] == 3)
    s_out = {(i["txid"], i["vout"]) for i in S["vin"]}
    c_out = {(i["txid"], i["vout"]) for i in C3["vin"]}
    check("S spends P but not the same outpoint as C3", any(t == P["txid"] for t, _ in s_out) and not (s_out & c_out),
          "S must spend P's OTHER output, so the replacement is by sibling eviction, not a direct conflict")
    check("C3 was evicted (not in mempool, not mined)", not in_mempool(C3["txid"]) and not C3.get("blockhash"))
    check("S is mined in the same block as P", S.get("blockhash") and S.get("blockhash") == P.get("blockhash"), "mine one block after S")
    want = fee_sats(C3) + S["vsize"] * round(cli("getnetworkinfo")["incrementalfee"] * 1e5, 3)
    m = num("S_MIN_FEE_SATS")
    check("S_MIN_FEE_SATS (C3 fee + incremental x vsize(S))", m is not None and abs(m - want) <= 2)
    check("S really paid at least S_MIN_FEE_SATS", m is not None and fee_sats(S) >= m)

print("== Worksheet 3")
E, EC = tx("E_TXID"), tx("EC_TXID")
check("E found", E); check("EC found", EC)
eq("E_ALONE_REASON", "min relay fee not met", "a 0-fee tx alone; same reason as Worksheet 1")
eq("UNSPENT_DUST_PKG_MSG", "unspent-dust", "copy package_msg exactly")
eq("MISSING_SPEND_REASON", "missing-ephemeral-spends", "the child's error in tx-results, the part before the first comma")
if E and EC:
    zero = [n for n, o in enumerate(E["vout"]) if round(o["value"] * 1e8) == 0]
    check("E has exactly one 0-value output", len(zero) == 1)
    check("E is 0-fee and version 3", fee_sats(E) == 0 and E["version"] == 3)
    check("EC spends E's dust output", zero and any(i["txid"] == E["txid"] and i["vout"] == zero[0] for i in EC["vin"]))
    check("E and EC mined together", E.get("blockhash") and E.get("blockhash") == EC.get("blockhash"))
done()
PY
