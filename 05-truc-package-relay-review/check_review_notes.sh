#!/usr/bin/env bash
# check_review_notes.sh — structure checker for exercises/04-concept-review.md
# It checks shape and that cited paths exist in your Core checkout. It cannot judge your thinking.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import os, re, subprocess, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
ROOT = os.environ.get("BITCOIN_ROOT", os.path.expanduser("~/bitcoin"))
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
NOTES = os.environ.get("NOTES", os.path.join(WORK, "review-28948.md"))
res = []
def check(n, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + n + ("" if ok or not why else f" -- {why}"))
if not os.path.exists(NOTES):
    check("notes file exists", False, f"write {NOTES}"); print(f"\n0/1 checks passed."); sys.exit(1)
text = open(NOTES).read()
sections = {}
for m in re.finditer(r"^## (.+?)\s*$(.*?)(?=^## |\Z)", text, re.M | re.S):
    sections[m.group(1).strip().lower()] = m.group(2)
for h in ["problem", "concept", "alternatives", "approach", "files i read", "tests i ran", "questions"]:
    check(f"section '## {h.title()}'", h in sections, "use the headings exactly as listed")
words = len(re.findall(r"\w+", sections.get("problem", "")))
check("Problem has >= 80 words of your own", words >= 80, f"{words} words")
check("Concept states ACK or NACK", re.search(r"\b(concept\s+)?n?ack\b", sections.get("concept", ""), re.I))
check("Approach states ACK or NACK", re.search(r"\b(approach\s+)?n?ack\b", sections.get("approach", ""), re.I))
paths = set(re.findall(r"\b((?:src|test|doc)/[\w./-]+\.\w+)", sections.get("files i read", "")))
def exists_any(p):
    if os.path.exists(os.path.join(ROOT, p)):
        return True
    for rev in ("master", "7143d43884"):
        if subprocess.run(["git", "-C", ROOT, "cat-file", "-e", f"{rev}:{p}"], capture_output=True).returncode == 0:
            return True
    return False
real = [p for p in paths if exists_any(p)]
check(">= 4 real file paths in Files I read", len(real) >= 4, f"{len(real)} paths found in your Core checkout (working tree, master or the merge commit)")
check("Tests I ran contains a command", re.search(r"(test_runner\.py|\.py\b|test_bitcoin)", sections.get("tests i ran", "")))
q = re.findall(r"\?", sections.get("questions", ""))
check(">= 2 questions", len(q) >= 2)
check("no AI co-author / generated markers", not re.search(r"co-authored-by:.*(claude|gpt|copilot|ai\b)|generated (by|with) (ai|claude|chatgpt)", text, re.I))
print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if all(res) else 1)
PY
