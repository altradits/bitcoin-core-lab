# Curriculum Conventions (the contract every stage follows)

This lab exists so that **Stanley (@altradits) becomes a Bitcoin Core / Lightning
contributor who can review any PR and contribute upstream with confidence, and who
meets what Btrust asks of a grant applicant.** Every file in this repo follows the
rules below.

## 1. The No-Shortcuts Rule
The learner types every command and writes every line of code that teaches a skill.
The lab never hands over a script that does the work.

- **Exercises are worksheets, not scripts.** Each step says *what to achieve* and
  *which RPC / file / concept to use*. It does not show the finished command.
  Example: "Build a raw tx spending exactly one UTXO to the merchant address with a
  10,000-sat fee. Use `createrawtransaction`. Read `bitcoin-cli help createrawtransaction` first."
- **Hints come in layers.** Use collapsible `<details>` blocks: Hint 1 (concept) →
  Hint 2 (which RPC/function and its arguments) → there is **no** Hint 3 with the full answer.
- **Reference solutions live in `solutions/`** in each stage, and the learner opens them
  only after a check passes or after 3 honest attempts. Every README says this.
- **Checkers verify outcomes, not keystrokes.** `check_*.sh` / `*_test.go` / `test_*.py`
  look at state (a tx in the mempool, a test passing, a file the learner wrote) and print
  PASS/FAIL with a reason. They never print the answer.
- **Command journal.** Each exercise asks the learner to save the commands they typed in
  `my-work/<stage>/journal.md` (git-ignored by default, so the learner chooses what to publish).
- Helper scripts that only set up the environment (start regtest, fund a wallet) are
  allowed, and are labelled `setup_*.sh`. Note: by Stage 02 the learner writes their
  own setup.

## 2. Stage Layout
```
NN-stage-name/
  README.md          # Objectives (competency IDs), prerequisites, theory, exercises, self-check, "Review lens"
  exercises/         # worksheets, blank code skeletons with TODOs
  check_*.sh|*_test.go|test_*.py   # outcome checkers
  solutions/         # reference answers (spoilers)
```
Every stage README ends with:
- **Self-check quiz**: 5–10 questions answered from memory, with answers in `solutions/`.
- **Review lens**: how this stage's knowledge is used when reviewing a real `bitcoin/bitcoin`
  PR that touches this area (the files and invariants to look at, and the questions to ask).
- **Proof-of-work output**: the public artifact this stage produces, if any (e.g. a gist,
  a PR Review Club answer, a test written).

## 3. Competency IDs (defined in `CURRICULUM.md`)
Stages tag objectives with IDs such as `C-BUILD-1`, `C-P2P-2`, `C-REVIEW-3`. `CURRICULUM.md`
is the single source of truth for the IDs. If a stage needs an ID that does not exist yet,
use the area prefix and list the new ID in your final report so the architect adds it.
Area prefixes: `C-GIT` `C-BUILD` `C-CPP` `C-PY` `C-TEST` `C-FUZZ` `C-DEBUG` `C-TX` `C-SCRIPT`
`C-CRYPTO` `C-CONS` `C-VAL` `C-P2P` `C-MEMPOOL` `C-WALLET` `C-PSBT` `C-LN` `C-REVIEW`
`C-CONTRIB` `C-COMMS` `C-BTRUST`.

## 4. Accuracy
- The upstream source is at `~/bitcoin`. Check every file path, function name
  and constant against it with `grep`. Note which commit you checked (`git -C ~/bitcoin log -1 --oneline`).
- Do not invent BIP numbers, PR numbers, CVE details, or Btrust rules. If you cannot
  verify something, label it `UNVERIFIED` rather than presenting it as fact.
- Use relative links (`../pr-reviews/...`), not `file://~/...` links, so the repo works on GitHub.

## 5. Integrity (Btrust and upstream AI policy)
- The lab teaches; the learner does the public work. Nothing in this repo is a ready-to-post
  review comment, ACK, or PR description written on the learner's behalf. Templates have
  blanks the learner fills from their own testing.
- Bitcoin-only and FOSS-only (MIT). No altcoin or token content.

## 6. Machine Limits
The machine is an Apple M1 with 8 GB of RAM. Do not compile Bitcoin Core during authoring.
Do not start more than one `bitcoind` at a time.
