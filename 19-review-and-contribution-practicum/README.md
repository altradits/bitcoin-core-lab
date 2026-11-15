# Stage 19: Review and Contribution Practicum (Capstone)

This stage turns what you know into **public work that other people can check**:
reviews on real `bitcoin/bitcoin` pull requests, PR Review Club answers, a well-made
commit stack, a bug reproduction, a Delving Bitcoin post, and a BitDevs Kisumu
presentation. Each one leaves a public link you can put in your Btrust application.

> **Read this first: the integrity rules.** Everything you post publicly must be in your
> own words and based on testing you did yourself. Bitcoin Core's AI policy
> (`doc/AI_POLICY.md` on `master`, added in commit `31abaa264c`, last changed in
> `f5d7cc66ec`) says, word for word:
>
> - "**AI should not be used to generate comments when communicating with maintainers and other contributors**."
> - "**Do not copy responses from the AI when replying to questions from reviewers.**"
> - "**Pull requests should not be opened or driven by autonomous agents**."
> - "Do not include agents as authors or co-authors of your commits for these reasons."
> - "If you wish to include context from an interaction with AI in your comments, it must be disclosed as such."
>
> `CONTRIBUTING.md` links to that policy and adds: "Contributors are responsible for
> understanding and explaining their own work in their own words."
>
> So in this stage, **templates only contain blanks**. No file in this repo is a ready-to-post
> ACK, review comment, or PR description. If an AI tool helped you *learn* something, the
> sentence you post must still be one you wrote and can defend. If you use an AI coding tool
> that adds a `Co-Authored-By:` line to your commits, **remove that line** before pushing to
> any Bitcoin Core branch (the `check_commit_hygiene.sh` checker flags it).

Facts checked against `~/bitcoin` at local `master` = `e75b76b12c` and
`origin/master` = `ab7e668cc6` ("Merge bitcoin/bitcoin#36611", 2026-10-30), and with
`gh pr view` on 2026-11-09. The Gauntlet merge commits are only on `origin/master`, so
`git fetch` first. `CONTRIBUTING.md` quotes come from `origin/master`. Local `master` differs only in
one sentence of "Committing Patches".
Your local checkout is detached at the 29.x branch (`f490f5562d`), so read upstream docs with
`git show origin/master:<path>`, or better, make a separate **worktree** for review (see
`doc/productivity.md`, section "Multiple working directories with `git worktrees`").

---

## Objectives (competency IDs, as defined in [`../CURRICULUM.md`](../CURRICULUM.md))

| ID | In this stage you... | Where |
| :-- | :-- | :-- |
| `C-REVIEW-1` Triage | Classify a PR by type and risk (the PR-type matrix) and name the invariants it must keep. | Ex. 1, 2 |
| `C-REVIEW-2` Concept & approach | Give a Concept/Approach (N)ACK based on the motivation and prior discussion, with reasons for any NACK. | Ex. 1, 2 |
| `C-REVIEW-3` Code review | Read commit by commit for behaviour changes, locking, bounds, and test coverage. | Ex. 1, 2 |
| `C-REVIEW-4` Tested ACK | Give `ACK <full commit>` that says what you tested, including a break attempt (mutation or reproduction). | Ex. 1, 2 |
| `C-REVIEW-5` Follow-up | Re-review after a force-push with `git range-diff`, and track your comments until they are resolved. | Ex. 1 step 7, Gauntlet R7 |
| `C-REVIEW-6` Review Club | Prepare for, practise with, and attend Bitcoin Core PR Review Club. | Ex. 3 |
| `C-CONTRIB-1` Find work | Find reproductions, intermittent failures, coverage gaps, and review follow-ups, and avoid trivial drive-by PRs. | Ex. 4A |
| `C-CONTRIB-2` Atomic commits | Write atomic, prefixed, well-explained commits and a PR description. | Ex. 4B, 4D |
| `C-CONTRIB-3` Keep a PR alive | Answer every review comment, rebase, squash fixups, and read CI failures. | Ex. 4E, 4F |
| `C-CONTRIB-4` Policy | Follow `doc/AI_POLICY.md`: human authorship, your own words, **no AI co-author trailers**. | Integrity box, Ex. 4 |
| `C-GIT-2` Check out a PR | Fetch any PR by number, check out merge parents, and list commits. | Ex. 1 step 2, Gauntlet |
| `C-GIT-3` Shape history | Use interactive rebase, `fixup!` and `--autosquash`. | Ex. 4D |
| `C-GIT-4` Range-diff | Say exactly what changed between two pushes. | Ex. 1 step 7, 4D |
| `C-GIT-7` Signing | Sign commits with GPG or SSH and verify signatures. | Ex. 4C |
| `C-COMMS-1` Your own words | Write precise technical comments in your own words. | All exercises |
| `C-COMMS-2` Socratic Seminar | Prepare and moderate one PR topic at BitDevs Kisumu. | Ex. 5C |
| `C-COMMS-3` Write-ups | Write a bug reproduction and a technical post. | Ex. 5A, 5B |
| `C-COMMS-4` Community etiquette | Use IRC (Review Club), Delving Bitcoin and mailing-list conventions. | Ex. 3, 5B |
| `C-BTRUST-2` Evidence | Turn every public action into a dated link in [`../BTRUST_READINESS_TRACKER.md`](../BTRUST_READINESS_TRACKER.md). | Ex. 6 |
| `C-BTRUST-3` References | Earn references through real, repeated review of the same contributors' work. | Ex. 6 |

