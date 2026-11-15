#!/usr/bin/env bash
# check_anatomy.sh — offline checker for exercises/01-run-and-read.md (compares answer hashes)
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
EXPECT = {
    "EXAMPLE_NUM_NODES": {"4e07408562bedb8b"},
    "CACHE_BLOCKS": {"27badc983df1780b"},
    "MEMPOOL_SYNC_METHOD": {"c8967660da721162"},
    "CREATE_ONE_METHOD": {"8339fadbe02a0bf1"},
    "MINIWALLET_DEFAULT_MODE": {"97aea50a3460aa87"},
    "REGISTER_LIST": {"33583649ebd5825e"},
    "KEEP_TMP_OPTION": {"095e55c1012146fe"},
}
ok = 0
for k, want in EXPECT.items():
    v = A.get(k, "").removesuffix("()").removeprefix("MiniWalletMode.").removeprefix("self.")
    good = H(v) in want
    ok += good
    print(("PASS: " if good else "FAIL: ") + k + ("" if good else " -- answer from the source files named in the worksheet"))
print(f"\n{ok}/{len(EXPECT)} checks passed.")
sys.exit(0 if ok == len(EXPECT) else 1)
PY
