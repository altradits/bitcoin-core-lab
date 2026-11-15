#!/usr/bin/env bash
# check_code_reading.sh — offline checker for exercises/04-read-the-code.md
# Compares hashes of your answers, so the answers are not readable here.
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
            k, v = line.split("=", 1)
            A[k.strip()] = v.strip().strip('"').strip("'")
H = lambda s: hashlib.sha256(s.strip().lower().encode()).hexdigest()[:16]
# sha256(answer.lower())[:16]; several values accepted where the question allows it
EXPECT = {
    "RULE4_FUNCTION": {"1e25bfec3142db36"},
    "RULE4_CALLER": {"afd46549cd74c4fb"},
    "MAX_REPLACEMENT_CANDIDATES": {"ad57366865126e55"},
    "V29_SELECTION_METHOD": {"7e26830b5a9fe5f4"},
    "MASTER_SELECTION_METHOD": {"da088e8692433c1d"},
    "DIAGRAM_FUNCTION": {"9729080047acd032"},
    "INCREMENTAL_V29": {"40510175845988f1"},
    "INCREMENTAL_MASTER": {"ad57366865126e55"},
    "BUMPFEE_CREATE_FUNCTION": {"4efb61f5a2225628"},
    "RULE4_TEST_FILE": {"2ae82d302adecf0e", "4e8f61389cdc7990", "663f7a09e9449556"},
}
ok = 0
for k, want in EXPECT.items():
    good = H(A.get(k, "").removesuffix("()")) in want
    ok += good
    print(("PASS: " if good else "FAIL: ") + k + ("" if good else " -- re-read the worksheet question; use git grep"))
print(f"\n{ok}/{len(EXPECT)} checks passed.")
sys.exit(0 if ok == len(EXPECT) else 1)
PY
