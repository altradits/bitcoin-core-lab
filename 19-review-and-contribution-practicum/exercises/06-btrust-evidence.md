# Exercise 19.6: Turning Work into Btrust Evidence

**Requirements:** use the verified ones in [`../../BTRUST_AND_BITDEVS_PLAYBOOK.md`](../../BTRUST_AND_BITDEVS_PLAYBOOK.md)
(checked 2026-11-09). In short: the **Starter Grant** asks for at least **five merged code-based PRs**
(excluding docs, not labelled "good first issue") and at least **two references**, and the page
showed "Applications closed" that day. **Btrust Builders** is for Africa; btrust.tech asks for 3+ years of production
experience and 20+ hours/week with a code challenge, while builders.btrust.tech asks for one year and
offers free pathways, the BOSS challenge and a Fellowship (playbook Part 2A, checked 2026-11-15). btrust.tech/grants
says applicants outside the listed regions are considered "contingent on their Proof of Work".
Re-check the live pages before applying. Anything the playbook marks `UNVERIFIED` stays unverified.

The tracker is [`../../BTRUST_READINESS_TRACKER.md`](../../BTRUST_READINESS_TRACKER.md): reviews go in section 3, your PRs in section 4, and so on. Add one row per public item. (C-BTRUST-2, C-BTRUST-3)

## Which activity produces which link

| Activity (exercise) | Public link to record | What makes it count |
| :-- | :-- | :-- |
| Live PR review (19.1) | URL of your review comment on `github.com/bitcoin/bitcoin/pull/N` | Full commit hash and what you tested, in your words |
| Re-review after force-push (19.1 step 7) | URL of your re-ACK comment | Shows you followed the PR over time |
| Review Club attendance (19.3) | `bitcoincore.reviews/<N>` meeting log, plus your nick | Substantive answers in the log |
| Bug reproduction (19.5A) | Issue comment URL | New information: platform, smaller repro, failure rate |
| Your PR (19.4) | PR URL (merged or open), plus your replies to reviewers | Real value, not trivial; you answered every comment |
| Delving / bitcoindev post (19.5B) | Thread URL | Your own data or a precise question |
| BitDevs Kisumu seminar (19.5C) | Public reading-list URL | Your topic and questions are listed |
| Gauntlet results (19.2) | *Optional*: a public repo or gist of your blind reviews and scores | Shows your method, and that you score yourself honestly |

## Rules for evidence

- Record only links that exist. Never record planned or draft work as done.
- Do not count Gauntlet blind reviews as "reviews". They are training. Upstream reviews on
  **open** PRs are what show up on GitHub.
- Quality over count. Four reviews that each found something or tested something real are worth more
  than twenty "ACK, lgtm" comments, and maintainers notice the difference (`CONTRIBUTING.md`:
  reviewers who "have demonstrated a deeper commitment and understanding of the project over time
  … may naturally have more weight").
- Write your monthly progress summary yourself from the tracker rows (C-COMMS-3).
- **References (C-BTRUST-3)** come from repeated, useful review of the same contributors'
  PRs in one area, and from fixing things they care about. You never ask for one after a
  single comment.

**Done when:** every proof-of-work output listed in the stage README has a row with a working link.

**Checker:** `python3 check_practicum.py evidence` checks that every row you filled in is well-formed: a real
link, an `ACK` that names its commit, what you tested, a merged date for merged PRs. Add `--online` (needs
`gh auth login`; set `GITHUB_USER` to your handle) to have GitHub confirm each PR's status and author.
It also prints your progress against the Starter Grant numbers (5 merged code PRs, 2 references).
