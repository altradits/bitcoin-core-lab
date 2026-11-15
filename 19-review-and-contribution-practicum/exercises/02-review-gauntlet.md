# Exercise 19.2: The Review Gauntlet (10 merged PRs, reviewed blind)

**Idea:** You review a PR that has **already been merged** as if it were still open. You write
your review *before* you look at what real reviewers said. Then you open the real thread and
score yourself. These PRs are closed, so nothing you write here goes upstream. The point is to
calibrate your judgment against experienced reviewers.

Every PR below was checked on 2026-11-09 with
`gh pr view N -R bitcoin/bitcoin --json title,state,mergedAt` (state `MERGED`) and against the
merge commit on `origin/master` in `~/bitcoin`.

> The merge commits below are on `origin/master` (not on your older local `master`). Run
> `git fetch origin` in `~/bitcoin` first; your review worktree shares those objects.
> GUI round G10 is merged into the same monotree, so its merge commit is there too.

## Rules of the round

1. **Stay blind.** Until your blind file is sealed, do **not** open the PR's GitHub
   conversation, and do not read the full merge commit message: its body lists the
   "ACKs for top commit". You *may* read the PR description (`gh pr view N` without `--comments`).
2. **Start at the parent.** Check out the merge commit's **first parent** (the old `master`) in your
   review worktree, build, and run the relevant tests there. Then move to the PR head (the merge commit's
   **second parent**) and repeat. You work out both hashes yourself; the checker verifies them.
3. **Write the blind review** in `my-work/19-review-and-contribution-practicum/gauntlet/Gxx-<PR>-blind.md`, using
   `templates/gauntlet-blind.md`. It must include what you ran and your break attempt.
4. **Seal it.** Compute the SHA-256 of the blind file (`shasum -a 256`; read `man shasum`) and
   write the hash into the compare file. After sealing, do not edit the blind file. The checker
   recomputes the hash.
5. **Compare.** Now read the real thread (`gh pr view N -R bitcoin/bitcoin --comments`, and
   the inline review comments on the GitHub "Files changed" tab). Answer the rubric in
   `my-work/19-review-and-contribution-practicum/gauntlet/Gxx-<PR>-compare.md` using `templates/gauntlet-compare.md`.
6. **Score yourself** 0–2 on each rubric line. Be honest. Nobody else sees this unless you
   choose to publish it.
7. Run `bash 19-review-and-contribution-practicum/check_gauntlet.sh Gxx`.

> No answers or model reviews exist for these rounds, by design. The GitHub thread is the
> answer key, and it is written by real people, not by this lab.

---

## The 10 rounds (ordered roughly from easiest to hardest; G01–G02 can start around week 4)

