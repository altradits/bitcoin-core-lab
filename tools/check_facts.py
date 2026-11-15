#!/usr/bin/env python3
"""check_facts.py: checks the short factual answers of reading worksheets.

Usage (from the lab root or via ./lab.sh check NN):
    python3 tools/check_facts.py <stage-dir> [worksheet-id]

Each stage that has reading worksheets ships a facts.json with, per worksheet, the
answer keys you write into my-work/<stage>/answers.env (KEY=value, one per line).
Only salted hashes of the accepted answers are stored, so this file and facts.json
never show an answer. A FAIL tells you which question to re-read, not the value.

Normalisation before hashing: trimmed, lower-case, all whitespace removed, surrounding
quotes/backticks removed, a trailing "()" removed, a leading "0x" removed.
"""
import hashlib
import json
import os
import sys


def norm(value):
    v = value.strip().strip("`'\"").strip()
    v = "".join(v.split()).lower()
    if v.endswith("()"):
        v = v[:-2]
    if v.startswith("0x"):
        v = v[2:]
    return v


def digest(key, value):
    return hashlib.sha256(f"bcl:{key}:{norm(value)}".encode()).hexdigest()[:20]


def load_answers(path):
    answers = {}
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                answers[k.strip()] = v.strip()
    return answers


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    stage_dir = os.path.abspath(sys.argv[1])
    only = sys.argv[2] if len(sys.argv) > 2 else None
    lab = os.path.dirname(stage_dir)
    stage = os.path.basename(stage_dir)
    facts_path = os.path.join(stage_dir, "facts.json")
    if not os.path.exists(facts_path):
        print(f"FAIL: no facts.json in {stage}")
        return 2
    facts = json.load(open(facts_path, encoding="utf-8"))
    work = os.environ.get("MY_WORK", os.path.join(lab, "my-work", stage))
    ans_path = os.environ.get("ANSWERS", os.path.join(work, "answers.env"))
    answers = load_answers(ans_path)
    if not answers:
        print(f"FAIL: no answers yet -- write KEY=value lines in {ans_path}")
    total = passed = 0
    for wid, sheet in facts.items():
        if only and wid != only:
            continue
        print(f"--- {wid}: {sheet['worksheet']}")
        for key, spec in sheet["keys"].items():
            total += 1
            given = answers.get(key)
            if given is None or given == "":
                print(f"FAIL: {key} -- missing ({spec['q']})")
                continue
            if digest(key, given) in spec["accept"]:
                passed += 1
                print(f"PASS: {key}")
            else:
                print(f"FAIL: {key} -- not right yet; re-read {spec['q']}")
    print(f"\n{passed}/{total} facts correct.")
    return 0 if total and passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
