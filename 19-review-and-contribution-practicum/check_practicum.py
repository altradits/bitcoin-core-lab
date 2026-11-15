#!/usr/bin/env python3
"""check_practicum.py: outcome checker for Stage 19 exercises 3, 5 and 6.

  python3 check_practicum.py club        # 19.3 Review Club: answer files + tracker rows
  python3 check_practicum.py comms       # 19.5 reproduction, post draft, seminar prep + retro
  python3 check_practicum.py evidence    # 19.6 BTRUST_READINESS_TRACKER.md rows are well-formed
  python3 check_practicum.py evidence --online   # also asks GitHub (gh) whether your PR rows are true
  python3 check_practicum.py             # club + comms + evidence

It checks that your files exist and are really filled in. It cannot judge quality: that is
what the meeting log, the issue thread and real reviewers are for. It never writes anything.
"""
import os
import re
import subprocess
import sys
from glob import glob

HERE = os.path.dirname(os.path.abspath(__file__))
LAB, STAGE = os.path.dirname(HERE), os.path.basename(HERE)
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
TRACKER = os.environ.get("TRACKER", os.path.join(LAB, "BTRUST_READINESS_TRACKER.md"))
res = []


def check(name, ok, why=""):
    res.append(bool(ok))
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))


def read(p):
    return open(p, encoding="utf-8").read() if os.path.exists(p) else ""


def section(text, heading):
    """Body under a '## heading' (case-insensitive prefix match) up to the next '## '."""
    m = re.search(r"^##\s+" + re.escape(heading) + r"[^\n]*\n(.*?)(?=^##\s|\Z)", text, re.M | re.S | re.I)
    return m.group(1) if m else ""


def filled_lines(body):
    return [l for l in body.splitlines() if l.strip() and l.strip() not in ("-", "1.", "2.", "3.") and "____" not in l]