| Round | PR | Title (verbatim) | Subsystem / matrix row | Merge commit on `master` | Commits | Merged (UTC) |
| :-: | :-: | :-- | :-- | :-- | :-: | :-- |
| G01 | [#36231](https://github.com/bitcoin/bitcoin/pull/36231) | test: add pow tests covering live mutants | Tests-only (unit), consensus-adjacent code under test | `368c138231` | 4 | 2026-10-19 |
| G02 | [#36703](https://github.com/bitcoin/bitcoin/pull/36703) | test: Sync blocks in test_witness_block in p2p_segwit.py | Tests-only (functional, intermittent) | `07efc59292` | 1 | 2026-10-30 |
| G03 | [#36535](https://github.com/bitcoin/bitcoin/pull/36535) | policy: sum package weight in int64_t | Policy / mempool | `c50817fe2d` | 1 | 2026-10-16 |
| G04 | [#36682](https://github.com/bitcoin/bitcoin/pull/36682) | refactor: Use std::erase and std::erase_if | Refactor (many subsystems) | `363d9e9d38` | 2 | 2026-10-29 |
| G05 | [#36397](https://github.com/bitcoin/bitcoin/pull/36397) | scripted-diff: [wallet] Remove trailing newlines from one-line log messages | Scripted-diff + util + wallet logging | `6799119cef` | 5 | 2026-10-20 |
| G06 | [#36368](https://github.com/bitcoin/bitcoin/pull/36368) | bitcoin-tx: reject in and outscript arguments with too many separators | RPC / tools (`bitcoin-tx`) | `fe52f520de` | 1 | 2026-10-19 |
| G07 | [#35989](https://github.com/bitcoin/bitcoin/pull/35989) | wallet: fix crash on importdescriptors with a range ending at 2^31-1 | Wallet + descriptors | `acdb326934` | 5 | 2026-10-08 |
| G08 | [#35984](https://github.com/bitcoin/bitcoin/pull/35984) | sign: skip signing SIGHASH_SINGLE inputs with no corresponding output | Consensus-adjacent (script signing, PSBT) | `e19f83e944` | 1 | 2026-09-25 |
| G09 | [#36080](https://github.com/bitcoin/bitcoin/pull/36080) | p2p: Suspend ping timeout while downloading blocks from a peer | P2P | `c7835db15a` | 3 | 2026-10-05 |
| G10 | [bitcoin-core/gui#970](https://github.com/bitcoin-core/gui/pull/970) | Remove legacy BIP70 merchant name from tx details window | GUI (merged into the monotree as "Merge bitcoin-core/gui#970") | `43a33e513c` | 1 | 2026-10-30 |

Optional extra round (Build/CI): [#36275](https://github.com/bitcoin/bitcoin/pull/36275)
"build: enable `-Wunused-const-variable`", merge commit `3b9768a07a`, merged 2026-09-29.

For each round, the **files touched** are a fact you should find yourself with `git diff --stat`.
Don't look them up here.

---

## Round-specific focus prompts (they point you at a question, not an answer)

- **G01 #36231:** Each commit claims to cover a "mutant". For each commit, find the line in
  `src/pow.cpp` it targets, mutate it yourself, and record which new test fails. Is there a
  mutant on the same lines that **still survives**?
- **G02 #36703:** The diff is large for a one-line idea. Work out why. Can you make the original
  race happen on the parent commit? What sync primitive does the framework offer, and why
  that one?
- **G03 #36535:** One line changed. What type was used before, what is the largest value it
  could hold, and what is the largest value a package could reach? Is a test needed?
  Should there be one?
- **G04 #36682:** For every call site, prove the old and new code behave the same. Are there
  call sites where iterator order, return values, or container type make that unclear?
- **G05 #36397:** Re-run the scripted-diff yourself and confirm the result is identical. Then judge
  the non-scripted commits on their own. Is each commit atomic?
- **G06 #36368:** Write down 5 malformed `bitcoin-tx` arguments of your own *before* reading the
  new test vectors. How many of yours do the vectors cover?
- **G07 #35989:** Reproduce the crash on the parent commit (functional test or manual RPC on
  regtest). Then map each of the 5 commits to the problem it fixes.
- **G08 #35984:** Explain in your own words what `SIGHASH_SINGLE` means when an input has no
  output at the same index. Why might *skipping* signing be safer than signing? Which test proves it?
- **G09 #36080:** The test is about 200 lines. Before reading it, write the test plan *you* would
  have written. Then think about the attacker: can a peer abuse the suspended timeout?
- **G10 gui#970:** What does a user lose or gain? Is the release note accurate? If you can't
  build `bitcoin-qt` on 8 GB, say so honestly in your review ("not tested, code review only").

---

## Comparison rubric (copy into each `-compare.md` and answer; score 0/1/2)

- **R1 Concept:** Did your Concept opinion match the reviewers'? If not, who was right, and why?
- **R2 Approach:** Did anyone suggest a different approach? Had you thought of it?
- **R3 Findings:** List every substantive finding in the thread (bugs, missing cases, renames).
  Which did you find on your own? Which did you miss, and **which step of the method would have caught it**?
- **R4 False alarms:** Did you raise anything that was wrong or did not matter? What misled you?
- **R5 Testing depth:** Compare what you tested with what the reviewers said they tested. Did anyone
  run a mutation, a reproduction, or a manual test you did not?
- **R6 Commit structure:** Did reviewers ask for commits to be split, squashed, or reordered? Did you notice the need?
- **R7 Force-pushes:** How many times was the PR force-pushed after the first review? Pick one
  push and `range-diff` it. Does your summary of the change match the author's?
- **R8 Communication:** Copy (into your private notes) **one** review comment you admire. Write
  in your own words why it worked. Do not reuse its wording in your future reviews.
- **R9 Next time:** One concrete change to your method (also add it to `method-notes.md`).

**Scoring:** 14–18 strong; 9–13 solid, but repeat the method step behind your misses; ≤8 redo a
similar PR from the same matrix row before moving on.

**Done when:** `check_gauntlet.sh` passes for G01–G10 (or at least 8 rounds, including G01,
G02, one wallet round, and one P2P or consensus-adjacent round).