## Prerequisites

- **Recommended:** Stages 13–18. In particular, being able to build Core and run unit and
  functional tests on your own, and the C++ and functional-test reading skills.
- **Early start allowed:** Gauntlet rounds **G01–G02 are tests-only PRs**. You can start them
  around **week 4**, once you can build `test_bitcoin` and run one functional test
  (Stages 01–04, plus `BUILDING_BITCOIN_CORE_FROM_SOURCE.md` Drills 1–4).
- **Tools:** `git` ≥ 2.19 (needed for `range-diff`), the `gh` CLI (read-only use is enough), and an IRC client
  or web.libera.chat.
- **Machine limits (8 GB M1):** build only the targets you need, use `ccache`, keep `-j`
  low (start at `-j4`), and run at most one `bitcoind`. Never run the full extended
  functional suite while anything else is open.

## Estimated time

About **70–90 hours** spread over 8–12 weeks. Allow 3–6 h per Gauntlet round (10 rounds), 2 h to
prepare each Review Club meeting, about 10 h for the contribution exercise, and about 10 h for the writing
tasks. Keep going after that: the habit to keep is **1–2 real reviews a week**.

---

## Exercises (do them in this order; each is a worksheet, not a script)

| # | Worksheet | Produces |
| :-: | :-- | :-- |
| 1 | [`exercises/01-review-method.md`](./exercises/01-review-method.md): the method you use on every PR, plus the PR-type matrix | `my-work/19-review-and-contribution-practicum/method-notes.md` |
| 2 | [`exercises/02-review-gauntlet.md`](./exercises/02-review-gauntlet.md): 10 merged PRs, reviewed blind, then compared with the real thread | `my-work/19-review-and-contribution-practicum/gauntlet/Gxx-*-blind.md` and `-compare.md` |
| 3 | [`exercises/03-pr-review-club.md`](./exercises/03-pr-review-club.md): prepare for, attend, and practice with past meetings | `my-work/19-review-and-contribution-practicum/review-club/` (checked by `python3 check_practicum.py club`) |
| 4 | [`exercises/04-contribution-craft.md`](./exercises/04-contribution-craft.md): finding work, commit hygiene, signing, rebasing, feedback, and a dry-run branch in **your own** clone | a signed, hygienic branch that passes `check_commit_hygiene.sh` |
| 5 | [`exercises/05-technical-communication.md`](./exercises/05-technical-communication.md): bug reproduction, Delving/mailing-list post, BitDevs presentation | `my-work/19-review-and-contribution-practicum/comms/` (checked by `python3 check_practicum.py comms`) |
| 6 | [`exercises/06-btrust-evidence.md`](./exercises/06-btrust-evidence.md): turn each activity into a public link | rows in `../BTRUST_READINESS_TRACKER.md` (checked by `python3 check_practicum.py evidence`) |

Blank templates are in [`exercises/templates/`](./exercises/templates/). Copy them into
`my-work/19-review-and-contribution-practicum/` and fill them in yourself.

Keep a command journal for this stage in `my-work/19-review-and-contribution-practicum/journal.md`, as you have for every other stage.

**Checkers (they check outcomes and never print answers):**

- `bash 19-review-and-contribution-practicum/check_gauntlet.sh [G01..G10]` checks that each round
  has a sealed blind review, the right parent and head commits, tests you ran, a break
  attempt, and an answered comparison rubric.
- `bash 19-review-and-contribution-practicum/check_commit_hygiene.sh <repo> <base>..<branch>`
  checks subject length and prefix, the blank line, the body, no `@` mentions, no agent
  co-author lines, and that every commit is signed.

**Solutions:** [`solutions/`](./solutions/) holds the self-check quiz answers. Open them only after
your answers are written down, or after 3 honest attempts. **There are no model reviews for
the Gauntlet.** The real GitHub thread is the comparison point, and you score yourself.

