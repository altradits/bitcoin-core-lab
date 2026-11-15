# Exercise 19.4: Contribution Craft

`CONTRIBUTING.md` says "In-depth reviewing and testing are the bottleneck of the project, and are
the most effective way anyone can start to contribute." Review first; code PRs come out of what
review teaches you. This exercise prepares you to open a PR that is worth a maintainer's time.

> **Do not touch `/Users/mac/bitcoin` for this exercise.** Fork `bitcoin/bitcoin` on GitHub
> yourself, clone your fork (or add it as a remote to a *separate* worktree), and do every
> practice commit on your own branch. Nothing here is pushed until you choose to.

---

## Part A: Finding work that matters (C-CONTRIB-1)

Verified on 2026-11-09 with `gh label list -R bitcoin/bitcoin`: there is **no
"good first issue" label** in `bitcoin/bitcoin` right now. Labels that do exist and are useful:
`Up for grabs`, `Questions and Help`, `Tests`, `CI failed`, `Waiting for author`,
`Needs Conceptual Review`, `Insufficient Review`, `Review club`, `Brainstorming`. The
PR Review Club homepage also links a "Good First Issues" list.

Sources of real work. For each one, write 2 candidates in `my-work/19/work-candidates.md`:
1. **Issues to reproduce.** Find an open bug issue with no reproduction from a second person.
   Reproduce it on your Mac (macOS/arm64 is a platform people need reports from). Use
   `templates/bug-reproduction.md`. A good reproduction comment is valuable on its own.
