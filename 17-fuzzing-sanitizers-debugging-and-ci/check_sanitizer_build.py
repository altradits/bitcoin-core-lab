#!/usr/bin/env python3
"""check_sanitizer_build.py: outcome checker for exercises/17.4-sanitizers.md.

Checks YOUR artifacts, never prints an answer:
  - the build dir you name in answers.env (ASAN_BUILD_DIR) was configured with ASan and UBSan,
  - test_bitcoin was built there,
  - your journal holds a real AddressSanitizer report and a UBSan "runtime error" line,
  - the throwaway branch was deleted (SANITIZER_REPO, default ~/bitcoin-fuzz).
Usage: python3 check_sanitizer_build.py
"""
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LAB, STAGE = os.path.dirname(HERE), os.path.basename(HERE)
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
res = []


def check(name, ok, why=""):
    res.append(bool(ok))
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))


A = {}
ans = os.path.join(WORK, "answers.env")
if os.path.exists(ans):
    for line in open(ans):
        if "=" in line and not line.lstrip().startswith("#"):
            k, v = line.strip().split("=", 1)
            A[k.strip()] = os.path.expanduser(v.strip().strip('"'))

build = A.get("ASAN_BUILD_DIR", "")
cache = os.path.join(build, "CMakeCache.txt")
san = ""
if os.path.exists(cache):
    m = re.search(r"^SANITIZERS:[A-Z]+=(.*)$", open(cache).read(), re.M)
    san = m.group(1) if m else ""
check("ASAN_BUILD_DIR is a configured CMake build dir", os.path.exists(cache),
      "write ASAN_BUILD_DIR=<path to your build_asan> in answers.env")
check("that build enables ASan and UBSan", "address" in san and "undefined" in san,
      "re-read Part B and doc/developer-notes.md 'Sanitizers'")
check("test_bitcoin was built there", os.path.exists(os.path.join(build, "bin", "test_bitcoin")),
      "build only the test_bitcoin target")
journal = os.path.join(WORK, "journal.md")
j = open(journal).read() if os.path.exists(journal) else ""
check("journal contains a real ASan report you annotated", "ERROR: AddressSanitizer" in j,
      "paste the ASan report from Part C (and annotate it)")
check("journal contains a real UBSan 'runtime error' line", re.search(r"runtime error:", j) is not None,
      "paste the UBSan line from Part C")
repo = os.path.expanduser(A.get("SANITIZER_REPO", "~/bitcoin-fuzz"))
if os.path.isdir(repo):
    p = subprocess.run(["git", "-C", repo, "branch", "--list", "sanitizer-playground"], capture_output=True, text=True)
    check("throwaway branch sanitizer-playground was deleted", p.stdout.strip() == "", "Clean up step")
print(f"\n{sum(res)}/{len(res)} checks passed.")
sys.exit(0 if all(res) else 1)
