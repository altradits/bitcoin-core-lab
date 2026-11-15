# Exercise 19.5: Technical Communication

Bitcoin development is done in writing: issues, review comments, Delving Bitcoin threads,
the bitcoindev mailing list, and IRC. Clear writing earns reviewers and references.

Ground rule: every sentence you publish is yours. You may ask someone to proofread your
text, but the ideas and wording must be your own (`doc/AI_POLICY.md`).

---

## Part A: A bug reproduction write-up (C-COMMS-3)

Use `templates/bug-reproduction.md`. Rules:
- Name the exact commit, OS/arch, and build options. "Latest master" is not a version.
- Steps must be **minimal**. Remove every step that doesn't matter, then try again from a clean datadir.
- Paste **real** log lines (trimmed), not a paraphrase.
- Give a failure rate (n/m) for intermittent issues.
- Say what you ruled out.
- Practice first on a closed issue that has a known fix: reproduce it at the parent of the fix
  commit, and confirm it is gone at the fix. Then do one on an open issue.

**Output:** `my-work/19-review-and-contribution-practicum/comms/repro-<issue>.md`. Post it on the issue only if it adds new information
(a new platform, a smaller reproduction, a failure rate). A "+1, same here" comment adds nothing.

## Part B: A Delving Bitcoin or bitcoindev post (C-COMMS-3, C-COMMS-4)

`CONTRIBUTING.md` says the mailing list "should be used to discuss complicated or controversial
consensus or P2P protocol changes before working on a patch set". Delving Bitcoin
(delvingbitcoin.org) is the forum where much protocol research is discussed today. Its posting
rules are not checked in this lab (`UNVERIFIED`), so read its FAQ and a few weeks of threads before posting.

1. Read 10 recent threads in one category. Notice what kinds of post get replies: posts with
   data, code, or a precise question.
2. Pick a topic where you have **your own data**: e.g. measurements from your pruned M1 node,
   fee data you collected, or a regtest experiment around a policy you reviewed in the Gauntlet.
3. Fill in `templates/post-outline.md`, then write the post yourself in `my-work/19-review-and-contribution-practicum/comms/post-draft.md`.
4. Wait a day, reread it, and cut 30%. Check every factual claim against code or a link.
5. Ask a BitDevs Kisumu co-organizer to read it for clarity (they review it; they don't rewrite it).
6. Post it when you are ready. A thoughtful **reply** to an existing thread counts too.

## Part C: Presenting a PR at the BitDevs Kisumu Socratic Seminar (C-COMMS-2)

From `../../BTRUST_AND_BITDEVS_PLAYBOOK.md`: the Socratic format means a short introduction followed by
open questions to the room. (Chatham House and no-recording are common BitDevs practice. As a *Btrust* rule they are `UNVERIFIED`, so agree on them with your co-organizers.)

1. Choose a PR you reviewed in the Gauntlet or live (ideally one you posted on).
2. Copy `templates/seminar-prep.md` to `my-work/19-review-and-contribution-practicum/comms/seminar-<date>-prep.md` and fill it in: a 2-minute intro, background, **3+ open questions**
   (not yes/no), the one thing you're still unsure about, and an optional regtest demo.
3. Rehearse the intro aloud with a timer. If it goes over 2 minutes, cut it.
4. Publish the reading list entry 1–2 weeks before the meetup.
5. Afterwards, write down in `my-work/19-review-and-contribution-practicum/comms/seminar-<date>-retro.md` which questions started discussion
   and which fell flat. Do not attribute anything said in the room to a named person.

**Done when:** one reproduction write-up, one post draft (posted or not), and one seminar prep
plus retro exist.

**Checker:** `python3 check_practicum.py comms`. It checks the files exist and are really filled in: no
`____` blanks, a full 40-character commit hash and an `n / m` failure rate in the reproduction, real log
lines, at least 150 words in the post draft, three or more open questions in the seminar prep, and a retro.
It cannot judge quality; the issue thread, the forum and your BitDevs group do that.
