# Exercise 19.1: The Review Method and the PR-Type Matrix

You will use this method on **every** PR, in the Gauntlet and in real reviews.
Save the commands you type in `my-work/19-review-and-contribution-practicum/journal.md`. After your first two PRs, write your
own version of the method in `my-work/19-review-and-contribution-practicum/method-notes.md`.

The short checklist version is in [`../../pr-reviews/REVIEW_METHOD.md`](../../pr-reviews/REVIEW_METHOD.md).

---

## Step 0: Set up a review worktree (once)

**Goal:** a second working directory for PR review, so your `~/bitcoin` checkout
and its build are left alone.

- Read `git show origin/master:doc/productivity.md`, section "Multiple working directories with `git worktrees`".
- Create a worktree somewhere outside both repos, e.g. `~/review/bitcoin`.
- Set up `ccache` (same file, section "Cache compilations with `ccache`").

<details><summary>Hint 1 (concept)</summary>
A worktree shares the object database with your main clone, so fetching a PR once makes it
available in both. It has its own checked-out files and its own build directory.
</details>
<details><summary>Hint 2 (which command)</summary>
<code>git worktree add</code> takes a path and a commit-ish. Read <code>git help worktree</code>.
</details>

## Step 1: Understand the motivation (before you read any code)

Write down in your notes, in your own words:
1. What problem does the PR claim to solve? Is there a linked issue, CI failure, or mailing list thread?
2. Do you agree the problem is real? (This is your **Concept** opinion.)
3. Before you look at the diff, how would *you* have solved it? (You compare this with the PR later, to form your **Approach** opinion.)
4. Which subsystem is it, and which row of the matrix below applies?

Read the PR description with `gh pr view <N> -R bitcoin/bitcoin` (read-only). Do not read the
comments yet if this is a Gauntlet round.

## Step 2: Check out the PR head

**Goal:** a local branch at the PR's exact head commit. Write down the full 40-character hash,
because your ACK will name it.

- Option A: `gh pr checkout` (read `gh pr checkout --help`; mind which remote it uses).
- Option B: fetch `refs/pull/<N>/head` yourself. Read `doc/productivity.md`, sections
  "Fetch and update PRs individually" and "Reference PRs easily with `refspec`s".
- For Gauntlet rounds you check out the **parent of the merge commit** first, then the PR head.
  A merge commit's first parent is the old `master` and its second parent is the PR head.

<details><summary>Hint 1</summary>
The ref GitHub keeps for every PR lives under <code>pull/&lt;N&gt;/head</code> on the remote the PR was opened against.
</details>
<details><summary>Hint 2</summary>
<code>git fetch &lt;remote&gt; &lt;src&gt;:&lt;dst&gt;</code> creates a local branch. For a merge commit <code>M</code>, read <code>git help revisions</code> about <code>M^1</code> and <code>M^2</code>.
</details>

## Step 3: Build only the affected targets

**Goal:** a build of the binaries the PR touches, without building everything on 8 GB of RAM.

- Use `git diff --stat <base>...<head>` to list the touched files, then decide on targets:
  `test_bitcoin` for `src/test/*`, `bitcoind` and `bitcoin-cli` for functional tests,
  `fuzz` for fuzz targets, `bitcoin-qt` only if the PR is GUI.
- Read `doc/productivity.md`, section "Only build what you need", and
  `doc/productivity.md`, section "Disable features when generating the build system".

## Step 4: Run the relevant tests

- Unit tests: read `src/test/README.md` to learn how to run a single suite or a single case.
- Functional tests: read `test/README.md` to learn how to run one test through `test_runner.py`.
- If the PR fixes an intermittent failure, run the test many times, under load, both
  **before** and **after** the change. Write down how often it fails.
- Write down every test you ran and its result. This becomes the "what I tested" part of your review.

## Step 5: Try to break it