---

## Theory in brief: the review vocabulary (verified)

Current `CONTRIBUTING.md` ("Peer Review" section) defines:

- **Conceptual review:** `Concept (N)ACK` means "I do (not) agree with the general goal of this pull
  request". `Approach (N)ACK` means `Concept ACK`, but "I do (not) agree with the approach
  of this change". "A `NACK` needs to include a rationale why the change is not worthwhile.
  NACKs without accompanying reasoning may be disregarded."
- **Code review:** "A review begins with `ACK BRANCH_COMMIT`, where `BRANCH_COMMIT` is the top of
  the PR branch, followed by a description of how the reviewer did the review." It then
  describes two kinds of review: "I have tested the code" (change-specific manual testing, not
  only running the existing tests) and "I have not tested the code, but I have reviewed it
  and it looks OK". A "nit" is "a trivial, often non-blocking issue".
- **Informal terms you will see:** `tACK` / `tested ACK`, `utACK` (untested ACK), `crACK`
  (code-review ACK), `lgtm`, `re-ACK` after a force-push. `CONTRIBUTING.md` defined `(t)ACK`
  and `utACK` until commit `fac5ddfc57` ("doc: Rework section on ACK", 2019) replaced them
  with the descriptions above. `crACK` never appeared in `CONTRIBUTING.md`; it is convention only.
  **What matters is the full commit hash plus an honest account of what you did.** You can see this in
  the real threads, e.g. `@maflcko`'s "re-lgtm ACK 3a10d700…" on #33624, or "lightly tested
  ACK" on #36545 (see `../pr-reviews/merged-journeys/`).
- **After a force-push**, `CONTRIBUTING.md` says "reviewers are encouraged to sign off on the force
  push" using `git range-diff` (`doc/productivity.md`, section "Diff the diffs with `git range-diff`").

## Checkpoint

```bash
./lab.sh check 19
```

Runs: ./check_gauntlet.sh, python3 check_practicum.py (Review Club, communication, evidence). Each prints PASS/FAIL with a reason, never the answer. Check your own commit stack separately: `./check_commit_hygiene.sh <your-clone> <base>..<branch>` (read-only).
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answer from memory, then check `solutions/self-check-answers.md`)

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_19=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).

1. What is the difference between `Concept ACK` and `Approach NACK`? Can a person give both on one PR?
2. Why must an ACK name the full commit hash and not just say "ACK"?
3. A PR is force-pushed after your ACK. What command lets you re-review only what changed, and what
   do you write afterwards?
4. Name two kinds of PR that `CONTRIBUTING.md` says new contributors should not open, or that may be closed
   immediately.
5. What does `doc/AI_POLICY.md` say about (a) review comments, (b) answering reviewer questions,
   (c) commit co-authors?
6. You are reviewing a tests-only PR. What single experiment best shows the new test has value?
7. Why should a `refactor:` PR never change test expectations? Where does
   `doc/developer-notes.md` say new coverage should go for a non-trivial refactor?
8. What does a `scripted-diff:` commit contain, and how do you verify it?
9. Which repository do you use for a PR that only touches `src/qt`?
10. Name three places to find real work that is not a trivial drive-by.

## Review lens

This whole stage is the review lens. For any PR, ask:
*What invariant does this protect? Which test would fail if the change were reverted? Did I
run that test and watch it fail? What did I actually do, and does my comment say exactly that?*
Use the per-subsystem matrix in exercise 1 to choose files and invariants to examine.

## Proof-of-work output

- At least **4 public reviews** on open `bitcoin/bitcoin` PRs, each starting with a conceptual
  or `ACK <hash>` line and describing what you tested in your own words.
- At least **2 PR Review Club meetings** attended, with your IRC nick visible in the meeting log.
- **1 reproducible bug report or reproduction comment** on a real issue.
- **1 focused PR** (tests or a real bug fix, not a typo-only change) opened from a signed, hygienic branch.
- **1 written post** (Delving Bitcoin / bitcoindev) or **1 BitDevs Kisumu seminar**, with its public reading list.
- Every link recorded in [`../BTRUST_READINESS_TRACKER.md`](../BTRUST_READINESS_TRACKER.md).

Keep the scale in mind. The Btrust Starter Grant asks for **at least five merged code-based PRs**
(not docs, not "good first issue") and **at least two references** (verified 2026-11-09; see
[`../BTRUST_AND_BITDEVS_PLAYBOOK.md`](../BTRUST_AND_BITDEVS_PLAYBOOK.md); the page showed
applications closed that day). This stage gives you the habits. Reaching that bar takes months of
the weekly review-and-contribute loop after this stage.
