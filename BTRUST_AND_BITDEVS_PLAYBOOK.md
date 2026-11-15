# Btrust Programs & BitDevs Kisumu Playbook (verified)

This playbook covers two things:
1. Which Btrust program to aim for, and what each one actually asks for.
2. How to run BitDevs Kisumu within Btrust's sponsorship terms.

Every claim below is either quoted from a source in
[Sources checked](#sources-checked-date-2026-11-09) or marked **UNVERIFIED**.
Earlier versions of this file stated requirements that the sources do not support
(see [Corrections](#corrections-made-on-2026-11-09)).
Btrust pages change, so re-read them before you apply.

Your evidence lives in [BTRUST_READINESS_TRACKER.md](./BTRUST_READINESS_TRACKER.md).
The route to it is in [CURRICULUM.md](./CURRICULUM.md).

---

## Part 1: What Btrust funds (btrust.tech/grants)

- Btrust funds "open-source Bitcoin developers working to improve the Bitcoin ecosystem".
  Its focus areas are "Bitcoin protocol improvements, Layer 2 solutions, security enhancements, and other critical open-source projects".
- Grant categories listed: **Developer**, **Education** and **Event** grants.
- Geography: "Africa, India, Latin America, MENA, and Southeast Asia". Other Global South applicants are considered "contingent on their Proof of Work".
- Payment: "paid monthly or one-time (depending on the grant) in Bitcoin (BTC)".
- Applications are "reviewed on a rolling basis".
- Grant amounts are **not stated** on the page.
- Reporting obligations for developer grants are **not stated** on the page. **UNVERIFIED:** expect monthly reports, and ask Btrust when you are accepted.

## Part 2: The three developer routes

### A. Btrust Builders (training program, Africa)
From btrust.tech/builders and /builders/apply:
- "a comprehensive engineering program designed to train experienced software developers in Africa".
- Criteria: "3+ years of experience as a software developer in a production environment"; "an active GitHub/GitLab account"; "Demonstrate your ability to engage with the technical content"; "a minimum of 20 hours per week"; "willingness to learn and grow".
- The application includes a **code challenge**.
- Applications are "open all year round", and you hear back "within two weeks".
- Participants are paid during a "training period". The length of that period is **not stated**.
- **Fit for you:** this is the realistic first application while you work through
  Gates 1–2. Before applying, check honestly that you meet the 3+ years of production experience.

### B. Btrust Starter Grant (six months, full-time)
From btrust.homerun.co/starter-grants. The page showed "**Applications closed**" on 2026-11-09.
- Ideal applicant: "made the jump from 'good first issues' to contribute more meaningful PRs and Reviews".
- "Have chosen a specific Bitcoin open-source project … and made several non-trivial code contributions". The page defines these as:
  - Reviews: "contributed multiple helpful insights on others' work and helped to move code that is not their own forward".
  - PRs: "**at least five merged code-based PR** (excluding documentation changes) that is not labelled as a 'good first issue'".
  - Other: "multiple helpful responses on issues, input on discussions, participation in community (project or otherwise, like BitDevs)".
- "Have a clear plan outlining what you want to work on over the next six months".
- "Be willing to commit full-time … during the six-month grant period".
- "Positive reviews from **at least two** mentors or contributors on the project".
- These map one-to-one onto **Gate 3** in [CURRICULUM.md](./CURRICULUM.md#gate-3-btrust-application-ready-no-fixed-week-it-depends-on-merges).

### C. Btrust Open Source Cohort (established contributors)
From btrust.homerun.co/open-source-cohort. The page showed "Applications closed" on 2026-11-09.
- You meet the starter-grant criteria, plus: "at least 2 year's worth of proof of work", a "non-trivial portfolio", "a clear vision … for the next year", a mentor or contributor willing to support you, a record of effective collaboration, and readiness to "support a mentee from the starter grantees".
- This route is out of scope for this lab's timeline. It is listed so you know where the path leads.

## Part 3: Bitcoin Core's own rules (they apply to every public action)

Checked in `~/bitcoin`, branch `master` at `e75b76b12c`:
- **`doc/AI_POLICY.md` exists on master.** It was added in 2026 and was last changed in
  `f5d7cc66ec` "doc: Discourage adding AI agents as commit authors". It is **not** in
  the 29.x checkout, so read it with `git show master:doc/AI_POLICY.md`. Its key points:
  - Comments must be written by humans. Comments believed to be AI-written "may be moderated".
  - Open a PR only if you know the language, "could have written the code yourself", and understand the surrounding code.
  - Explain the change in your own words. "Do not copy responses from the AI when replying to questions from reviewers."
  - PRs must not be "opened or driven by autonomous agents", and agents must not be listed as authors or co-authors of commits.
  - Any AI context you quote must be disclosed and accompanied by your own commentary.
- `CONTRIBUTING.md` (Getting Started): "In-depth reviewing and testing are the bottleneck of the project, and are the most effective way anyone can start to contribute". It also points to PR Review Club (bitcoincore.reviews).
- `CONTRIBUTING.md` (Peer Review): Concept (N)ACK and Approach (N)ACK are defined there. A code review "begins with `ACK BRANCH_COMMIT`" followed by how you reviewed it, and any testing beyond the existing tests should be described. A NACK needs a rationale.

What this means for the lab: nothing in this repo is a comment or PR text for you to post.
You write every public word from your own testing.

## Part 4: Running BitDevs Kisumu

From btrust.tech/bitdevs (verified):
- Sponsorship requires "at least two reliable and committed organizers, including a Bitcoin developer". Solo organizers are not eligible.
- Meetups are "technical, developer-focused discussions that follow a Socratic Seminar format". Topics must be "strictly related to Bitcoin".
- "BitDevs discussions are never recorded or live-streamed." Photos are at the organizers' discretion.
- Sponsorship covers essential costs ("venue, logistics, and operational support") and does not make the meetup a promotional platform.
- Cities already on Btrust's list are not sponsored twice. Btrust aims to respond within 2–4 weeks. New groups usually start with a **3-month probation**, and sponsorship can stop if meetups are inconsistent or drift off Bitcoin.
- The page expects regular **monthly** meetups.

**UNVERIFIED** (not on the Btrust or bitdevs.org pages checked; confirm with Btrust):
- Chatham House Rule. It is a widespread BitDevs convention but not a stated Btrust requirement.
- A budget template, a "10th of the month" reporting deadline, or any specific report format.

**Session design.** This is your work. Use these as prompts, not a script.
- At least one week before: publish a reading list. Sources you can draw from are Optech newsletters, PRs you reviewed, Delving Bitcoin threads, and BOLT changes. Which 5–8 items would make engineers argue usefully?
- During the session: for each item, what is the one question that exposes the trade-off? Write your own questions. Don't reuse examples from this file.
- After the session: log the date, topic list link and attendance count in the tracker (Gate 2 asks for 3 sessions).

## Part 5: Other funders (pointers only, not verified in this pass)

Summer of Bitcoin, Spiral, OpenSats, Brink and others fund Bitcoin FOSS work. Their
criteria were **not checked** on 2026-11-09. Read each funder's own site before
advising anyone in your community.

---

## Corrections made on 2026-11-09

| Previous claim | Status |
|---|---|
| Starter Grant needs "at least one merged code-based PR" | **Wrong.** The page says **at least five**. |
| Starter Grant needs "1 peer/contributor reference" | **Wrong.** The page says **at least two**. |
| "Btrust Builders: experienced engineers transitioning" | Partly true. The page specifies Africa, 3+ years production experience, 20 h/week and a code challenge. |
| Upstream projects enforce `doc/AI_POLICY.md` | **True for `bitcoin/bitcoin` master** (not the 29.x checkout). Not checked for lnd/LDK/BDK. |
| BitDevs: "at least one co-organizer must be a technical developer" | Close. The page says "including a Bitcoin developer". |
| BitDevs: Chatham House Rule is a Btrust rule | **UNVERIFIED.** Not stated on the Btrust page. |
| BitDevs: monthly budget/report due by the 10th | **UNVERIFIED.** Removed as a rule. |
| BitDevs: photography restricted | **Wrong.** The page leaves photos to organizers' discretion. Recording and streaming are banned. |
| "Promoting altcoins disqualifies immediately"; mandatory MIT/BSD/Apache | **UNVERIFIED** as wording. The pages do say "Bitcoin-only" and "strictly related to Bitcoin" (BitDevs) and "open-source Bitcoin" (grants). |
| "Btrust evaluates monthly progress reports" | **UNVERIFIED.** |
| Lab-specific "Bitrust Bootcamp 2026" | **UNVERIFIED.** Removed. |

## Sources checked (date 2026-11-09)

- https://www.btrust.tech/grants
- https://www.btrust.tech/builders and https://www.btrust.tech/builders/apply
- https://btrust.homerun.co/starter-grants
- https://btrust.homerun.co/open-source-cohort
- https://www.btrust.tech/bitdevs
- https://bitdevs.org/ (no Chatham House or recording policy stated)
- Local: Bitcoin Core checkout (`$BITCOIN_ROOT`) `master` (`e75b76b12c`): `doc/AI_POLICY.md`, `CONTRIBUTING.md`
