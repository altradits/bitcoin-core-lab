#!/usr/bin/env bash
# check_policy.sh — checker for exercises/04-policy-vs-consensus.md
# Checks the reject reasons you observed and how you classified them. Offline (no node needed).
#   MY_WORK, ANSWERS as in the other checkers.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import os, sys

LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ANS_PATH = os.environ.get("ANSWERS", os.path.join(WORK, "answers.env"))
results = []

def check(name, ok, why=""):
    results.append(bool(ok))
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))

A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            A[k.strip()] = v.strip().strip('"').strip("'")
check("answers file exists", os.path.exists(ANS_PATH), f"copy exercises/answers.env.template to {ANS_PATH}")

def eq(key, want, why):
    check(key, A.get(key, "").strip().lower() == str(want).lower(), why)

LAYER_WHY = "is a block with this tx invalid (consensus), merely non-standard (policy), or did only the RPC refuse (rpc)?"
eq("MAXFEE_ERROR_CODE", -25, "copy the 'error code' line sendrawtransaction printed")
eq("MAXFEE_TMA_REASON", "max-fee-exceeded", "copy reject-reason from testmempoolaccept with the default maxfeerate")
eq("MAXFEE_LAYER", "rpc", LAYER_WHY)
eq("DUST_REASON", "dust", "copy reject-reason exactly")
eq("DUST_LAYER", "policy", LAYER_WHY)
# P2WPKH output: 8 + 1 + 22 = 31 bytes; spending input counted as 32+4+1+107/4+4 = 67; (31+67) * 3 sat/vB
eq("DUST_THRESHOLD_P2WPKH_SATS", (31 + (32 + 4 + 1 + 107 // 4 + 4)) * 3, "GetDustThreshold: (output size + discounted input size) * 3 sat/vB")
eq("BELOWOUT_REASON", "bad-txns-in-belowout", "copy reject-reason exactly")
eq("BELOWOUT_LAYER", "consensus", LAYER_WHY)
eq("NONFINAL_REASON", "non-final", "copy reject-reason exactly")
eq("NONFINAL_LAYER", "consensus", LAYER_WHY)
lt = A.get("NONFINAL_LOCKTIME", "")
check("LOCKTIME_FIRST_OK_TIP", lt.isdigit() and A.get("LOCKTIME_FIRST_OK_TIP") == lt,
      "IsFinalTx compares nLockTime with tip+1 using '<'; which tip makes locktime < tip+1 first true?")
eq("VERSION_REASON", "version", "copy reject-reason exactly")
eq("VERSION_LAYER", "policy", LAYER_WHY)

print(f"\n{sum(results)}/{len(results)} checks passed.")
sys.exit(0 if all(results) else 1)
PY
