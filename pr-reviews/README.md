# pr-reviews/: index

Study material about real `bitcoin/bitcoin` pull requests, and the place where your own
review practice is organised. **Start with [`REVIEW_METHOD.md`](./REVIEW_METHOD.md).**

## What is here

| Path | What it is | How to use it |
| :-- | :-- | :-- |
| [`REVIEW_METHOD.md`](./REVIEW_METHOD.md) | One-page review checklist | Keep it open during every review |
| [`merged-journeys/`](./merged-journeys/README.md) | 8 merged PRs with their full review threads (#32313, #33624, #33630, #35724, #36439, #36447, #36469, #36545) | Read how real reviewers found problems and wrote ACKs. Study the patterns, but **do not copy wording** |
| `PR-*-AUDIT.md` (10 files) | Auto-generated "Guardian" audit dumps: description, commit list, diff, a pre-ticked checklist | Use them **only** as offline copies of the diff. See the caveats below |
| [`../19-review-and-contribution-practicum/`](../19-review-and-contribution-practicum/README.md) | Stage 19: review method, Review Gauntlet, Review Club, contribution craft | Where the actual training happens |

### Caveats on the `PR-*-AUDIT.md` files (checked 2026-11-09)

- The "6-Point Audit Checklist" boxes are **pre-ticked by a script**. They don't record any review you did.
- Each file ends with a "Formal Maintainer Sign-Off" block containing `Tested ACK <hash>`. **Never post
  that line.** It was generated, not tested. An ACK is only valid if you did the review it describes, in your own words
  (`doc/AI_POLICY.md`; `CONTRIBUTING.md` "Code Review").
- Risk rings are assigned by a script and can be wrong. #36553 (a test-only change to `wallet_conflicts.py`),
  #36555 (RPC) and #36550 (crypto destructor cleanup) are all labelled "Ring 0 — CRITICAL CONSENSUS".
- Some status lines are out of date: #36553 is listed as unmerged but was **merged 2026-10-20**
  (merge `020fcb281e`, final head `fa1061481b`, not the audited `faa3ea61a3`); #36550 was **closed
  without merge**; #36555 is still open.
- The three open-PR audits (#36550, #36553, #36555) list hundreds of unrelated commits and diff lines
  (the range was taken against a stale base). Recompute the PR's real range yourself from its merge-base.

## Where your own reviews go

```
my-work/19/                      # private (you choose what to publish)
  journal.md                     # every command you typed
  method-notes.md                # your own version of the method
  gauntlet/Gxx-<PR>-blind.md     # sealed blind reviews of merged PRs
  gauntlet/Gxx-<PR>-compare.md   # self-graded comparison with the real thread
  reviews/PR-<N>.md              # private notes for live PRs (template: review-notes.md)
  review-club/<PR>-answers.md    # Review Club prep and post-log comparison
```

Templates with blanks only: [`../19-review-and-contribution-practicum/exercises/templates/`](../19-review-and-contribution-practicum/exercises/templates/).

**Private vs public**

- `my-work/` is your notebook. Nothing in it is posted automatically.
- **Public** means a comment *you* type on GitHub, IRC, or Delving, based on testing *you* did.
  After posting, record the link in [`../BTRUST_READINESS_TRACKER.md`](../BTRUST_READINESS_TRACKER.md).
- If you want a public portfolio of Gauntlet reviews, publish them from your own repo or gist.
  Label them clearly as practice on already-merged PRs.

## Adding a new study dossier here

If you add a new `merged-journeys/PR-<N>-JOURNEY.md`, check the number, title and merge with
`gh pr view <N> -R bitcoin/bitcoin --json title,state,mergedAt` and note the date. Quote reviewers
only from the actual thread, and add your own analysis in a section clearly marked as yours.
