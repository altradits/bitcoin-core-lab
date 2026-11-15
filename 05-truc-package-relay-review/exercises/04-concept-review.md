# Stage 05 Worksheet 4: Concept/approach review of PR #28948 (private notes)

**Output:** `my-work/05-truc-package-relay-review/review-28948.md` (private; do not post).
**Checker:** `./check_review_notes.sh` (checks structure and that you cite real files, not content quality)

PR #28948 "v3 transaction policy for anti-pinning" was merged (`git log --merges --grep="#28948"
master` in your Core checkout). Reviewing a merged PR is safe practice: you can compare your view
with what actually happened.

## Steps
1. Read the PR description and the linked discussion (Delving Bitcoin / mailing list threads
   linked from it). Read the code as it was merged: `git show 7143d43884:src/policy/v3_policy.h`
   and the new test `test/functional/mempool_accept_v3.py` at that commit. Both were later renamed
   when "v3" became "TRUC" (`truc_policy.{h,cpp}`, `mempool_truc.py`; see PR #30272).
2. Check out the merge commit's first parent and the PR head in a worktree; list the commits with
   `git log --oneline <base>..<head>`.
3. Write `review-28948.md` with **these headings exactly**:
   - `## Problem` — the pinning problem in your own words (≥ 80 words).
   - `## Concept` — your Concept ACK/NACK and why.
   - `## Alternatives` — at least two alternatives that were discussed, and why this approach won.
   - `## Approach` — your Approach ACK/NACK.
   - `## Files I read` — at least 4 real paths (`src/...` or `test/...`).
   - `## Tests I ran` — exact commands and results (e.g. `mempool_truc.py`).
   - `## Questions` — at least 2 questions you would have asked the author.
4. Only afterwards, read the real review thread on GitHub and add `## Compared with real review`:
   what did reviewers raise that you missed?

Integrity: these notes are yours. Do not paste reviewer comments as your own text; quote them
with a link if you need to.
