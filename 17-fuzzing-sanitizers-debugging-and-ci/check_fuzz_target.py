#!/usr/bin/env python3
"""Checker for Stage 17 / Exercise 17.3 (your new fuzz target `taproot_merkle`).

Usage:
  python3 17-fuzzing-sanitizers-debugging-and-ci/check_fuzz_target.py [WORKTREE] [BUILD_DIR]

  WORKTREE   your Bitcoin Core worktree (default: /Users/mac/bitcoin-fuzz)
  BUILD_DIR  fuzz build dir inside it (default: first of build_fuzz_nosan, build_fuzz, build_fuzz_mac)

Static checks (always): the file exists, registers FUZZ_TARGET(taproot_merkle), uses
FuzzedDataProvider, calls the three taproot hash functions, asserts something, and is
listed in src/test/fuzz/CMakeLists.txt.
Dynamic checks (only if you built the fuzz binary): the target is compiled in, and it
runs cleanly over every input in my-work/17-fuzzing-sanitizers-debugging-and-ci/taproot_merkle_corpus/ (if that dir exists).
It never prints a solution.
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
WT = sys.argv[1] if len(sys.argv) > 1 else "/Users/mac/bitcoin-fuzz"
CORPUS = os.path.join(REPO, "my-work", "17-fuzzing-sanitizers-debugging-and-ci", "taproot_merkle_corpus")

fails = 0


def result(ok, msg):
    global fails
    print(("PASS: " if ok else "FAIL: ") + msg)
    if not ok:
        fails += 1


def main():
    src = os.path.join(WT, "src", "test", "fuzz", "taproot_merkle.cpp")
    if not os.path.exists(src):
        print(f"FAIL: {src} not found. Did you create the worktree and copy the skeleton?")
        sys.exit(1)
    code = open(src).read()
    # strip // comments so TODO text does not count
    body = re.sub(r"//.*", "", code)
    result(re.search(r"FUZZ_TARGET\(\s*taproot_merkle\b", body) is not None, "registers FUZZ_TARGET(taproot_merkle)")
    result("FuzzedDataProvider" in body and "#include <test/fuzz/FuzzedDataProvider.h>" in code, "uses FuzzedDataProvider")
    for fn in ("ComputeTapleafHash", "ComputeTapbranchHash", "ComputeTaprootMerkleRoot"):
        result(fn + "(" in body, f"calls {fn}")
    result(len(re.findall(r"\bassert\s*\(", body)) >= 3, "has at least three assert(...) invariants")
    result("TODO" not in code, "no TODO left in the file")
    cml = os.path.join(WT, "src", "test", "fuzz", "CMakeLists.txt")
    result(os.path.exists(cml) and re.search(r"^\s*taproot_merkle\.cpp\s*$", open(cml).read(), re.M) is not None,
           "taproot_merkle.cpp is listed in src/test/fuzz/CMakeLists.txt")

    cands = [sys.argv[2]] if len(sys.argv) > 2 else ["build_fuzz_nosan", "build_fuzz", "build_fuzz_mac"]
    binary = next((os.path.join(WT, c, "bin", "fuzz") for c in cands if os.path.exists(os.path.join(WT, c, "bin", "fuzz"))), None)
    if binary is None:
        print("INFO: no fuzz binary found yet; dynamic checks skipped (build it, then re-run)")
    else:
        env = dict(os.environ, PRINT_ALL_FUZZ_TARGETS_AND_ABORT="1")
        out = subprocess.run([binary], env=env, capture_output=True, text=True)
        names = (out.stdout + out.stderr).split()
        result("taproot_merkle" in names, f"{binary} was built with your target")
        if os.path.isdir(CORPUS) and os.listdir(CORPUS):
            env = dict(os.environ, FUZZ="taproot_merkle")
            run = subprocess.run([binary, CORPUS], env=env, capture_output=True, text=True, timeout=600)
            result(run.returncode == 0, f"target runs cleanly over {len(os.listdir(CORPUS))} corpus inputs")
            if run.returncode != 0:
                print((run.stderr or run.stdout)[-1500:])
        else:
            print(f"INFO: put a few input files in {CORPUS} to enable the corpus run")

    if fails:
        print(f"RESULT: FAIL ({fails} problem(s))")
        sys.exit(1)
    print("RESULT: PASS")


if __name__ == "__main__":
    main()
