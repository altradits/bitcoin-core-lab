# Review Method: one-page checklist

The full worksheet is in [`../19-review-and-contribution-practicum/exercises/01-review-method.md`](../19-review-and-contribution-practicum/exercises/01-review-method.md).
It explains each step and has the PR-type matrix. Sources: `CONTRIBUTING.md` ("Peer Review"),
`doc/productivity.md` ("Reviewing code"), and `doc/AI_POLICY.md` in `bitcoin/bitcoin`.

**Before you start**
- [ ] I am using a separate review worktree, not my main checkout.
- [ ] I have read the PR description and linked issues, and I can state the motivation in one sentence of my own.
- [ ] I wrote down how *I* would solve it before reading the diff.
- [ ] I know which matrix row applies (tests / refactor / policy / consensus-adjacent / wallet / P2P / RPC / GUI / build).

**Hands on**
- [ ] I checked out the exact PR head and wrote down the full 40-char hash.
- [ ] I built only the targets the PR affects (low `-j` on 8 GB; `ccache` on).
- [ ] I ran the relevant unit and functional tests, on the **parent** and on the **head**.
- [ ] I tried to break it: a mutation the new test should catch, a reproduction on the parent, or an adversarial input.
- [ ] I read every commit on its own. Each one is atomic and builds, and no move/format is mixed with logic.
- [ ] After any force-push: `git range-diff` old vs new, and I can say exactly what changed.

**Writing (your words only)**
- [ ] The first line is honest: `Concept ACK`, `Approach NACK` + reason, `ACK <full hash>`, or a question.
- [ ] I said **what I actually did** (built, ran, mutated, manually tested). I did not claim testing I didn't do.
- [ ] Each finding has a `file:line` and is phrased as a question if I'm unsure.
- [ ] Nits are labelled as nits, or left out.
- [ ] No AI-written text. I could defend every sentence aloud at BitDevs Kisumu.
- [ ] Afterwards: I recorded the link in [`../BTRUST_READINESS_TRACKER.md`](../BTRUST_READINESS_TRACKER.md) and my commands in `my-work/19-review-and-contribution-practicum/journal.md`.

**Vocabulary (from `CONTRIBUTING.md`)**: `Concept (N)ACK`, `Approach (N)ACK`; a code review "begins
with `ACK BRANCH_COMMIT` … followed by a description of how the reviewer did the review". A NACK needs a rationale.
"nit" = "a trivial, often non-blocking issue". `tACK`/`utACK`/`crACK` are informal shorthand
(`utACK` and `(t)ACK` were defined in `CONTRIBUTING.md` until 2019; `crACK` never was). The words matter less
than an accurate description of what you did.
