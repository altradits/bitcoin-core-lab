# Exercise 19.3: Bitcoin Core PR Review Club

`CONTRIBUTING.md` points new contributors to the [Bitcoin Core PR Review Club](https://bitcoincore.reviews/).
Facts below were read from the site on 2026-11-09:

- **Purpose:** "To help newer contributors learn about the Bitcoin Core codebase and review
  process." It is "not primarily intended to help open PRs get merged."
- **When:** "first Wednesday and Thursday of the month, at 17:00 UTC" (that is **20:00 EAT** in Kisumu).
  Check the homepage for the next date, because the schedule can change.
- **Where:** IRC, `#bitcoin-core-pr-reviews` on Libera Chat (web.libera.chat works).
- **Meeting pages** are at `https://bitcoincore.reviews/<PR number>`. They have **Notes**, a numbered
  list of **Questions**, and a **Meeting Log** added afterwards. The archive is at `/meetings/`.
  Example: `/33300` ("Compact block harness"). Its first question is "Did you review the PR?
  Concept ACK, approach ACK, tested ACK, or NACK? What was your review approach?"
- **Etiquette** (from `/your-first-meeting/`): the host opens with `#startmeeting`, and you say "hi" to show
  you are present. Address people as `nick:` (no `@`). Ask questions at any time. Lurking is fine.
  The host closes with `#endmeeting`.
- **Hosting:** see `/hosting`. Glozow and stickies-v schedule upcoming meetings.
- On GitHub, PRs chosen for a meeting get the **`Review club`** label (it exists in
  `gh label list -R bitcoin/bitcoin`).

---

## Part A: Practice on past meetings (no audience, unlimited tries)

Do this for **3 past meetings**, one each from tests, wallet, and p2p. Pick them from `/meetings/`.

1. Open the meeting page. Read **only the Notes and Questions**. Do not scroll to the log.
2. Check out the PR at the head that was current on the meeting date. Work out how to find it.
   <details><summary>Hint 1</summary>The PR's commit and push history on GitHub has dates.</details>
   <details><summary>Hint 2</summary>The meeting log often states the hash being discussed. You may search the log for that hash only.</details>
3. Follow the review method (exercise 1) as far as your time allows.
4. Answer **every** question in `my-work/19-review-and-contribution-practicum/review-club/<PR>-answers.md` under a
   heading `## My answers`, in your own words, with `file:line` references where needed.
5. Now read the meeting log. Under a heading `## After reading the log`, note for each question: what did participants say that you
   missed? Where were you more precise? Did the host correct someone, and why?
6. Write a short list of what to study next.

## Part B: Live meeting

1. Prepare the week before: build the PR, run its tests, and write answers as in Part A.
2. Attend. Say "hi". Answer at least one question in your own words. Ask at least one
   question you really have.
3. Afterwards, find your nick in the published log and record the link in
   `../BTRUST_READINESS_TRACKER.md` (see exercise 6).
4. Consider leaving a review on the PR itself if you found something. Same rules: your own
   words, your own testing.

## Part C (later): Bring it home to Kisumu

Run one past meeting as a practice session at BitDevs Kisumu or a study group: use the
meeting's questions with your group, then compare with the real log together.
Credit the original host and link the page.

**Done when:** 3 past-meeting answer files exist with the post-log comparison filled in, and
you have attended at least 2 live meetings.

**Checker:** `python3 check_practicum.py club`. It checks that three answer files have both sections filled
in and that tracker section 6 lists at least two live meetings (a `bitcoincore.reviews/<N>` link with
Attended = yes). It cannot judge your answers; the meeting log does that.
