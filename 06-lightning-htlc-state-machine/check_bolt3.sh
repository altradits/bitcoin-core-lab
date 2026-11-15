#!/usr/bin/env bash
# check_bolt3.sh — offline checker for exercises/03-bolt3-compare.md (answer hashes only)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import hashlib, os, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ANS_PATH = os.environ.get("ANSWERS", os.path.join(WORK, "answers.env"))
A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1); A[k.strip()] = v.strip().strip('"').strip("'").strip("`<>")
H = lambda s: hashlib.sha256(s.strip().lower().encode()).hexdigest()[:16]
EXPECT = {
    "BOLT3_HASH_OPCODE": {"fc79679ca1a5d1ae"},
    "BOLT3_HASH_LEN": {"f5ca38f748a1d6ea"},
    "RECEIVED_TIMEOUT_OPCODE": {"8ae33b19bd256ec2", "93ee83351d84a2df"},
    "HTLC_TIMEOUT_TX_FIELD": {"51e426b70e874098", "aeac8d9bbe004008"},
    "TO_LOCAL_DELAY_OPCODE": {"f769ea31bfc983c8", "cd09572320260e4c"},
    "PENALTY_KEY_NAME": {"93bd0eb0cb3a47d4", "30189c7f01c2f653", "85de20d6f61dd760"},
}
ok = 0
for k, want in EXPECT.items():
    g = H(A.get(k, "")) in want; ok += g
    print(("PASS: " if g else "FAIL: ") + k + ("" if g else " -- answer from the BOLT 3 text"))
print(f"\n{ok}/{len(EXPECT)} checks passed."); sys.exit(0 if ok == len(EXPECT) else 1)
PY
