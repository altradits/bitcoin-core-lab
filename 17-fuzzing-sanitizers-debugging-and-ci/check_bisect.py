#!/usr/bin/env python3
"""Checker for Stage 17 / Exercise 17.6 (git bisect drill).

Put the full commit hash that `git bisect` reported as "the first bad commit" on the first
line of my-work/17-fuzzing-sanitizers-debugging-and-ci/bisect-result.txt, then run:

  python3 17-fuzzing-sanitizers-debugging-and-ci/check_bisect.py [BITCOIN_REPO]

The "regression" you hunted: a node that used to default -incrementalrelayfee to
1000 sat/kvB now defaults to something else. The checker verifies that YOUR commit is the
one that changed the DEFAULT_INCREMENTAL_RELAY_FEE value in src/policy/policy.h (parent
has the old value, commit has a different one). It does not print the answer.
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
BTC = sys.argv[1] if len(sys.argv) > 1 else "/Users/mac/bitcoin"
RESULT = os.path.join(REPO, "my-work", "17-fuzzing-sanitizers-debugging-and-ci", "bisect-result.txt")
PAT = re.compile(r"DEFAULT_INCREMENTAL_RELAY_FEE\{(\d+)\}")


def show(rev):
    p = subprocess.run(["git", "-C", BTC, "show", f"{rev}:src/policy/policy.h"], capture_output=True, text=True)
    if p.returncode != 0:
        return None
    m = PAT.search(p.stdout)
    return m.group(1) if m else None


def main():
    if not os.path.exists(RESULT):
        print(f"FAIL: {RESULT} not found")
        sys.exit(1)
    first = open(RESULT).read().split()
    if not first:
        print("FAIL: bisect-result.txt is empty")
        sys.exit(1)
    rev = first[0]
    if not re.fullmatch(r"[0-9a-f]{7,40}", rev):
        print("FAIL: first token is not a commit hash")
        sys.exit(1)
    after, before = show(rev), show(rev + "^")
    if after is None or before is None:
        print("FAIL: commit (or its parent) not found in the repo, or policy.h missing there")
        sys.exit(1)
    if before == "1000" and after != "1000":
        print("PASS: that commit is where the default changed. Now read its message and the PR that merged it.")
        print("RESULT: PASS")
        return
    if before == after:
        print("FAIL: the value is the same before and after this commit — keep bisecting (good/bad marked correctly?)")
    else:
        print("FAIL: the value changed here, but not from the value your 'good' commit had")
    sys.exit(1)


if __name__ == "__main__":
    main()
