#!/usr/bin/env python3
"""progress.py: where you stand against the three mastery gates in CURRICULUM.md.

Run it as `./lab.sh progress`. It reads only your own records:
  - my-work/<stage>/.passed          written by `./lab.sh check NN` the first time every checker passes
  - my-work/quiz-scores.env          you write one line per stage after each self-check quiz:
                                     QUIZ_04=9/10   (answered from memory, then marked against solutions/)
  - BTRUST_READINESS_TRACKER.md      your public evidence (reviews, PRs, Review Club, BitDevs, references)

Items it cannot measure are shown as [you] with the question to ask yourself.
"""
import glob
import os
import re

LAB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORK = os.path.join(LAB, "my-work")
TRACKER = os.environ.get("TRACKER", os.path.join(LAB, "BTRUST_READINESS_TRACKER.md"))


def passed(stage):
    hits = glob.glob(os.path.join(WORK, f"{stage}-*", ".passed"))
    return open(hits[0]).read().strip() if hits else ""


def quiz():
    scores = {}
    p = os.path.join(WORK, "quiz-scores.env")
    if os.path.exists(p):
        for line in open(p):
            m = re.match(r"\s*QUIZ_(\d\d)\s*=\s*(\d+)\s*/\s*(\d+)", line)
            if m and int(m.group(3)) > 0:
                scores[m.group(1)] = int(m.group(2)) / int(m.group(3))
    return scores


def rows(heading):
    text = open(TRACKER, encoding="utf-8").read() if os.path.exists(TRACKER) else ""
    m = re.search(r"^##\s+" + re.escape(heading) + r"[^\n]*\n(.*?)(?=^##\s|\Z)", text, re.M | re.S)
    out = []
    for line in (m.group(1) if m else "").splitlines():
        if line.startswith("|") and not re.match(r"^\|[-\s|:]+\|$", line):
            out.append([c.strip() for c in line.strip().strip("|").split("|")])
    return out[1:]  # drop the header row


def filled(heading, skip_first=True):
    return [r for r in rows(heading) if any(c for c in (r[1:] if skip_first else r))]


def item(state, text):
    mark = {True: "[x]", False: "[ ]", None: "[you]"}[state]
    print(f"  {mark:5} {text}")


def quiz_ok(stages, scores):
    missing = [s for s in stages if s not in scores]
    low = [s for s in stages if s in scores and scores[s] < 0.8]
    ok = not missing and not low
    detail = "" if ok else f" (no score yet: {', '.join(missing) or '-'}; below 80%: {', '.join(low) or '-'})"
    return ok, detail


def main():
    scores = quiz()
    print("Stages whose checkers all passed (./lab.sh check NN):")
    line = []
    for n in range(20):
        s = f"{n:02d}"
        d = passed(s)
        line.append(f"{s}:{'ok' if d else '--'}")
    print("  " + "  ".join(line))
    reviews = filled("3. Reviews posted")
    prs = filled("4. My PRs")
    club = [r for r in filled("6. PR Review Club", skip_first=False) if re.search(r"bitcoincore\.reviews/\d+", " ".join(r))]
    attended = [r for r in club if len(r) > 2 and r[2].lower().startswith("y")]
    spoke = [r for r in attended if len(r) > 3 and r[3].lower().startswith("y")]
    bitdevs = [r for r in filled("7. BitDevs Kisumu") if len(r) > 2 and "https://" in r[2]]
    refs = [r for r in filled("8. References", skip_first=False) if len(r) > 3 and r[3]]
    moved = [r for r in reviews if len(r) > 6 and r[6].lower().startswith("y")]
    merged = [r for r in prs if len(r) > 7 and r[4].lower().startswith("merged")
              and r[6].lower().startswith("y") and r[7].lower().startswith("y")]

    print("\nGate 1: build and test Core, review a test-only PR (target: week 6)")
    item(bool(passed("13")), "Stage 13 checks pass: master built from source, unit test written (./lab.sh check 13)")
    item(bool(passed("04")), "Stage 04 checks pass: your functional test, and it fails under mutation")
    item(None, "You ran the full functional suite with --jobs sized for 8 GB (in your stage 13 journal?)")
    item(len(reviews) >= 1, f"At least 1 public review on a test-only bitcoin/bitcoin PR ({len(reviews)} reviews in tracker)")
    item(len(attended) >= 2 and len(spoke) >= 1, f"Review Club: attended {len(attended)}/2, spoke in {len(spoke)}/1")
    ok, d = quiz_ok(["00", "01", "02", "03", "04", "09", "13"], scores)
    item(ok, "Quizzes 00-04, 09, 13 at 80%+ from memory" + d)

    print("\nGate 2: review a policy/mempool PR with a tested ACK (target: week 20)")
    acks = [r for r in reviews if len(r) > 4 and re.search(r"\bACK\b", r[4]) and r[5]]
    item(None, f"A tested ACK / reasoned NACK on a mempool/policy/validation PR with your own regtest test ({len(acks)} ACK rows with tests recorded)")
    item(len(reviews) >= 10 and len(moved) >= 3, f"10+ public reviews, 3+ that moved the PR ({len(reviews)} / {len(moved)})")
    item(None, "Re-reviewed a PR after a force-push with git range-diff and said what changed")
    item(bool(passed("17")), "Stage 17 checks pass: a fuzz target and a sanitizer build, explained")
    item(len(prs) >= 1, f"Opened at least 1 PR of your own and answered its reviews ({len(prs)} in tracker)")
    ok, d = quiz_ok([f"{n:02d}" for n in [5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18]], scores)
    item(ok, "Quizzes 05-08 and 10-18 at 80%+" + d)
    item(len(bitdevs) >= 3, f"3+ BitDevs Kisumu seminars with a public reading list ({len(bitdevs)})")

    print("\nGate 3: Btrust-application-ready (re-check the live requirements first)")
    plan = open(TRACKER, encoding="utf-8").read() if os.path.exists(TRACKER) else ""
    plan_body = re.search(r"^## 9\..*?(?=^## 10\.)", plan, re.M | re.S)
    plan_done = bool(plan_body) and "______" not in plan_body.group(0)
    item(len(merged) >= 5, f"5+ merged code PRs, not docs, not good-first-issue ({len(merged)})")
    item(len(refs) >= 2, f"2+ references who agreed ({len(refs)})")
    item(plan_done, "Six-month plan written in tracker section 9 (no blanks left)")
    item(None, "Multiple helpful issue/discussion responses (tracker section 5) and willingness to commit full-time")
    print("\nRecord quiz scores in my-work/quiz-scores.env, e.g. QUIZ_04=9/10. Re-run after each stage.")


if __name__ == "__main__":
    main()