This step is what separates a real review from "LGTM".
- **Tests-only PR:** revert or mutate the code the test claims to cover. Does the new test fail?
  (This is Pattern 4 in `../../pr-reviews/merged-journeys/README.md`, from #33624.)
- **Bug-fix PR:** run the new test on the **parent** commit. It should fail there and pass on the PR head.
  If it passes on both, the test does not prove the fix.
- **Refactor:** look for behavior changes. Do edge cases, error paths, and iterator invalidation
  still behave the same?
- **Any PR:** write one extra test case of your own, or one adversarial manual input (RPC, P2P message, CLI argument).
- Never push these experiments anywhere. They stay in your worktree and your notes.

## Step 6: Read commit by commit

- Read `git log --reverse <base>..<head>` and look at each commit on its own.
- Ask: Is each commit atomic? Does it build on its own? Does each commit message explain *why*?
  Are moves and reformatting separated from logic changes? (See `CONTRIBUTING.md`, "Committing Patches".)
- Use `git diff` options to reduce noise, for example moved-code detection and ignoring whitespace. See
  `doc/productivity.md`, section "Reduce mental load with `git diff` options".

## Step 7: After a force-push, use `git range-diff`

- Fetch the new head, then compare the old and new ranges. Read `doc/productivity.md`,
  section "Diff the diffs with `git range-diff`" (it also covers `--creation-factor` and rebases).
- Real example: our local audit of #36553 recorded head `faa3ea61a3`, but the merged head was
  `fa1061481b`. Practice range-diff on that pair: what changed between them?

## Step 8: Write the review (your words only)

Use `templates/review-notes.md` for your **private** notes. The public comment is shorter and
contains only:
- the right first line (Concept ACK / Approach NACK with reasons / `ACK <full hash>` / a question),
- **what you actually did** (built which targets, ran which tests, which mutation, which manual check),
- anything you found, each tied to a `file:line`, with a question if you are not sure,
- nits marked as nits, or left out.

Before you post, make sure you could explain every sentence aloud at BitDevs. If you can't, delete it.

---

## The PR-Type Matrix (how review changes by type)

| PR type (prefix) | First question | Build / run | Break attempt | Watch out for |
| :-- | :-- | :-- | :-- | :-- |
| **Tests-only** (`test:`, `qa:`, `fuzz:`) | Does the test check the behavior it names? | `test_bitcoin` suite or the one functional test; `fuzz` target if fuzz | Mutate the covered code and watch the test fail; for intermittent fixes, reproduce the failure first (e.g. add a delay) | Tests that pass for the wrong reason; added sleeps instead of syncs; slower test runs |
| **Refactor** (`refactor:`, `scripted-diff:`) | Is behavior exactly the same, bugs included? | Whole affected binaries plus their existing tests | Look for changed edge cases: empty containers, iterator invalidation, ownership and lifetime | Mixed move + change commits; for scripted-diff, run the script yourself and compare (`doc/developer-notes.md`, "Scripted diffs", and `test/lint/commit-script-check.sh`) |
| **Policy / mempool** (`policy:`, `mempool:`) | Does this change what gets relayed or mined? Is it a DoS vector? | `bitcoind` plus `mempool_*`, `feature_rbf`, `mempool_truc` etc.; policy unit tests | Craft boundary transactions on regtest; check integer types and overflow | Differences from what other nodes do; fee and size arithmetic; pinning |
| **Consensus-adjacent** (`validation:`, `script`, `sign`, `pow`, `consensus:`) | Could any node reach a different validity result? | `test_bitcoin` (`script_tests`, `transaction_tests`, `pow_tests`…) plus functional tests | Run the test vectors; mutate a comparison operator and check something fails | The highest bar of all ("This includes refactoring of consensus-critical code", `CONTRIBUTING.md`); never ACK lightly |
| **Wallet** (`wallet:`) | Can funds be lost, leaked, or wrongly signed? Is this a backward-compatibility issue? | `bitcoind` plus `wallet_*` tests; wallet unit tests | Old wallet files, odd descriptor ranges, encrypted wallets, migration | Privacy leaks, fee calculation, RPC help text, release notes |
| **P2P / net** (`net:`, `p2p:`) | What can a peer that costs the attacker nothing make us do? | `bitcoind` plus `p2p_*` tests | Send unexpected or out-of-order messages with the test framework's `P2PInterface` | Locking (`cs_main`, `m_peer_mutex`), timeouts, eviction, memory bounds |
| **RPC / tools** (`rpc:`, `cli:`, `bitcoin-tx` …) | Is the API change compatible? Is the help text updated? | `bitcoind`, `bitcoin-cli`, `bitcoin-tx`; `rpc_*` or `tool_*` tests | Malformed arguments, boundaries, empty strings | Release notes for user-visible changes; the deprecation process (`doc/developer-notes.md`) |
| **GUI** (`qt:`, `gui:`; opened in `bitcoin-core/gui`) | Does the user see the right thing? | `bitcoin-qt` only if you can afford the build (heavy on 8 GB) | Click through the changed screen; take before/after screenshots | Changes to `src/interfaces` belong in the node repo (`CONTRIBUTING.md`) |
| **Build / CI** (`build:`, `cmake:`, `ci:`, `guix:`) | Does it build on all the platforms it claims to? | Configure from a clean build dir; for Guix, read `contrib/guix/README.md` | Try both with and without the option | Platform differences (macOS is one: you can test that!) |
| **Docs** (`doc:`) | Is it accurate against the code? | none | `grep` every claim against the source | Trivial-only changes may be closed (`CONTRIBUTING.md`, "Refactoring" section's last paragraph) |

**Done when:** you have used this method on Gauntlet rounds G01 and G02, and your
`method-notes.md` says, in your own words, what you will do differently next time.
