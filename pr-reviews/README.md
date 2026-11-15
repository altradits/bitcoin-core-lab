# pr-reviews/: index

Study material about real `bitcoin/bitcoin` pull requests, and the place where your own
review practice is organised. **Start with [`REVIEW_METHOD.md`](./REVIEW_METHOD.md).**

## What is here

| Path | What it is | How to use it |
| :-- | :-- | :-- |
| [`REVIEW_METHOD.md`](./REVIEW_METHOD.md) | One-page review checklist | Keep it open during every review |
| [`merged-journeys/`](./merged-journeys/README.md) | 8 merged PRs with their full review threads (#32313, #33624, #33630, #35724, #36439, #36447, #36469, #36545) | Read how real reviewers found problems and wrote ACKs. Study the patterns, but **do not copy wording** |
| `PR-*-AUDIT.md` (10 files) | Study files: PR description, commit list, diff, and a **blank** review checklist and conclusion for you to fill in. #36550, #36553 and #36555 were checked by hand | Offline copies of a PR to practise on. Read the caveats below first |
| [`../19-review-and-contribution-practicum/`](../19-review-and-contribution-practicum/README.md) | Stage 19: review method, Review Gauntlet, Review Club, contribution craft | Where the actual training happens |

### Caveats on the `PR-*-AUDIT.md` files (checked 2026-11-15)

- The review checklist (section 5) and your conclusion (section 6) are **blank** in every file. Nothing
  in them records a review anyone did. An ACK is only valid if you did the review it describes, in your
  own words (`doc/AI_POLICY.md`; `CONTRIBUTING.md` "Code Review").
- #36550, #36553 and #36555 were rewritten by hand: state, head commit, real commit count and risk are
  checked against GitHub (date in each file). #36550 was **closed without merge**; #36553 was **merged
  2026-10-20**; #36555 was still open. Open PRs change, so recheck before citing.
- The other audits still carry a script-assigned "risk ring" that can be wrong; decide the risk yourself.
- Audits generated with `./lab.sh pr-audit <n>` take the diff from your local branch. Recompute the PR's
  real range from its merge-base if the commit list looks too long.

## Where your own reviews go

```
my-work/19-review-and-contribution-practicum/                      # private (you choose what to publish)
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