2. **Intermittent test failures.** Search open issues for "intermittent" (on 2026-11-09 there were
   several, e.g. #36755 and #36099). Can you reproduce the failure by running the test in a loop
   under load? Read the merged fixes in `../../pr-reviews/merged-journeys/` (#36447, #36545) first.
3. **Coverage gaps.** Build a coverage report (`doc/developer-notes.md`, section "Compiling for test
   coverage"; heavy on 8 GB, so cover one test suite at a time) and look for untested branches in
   code you already understand. Mutation testing finds even better gaps: PR #33624's description links a
   corecheck.dev mutation page listing surviving mutants, and Gauntlet G01 (#36231) is made of exactly this kind of PR.
4. **Follow-ups in review threads.** Reviewers often write "could be done in a follow-up". Search
   merged PRs in an area you know.
5. **TODOs and FIXMEs** in code you have reviewed. Check `git blame` and the linked discussion
   first; many TODOs are deliberate.

**Avoid trivial drive-by PRs.** `CONTRIBUTING.md`: "Trivial pull requests or pull requests that
refactor the code with no clear benefits may be immediately closed by the maintainers to reduce
unnecessary workload on reviewing." It also says refactoring PRs "should not be made by new
contributors". A typo-only or whitespace PR costs reviewer time and builds no reputation.

## Part B: Commit hygiene (C-CONTRIB-2)

Rules from `CONTRIBUTING.md` ("Committing Patches", "Creating the Pull Request"):
- Atomic commits; "do not mix any formatting fixes or code moves with actual code changes".
- Each commit "builds successfully on its own without warnings, errors, regressions, or test failures".
- Subject line "(50 chars max)", a blank line, then a body explaining the *why*.
- "Commit messages should never contain any `@` mentions". The same goes for the PR description.
- Area prefixes for the PR title: `consensus`, `doc`, `qt`/`gui`, `log`, `mining`, `net`/`p2p`,
  `refactor`, `rpc`/`rest`/`zmq`, `contrib`/`cli`, `test`/`qa`/`ci`, `util`/`lib`, `wallet`,
  `build`, `guix`. In practice commit subjects use the same prefixes. The most common prefixes in the 2,777
  non-merge commits on `master` since 2026-01-01 were `test` (554), `refactor` (187), `doc` (187),
  `wallet` (156), `ci` (156), `fuzz` (118), `rpc` (81). There are also `scripted-diff:` commits
  (`doc/developer-notes.md`, "Scripted diffs").
- Test placement: read `doc/developer-notes.md`, section "Commit Structure for Tests" (on `origin/master`).
- **No AI co-author trailers, ever (C-CONTRIB-4).** `doc/AI_POLICY.md`
  (`git -C /Users/mac/bitcoin show master:doc/AI_POLICY.md`): "Do not include agents as authors or
  co-authors of your commits". Some AI coding tools add a `Co-Authored-By:` line automatically.
  Check every message with `git log --format=%B` before you push, and turn that setting off in
  any tool you use with your Bitcoin Core clone. `check_commit_hygiene.sh` fails a commit that has one.

## Part C: Signing (C-GIT-7)

Sign every commit you push. Choose **one**:
- GPG: create a key, tell git which key to use, and turn on signing for commits.
- SSH: set git's signature format to SSH and point it at your SSH public key.
Add the public key to your GitHub account as a *signing* key, so GitHub shows "Verified".
Check locally that `git log --show-signature` (or the `%G?` format placeholder) reports a good signature.

<details><summary>Hint 1</summary>Read <code>git help config</code> for <code>user.signingKey</code>, <code>commit.gpgSign</code>, <code>gpg.format</code>, and <code>gpg.ssh.allowedSignersFile</code>.</details>
<details><summary>Hint 2</summary>For SSH verification to show "good" locally, git needs an allowed-signers file mapping your email to your public key.</details>

## Part D: Dry-run commit stack on your own branch (C-CONTRIB-2, C-GIT-3, C-GIT-4)

In **your fork's clone**, on a new branch from current `master`:
1. Pick one candidate from Part A that is small and real (ideally a test that kills a surviving
   mutant, or a test for a reproduced bug).
2. Make **2–3 commits**: e.g. (1) a test that shows current behavior, (2) the change,
   (3) docs or a release note if the change is user-visible. Each must build and pass on its own.
3. Deliberately add a fixup commit, then **squash it** with an interactive rebase (or `--fixup` plus
   `--autosquash`). `CONTRIBUTING.md`, "Squashing Commits", explains the workflow.
4. Rebase onto a newer `master` (`CONTRIBUTING.md`, "Rebasing Changes"), then use `git range-diff`
   to prove to yourself that only the base changed.
5. Run:
   `bash 19-review-and-contribution-practicum/check_commit_hygiene.sh <path-to-your-clone> <base>..<your-branch>`
   Fix whatever it reports, by rewriting your commits yourself.
6. Write a PR description draft in `my-work/19/pr-draft.md`: *what* and, more importantly, *why*;
   which tests cover it; how a reviewer can test it manually; no `@` mentions.

Push and open the PR **only** if you would defend every line at BitDevs. Opening it is your
decision, not this lab's.

## Part E: Responding to review (C-CONTRIB-3)

From `CONTRIBUTING.md`, "Address Feedback": "You are expected to reply to any review comments before
your pull request is merged. You may update the code or reject the feedback if you do not agree
with it, but you should express so in a reply."

Practice: choose 5 inline review comments from the merged journeys (e.g. #36447, #35724). For each,
write in your private notes how *you* would reply if you were the author: accept, push back with a
reason, or ask a question. Then compare with what the real author did. Habits to keep:
- Reply to every comment, even with "Done" or "Fixed in <hash>".
- After a force-push, write one comment summarizing what changed, so reviewers can `range-diff`.
- Never get defensive. "Thanks, good catch" is a normal sentence in this project.
- Never paste an AI-written reply (`doc/AI_POLICY.md`).
- Be patient. See `CONTRIBUTING.md`, "Finding Reviewers", and review others' PRs while you wait.

## Part F: CI

Learn to read a CI failure on your own PR before asking: find which job failed, open the log,
and work out whether it is your change or a known intermittent failure (search open issues for the test name).
The `ci/` directory and `.github/workflows/` define the jobs. Read them, don't guess.

**Done when:** `check_commit_hygiene.sh` passes on your dry-run branch, your Part E replies are
written, and `work-candidates.md` has at least 6 real, linked candidates.
