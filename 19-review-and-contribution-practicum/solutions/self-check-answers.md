# Stage 19 self-check answers

Sources: `CONTRIBUTING.md`, `doc/developer-notes.md`, `doc/productivity.md`, `doc/AI_POLICY.md`
(all read from `/Users/mac/bitcoin` `origin/master` `ab7e668cc6`; AI_POLICY is identical on local `master`).

1. **Concept ACK vs Approach NACK.** Concept ACK: "I agree with the general goal of this pull request".
   Approach NACK: you agree with the goal (so it implies Concept ACK) but "do not agree with the
   approach of this change". Yes, the same person can hold both views; "Approach NACK" already includes the Concept ACK.
   Any NACK needs a rationale, or "may be disregarded".
2. **Full hash in an ACK.** An ACK is a statement about one exact tree. PRs get force-pushed. A hash
   lets maintainers (and the merge script, which lists "ACKs for top commit") see which version you
   reviewed, and whether your ACK is stale. `CONTRIBUTING.md`: "A review begins with `ACK BRANCH_COMMIT`,
   where `BRANCH_COMMIT` is the top of the PR branch, followed by a description of how the reviewer did the review."
3. **After a force-push:** `git range-diff` between the old range and the new range (with the
   merge-base if it was a rebase). See `doc/productivity.md`, "Diff the diffs with `git range-diff`". Then
   post a new ACK naming the **new** head hash and saying what you checked (e.g. "range-diff shows only the
   rebase plus the rename suggested above"). `CONTRIBUTING.md`: reviewers "are encouraged to sign off on
   the force push".
4. **PRs new contributors shouldn't open / that get closed:** refactoring PRs ("should not be made by new
   contributors"); "Trivial pull requests or pull requests that refactor the code with no clear benefits
   may be immediately closed". PRs whose author clearly doesn't understand or hasn't tested the change
   "may be closed immediately". PRs "opened or driven by autonomous agents" may be "closed without notice" (AI policy).
5. **AI policy:** (a) "AI should not be used to generate comments when communicating with maintainers and
   other contributors"; comments "are expected to be written by humans". (b) "Do not copy responses from
   the AI when replying to questions from reviewers." (c) "Do not include agents as authors or co-authors
   of your commits". Any AI context you quote must be disclosed, with your own commentary.
6. **Tests-only PR experiment:** mutate (or revert) the production code the test claims to cover and
   confirm the new test **fails**, then restore it. Example: #33624 reviewers changed the
   `SCRIPT_VERIFY_P2SH` check to `true` and confirmed the new assert caught it. For an intermittent-failure
   fix, reproduce the failure on the parent first (e.g. inject a delay).
7. **Refactor and test expectations:** a refactor must not change behaviour ("bugs must be preserved as
   is"), so needing to change an expectation is evidence the behaviour changed. `doc/developer-notes.md`
   "Commit Structure for Tests": for a non-trivial refactor without existing coverage, "first add that
   coverage in a separate test commit. The refactor commit should not need to update test expectations."
8. **scripted-diff:** the commit message starts with `scripted-diff:` and contains a bash script between
   `-BEGIN VERIFY SCRIPT-` and `-END VERIFY SCRIPT-`. Verify by re-running the script on the parent and
   checking the result is identical to the commit, or with `test/lint/commit-script-check.sh <range>`. Then
   also review the script's *intent* (is it too broad?).
9. **GUI-only (`src/qt`) PR:** the `bitcoin-core/gui` repository. Exceptions: global refactors, GUI-related
   build-system changes, and `src/interfaces` changes go to `bitcoin/bitcoin`.
10. **Real work sources (any three):** reproducing open bug issues (especially on macOS/arm64);
    intermittent CI failure issues; coverage or mutation gaps; follow-ups left in review threads;
    `Up for grabs` label; PR Review Club PRs; TODOs in code you have reviewed (after checking `git blame`).