def tracker_rows(heading):
    """Rows (list of cells) of the first table under a '## N. heading' section of the tracker."""
    body = section(read(TRACKER), heading)
    rows = []
    for line in body.splitlines():
        if not line.startswith("|") or re.match(r"^\|[-\s|:]+\|$", line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    return rows[1:] if rows else []  # drop header row


def real(rows, skip_first=False):
    out = []
    for r in rows:
        cells = r[1:] if skip_first else r
        if any(c for c in cells):
            out.append(r)
    return out


def club():
    print("--- 19.3 PR Review Club")
    files = sorted(glob(os.path.join(WORK, "review-club", "*-answers.md")))
    good = 0
    for f in files:
        t = read(f)
        mine, after = filled_lines(section(t, "My answers")), filled_lines(section(t, "After reading the log"))
        ok = len(mine) >= 3 and len(after) >= 3
        good += ok
        check(f"{os.path.basename(f)} has your answers and a post-log comparison", ok,
              "needs '## My answers' and '## After reading the log', each with real content")
    check("at least 3 past-meeting answer files", good >= 3,
          f"{good} complete so far in my-work/{STAGE}/review-club/<PR>-answers.md")
    rows = real(tracker_rows("6. PR Review Club"))
    live = [r for r in rows if len(r) > 2 and re.search(r"https://bitcoincore\.reviews/\d+", r[1])
            and r[2].lower().startswith("y")]
    check("tracker section 6 lists at least 2 live meetings you attended (bitcoincore.reviews link, Attended = yes)",
          len(live) >= 2, f"{len(live)} so far")


def comms():
    print("--- 19.5 Technical communication")
    repros = glob(os.path.join(WORK, "comms", "repro-*.md"))
    ok_repro = False
    for f in repros:
        t = read(f)
        ok = ("____" not in t and re.search(r"\b[0-9a-f]{40}\b", t) is not None
              and re.search(r"\b\d+\s*/\s*\d+\b", section(t, "How often")) is not None
              and len(filled_lines(section(t, "Actual"))) >= 2)
        ok_repro = ok_repro or ok
        check(f"{os.path.basename(f)}: no blanks, full commit hash, n/m failure rate, real log lines", ok,
              "follow the Part A rules and templates/bug-reproduction.md")
    if not repros:
        check("a reproduction write-up exists", False, f"my-work/{STAGE}/comms/repro-<issue>.md")
    post = read(os.path.join(WORK, "comms", "post-draft.md"))
    words = len(re.findall(r"\w+", post))
    check("post draft written (at least 150 words, your own)", words >= 150, f"{words} words in comms/post-draft.md")
    preps = glob(os.path.join(WORK, "comms", "seminar-*-prep.md"))
    ok_prep = False
    for f in preps:
        t = read(f)
        qs = [l for l in section(t, "Open questions").splitlines() if re.match(r"\s*\d+\.\s+\S", l)]
        ok_prep = ok_prep or ("____" not in t and len(qs) >= 3)
    check("seminar prep filled in (no blanks, 3+ open questions)", ok_prep,
          f"copy templates/seminar-prep.md to my-work/{STAGE}/comms/seminar-<date>-prep.md")
    retros = [f for f in glob(os.path.join(WORK, "comms", "seminar-*-retro.md")) if len(filled_lines(read(f))) >= 5]
    check("seminar retro written after the meetup", bool(retros), f"my-work/{STAGE}/comms/seminar-<date>-retro.md")


def evidence(online):
    print("--- 19.6 Btrust evidence (BTRUST_READINESS_TRACKER.md)")
    if not os.path.exists(TRACKER):
        check("tracker exists", False, TRACKER)
        return
    url = re.compile(r"https://\S+")
    reviews = real(tracker_rows("3. Reviews posted"), skip_first=True)
    prs = real(tracker_rows("4. My PRs"), skip_first=True)
    refs = real(tracker_rows("8. References"))
    total = len(reviews) + len(prs)
    check("at least one public item recorded", total > 0, "record only links that exist")
    for r in reviews:
        link = r[3] if len(r) > 3 else ""
        typ = r[4] if len(r) > 4 else ""
        tested = r[5] if len(r) > 5 else ""
        check(f"review #{r[0]}: link to your comment", url.search(link) is not None, "paste the comment URL")
        if re.search(r"\bACK\b", typ) and not re.search(r"concept|approach", typ, re.I):
            check(f"review #{r[0]}: an ACK names the commit it covers", re.search(r"\b[0-9a-f]{7,40}\b", typ) is not None,
                  "write ACK <commit>")
        check(f"review #{r[0]}: says what you tested yourself", bool(tested), "fill 'What I tested myself'")
    merged = 0
    for r in prs:
        ref, status = (r[1] if len(r) > 1 else ""), (r[4].lower() if len(r) > 4 else "")
        check(f"PR #{r[0]}: has a repo#PR or URL", bool(re.search(r"#\d+|https://", ref)), "e.g. bitcoin/bitcoin#12345")
        if status.startswith("merged"):
            check(f"PR #{r[0]}: merged PR has a merged date", bool(r[5] if len(r) > 5 else ""), "fill 'Merged date'")
            if (r[6] if len(r) > 6 else "").lower().startswith("y") and (r[7] if len(r) > 7 else "").lower().startswith("y"):
                merged += 1
        if online:
            m = re.search(r"([\w.-]+/[\w.-]+)#(\d+)", ref) or re.search(r"github\.com/([\w.-]+/[\w.-]+)/pull/(\d+)", ref)
            if m:
                p = subprocess.run(["gh", "pr", "view", m.group(2), "-R", m.group(1), "--json", "state,author"],
                                   capture_output=True, text=True)
                state = re.search(r'"state":"(\w+)"', p.stdout)
                gh_state = state.group(1).lower() if state else "?"
                want = {"merged": "merged", "open": "open", "closed": "closed"}.get(status.split()[0] if status else "", None)
                check(f"PR #{r[0]}: GitHub says {gh_state}", p.returncode == 0 and (want is None or want == gh_state),
                      "status in the tracker must match GitHub")
                user = os.environ.get("GITHUB_USER")
                if user:
                    check(f"PR #{r[0]}: authored by {user}", f'"login":"{user}"' in p.stdout)
    print(f"INFO: merged code PRs (not docs, not good-first-issue): {merged}/5 for the Starter Grant; "
          f"references recorded: {len(refs)}/2 (re-check the live requirements before applying)")


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    online = "--online" in sys.argv
    if mode in ("club", "all"):
        club()
    if mode in ("comms", "all"):
        comms()
    if mode in ("evidence", "all"):
        evidence(online)
    if mode not in ("club", "comms", "evidence", "all"):
        print(__doc__)
        return 2
    print(f"\n{sum(res)}/{len(res)} checks passed.")
    return 0 if res and all(res) else 1


if __name__ == "__main__":
    sys.exit(main())
