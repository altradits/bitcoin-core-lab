# Stage 09: The Bug Dojo — Break It, Fix It, Prove It, Review It

> Source checked: `master` (`e75b76b12c`) and `v29.0` (`f490f5562d`). The upstream PRs named
> below were confirmed as merged with `gh pr view` and `git log --merges --grep` on 2026-11-15.

**No-Shortcuts Rule.** Each mission gives you the *bug*, the *theory* and layered hints — never the
finished fix. You write the fix in `dojo_missions.go`; for Mission 6 you write the **test**.
Reference code is in [`solutions/`](./solutions/); `./lab.sh dojo solve` restores it. Open it only
after `./lab.sh dojo check` passes or after **3 honest attempts**. Journal:
`my-work/09-bug-dojo-and-pr-mastery/journal.md`.

---

## Objectives

| ID | You can... |
|----|------------|
| C-CONS-1 | state and implement the `CheckTransaction` invariants (value range, duplicate inputs, coinbase scriptSig length) |
| C-CONS-3 | explain CVE-2010-5139 (value overflow) and CVE-2018-17144 (duplicate inputs) and where the protection lives now |
| C-TEST-3 | write a test that passes on correct code and fails on every boundary mutant |
| C-REVIEW-1 | triage a fix PR: risk area, invariant, what a regression test must cover |
| C-GIT-2 / C-GIT-6 | check out the real PR and find, with `git log -S` and `git blame`, when a line was introduced |

## Prerequisites
Stages 02, 03 and 07. Go (`/usr/local/go/bin/go`). Estimated time: 12 hours.

## Commands
```
./lab.sh dojo break        # load the broken pre-fix code into dojo_missions.go
./lab.sh dojo check [1-6]  # run all missions or one
./lab.sh dojo solve        # restore the reference (spoiler)
./09-bug-dojo-and-pr-mastery/check_mission6.sh   # grades the test YOU write in Mission 6
```

---

## Missions

### Mission 1 — The consensus shield (CVE-2010-5139, CVE-2018-17144)
**Upstream:** `CheckTransaction` in [`src/consensus/tx_check.cpp`](https://github.com/bitcoin/bitcoin/blob/master/src/consensus/tx_check.cpp).
**Bug:** the broken `CheckTransactionConsensus` adds output values before range-checking each
one, and never looks for an outpoint spent twice in the same transaction.
**History:** in August 2010 a block created ~184 billion BTC through an overflowing sum
(CVE-2010-5139). In 2018 a duplicate-input check skipped for performance could have crashed nodes
or allowed inflation (CVE-2018-17144).

<details><summary>Hint 1 (concept)</summary>

Signed 64-bit addition wraps around. Which check must happen *before* each addition so that the
running total can never wrap? And what data structure tells you "I have seen this outpoint before"?
</details>
<details><summary>Hint 2 (where)</summary>

Read `tx_check.cpp` from top to bottom and copy the *order* of the checks, with the same reject
strings (`bad-txns-vout-negative`, `bad-txns-vout-toolarge`, `bad-txns-txouttotal-toolarge`,
`bad-txns-inputs-duplicate`).
</details>

### Mission 2 — BIP32 seed length (PR #35320)
**Upstream:** `CExtKey::SetSeed` in `src/key.cpp` (master). **Bug:** any seed length is accepted.
**Theory:** BIP32 defines the seed as 128–512 bits. The master key is HMAC-SHA512("Bitcoin seed", seed).
<details><summary>Hint 1</summary>

Read BIP32 ("Master key generation") in your offline BIPs folder for the allowed range in bytes.
Then compare with what PR #35320 asserts (`git show` the merge commit in your checkout).
</details>

### Mission 3 — sigop-adjusted vsize (PR #32800)
**Upstream:** `GetVirtualTransactionSize` in `src/policy/policy.cpp`; RPC fields in
`src/rpc/mempool.cpp`. **Bug:** the broken code charges only for weight, so a tiny tx full of
signature operations is underpriced.
<details><summary>Hint 1</summary>

Find `nBytesPerSigOp` / `DEFAULT_BYTES_PER_SIGOP` in `src/policy/settings.h` and
`src/policy/policy.h`. The adjusted size uses the *larger* of two weights. Mind the rounding:
vsize is weight / 4 rounded **up**.
</details>

### Mission 4 — replacement anti-DoS (Stage 03 rules 4 and 6)
**Upstream:** `PaysMoreThanConflicts`, `PaysForRBF` in `src/policy/rbf.cpp` (v29).
**Bug:** the broken validator only compares absolute fees.
<details><summary>Hint 1</summary>

Compare feerates without floating point: if a/b > c/d with positive b, d, then a·d > c·b.
Rule 4 is the inequality you computed by hand in Stage 03 Worksheet 1.
</details>

### Mission 5 — invalid partial signatures in a PSBT (PR #33014)
**Upstream:** `descriptorprocesspsbt` in `src/wallet/rpc/spend.cpp`. **Bug:** an invalid existing
or new partial signature is accepted.
<details><summary>Hint 1</summary>

A DER signature plus sighash byte has a minimum and maximum length (BIP66, `IsValidSignatureEncoding`
in `src/script/interpreter.cpp`). Reject both bad existing and bad new signatures, with an error,
not a panic.
</details>

### Mission 6 — you write the regression test
**Upstream:** the `bad-cb-length` rule in `tx_check.cpp`: a coinbase scriptSig must be 2–100
bytes. `CheckCoinbaseScriptSigLength` is already correct in the solution and subtly wrong in
`broken/`. Write `mission6_test.go` (package `dojo`, a func named `TestMission6_...`) in this
directory. `check_mission6.sh` runs your test against the correct code (must pass) and four
boundary mutants (each must fail).
<details><summary>Hint 1</summary>

Table-driven tests: a slice of `{length, wantErr}` cases. Test both sides of each edge.
</details>

---

## After each mission: review the real PR
For Missions 2, 3 and 5, check out the PR in your Core checkout (`git fetch origin pull/<n>/head:pr-<n>`),
list its commits, read its tests, and answer in your journal: what invariant does the fix
protect, and would the PR's own test fail without the fix? (Stage 19's review method.)
Note: the old `pr-reviews/PR-*-AUDIT.md` files contain conclusions written for you; treat them
as someone else's notes to compare against **after** your own review, never as text to post.

---

## Checkpoint

```bash
./lab.sh check 09
```

Runs: go vet + go test on `dojo_missions.go`, then ./check_mission6.sh. Each prints PASS/FAIL with a reason, never the answer. `./check_mission6.sh` runs your Mission 6 test against boundary mutants; a strong test kills all of them.
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_09=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).
1. Why must each output be range-checked *before* it is added to the running total?
2. Why was the duplicate-input check ever skipped, and what was the 2018 consequence?
3. What is the BIP32 seed length range in bytes?
4. Write the sigop-adjusted vsize formula with the default bytes-per-sigop.
5. Why compare feerates by cross-multiplication?
6. Give the four boundary values a test of a "2..100 inclusive" rule must use.
7. What is a "mutant", and why does a test that never fails prove nothing?
8. How do you find the commit that introduced a given line in Core?

## Review lens
- Files: `src/consensus/tx_check.cpp`, `src/consensus/tx_verify.cpp`, `src/key.cpp`,
  `src/policy/policy.cpp`, `src/policy/rbf.cpp`, `src/wallet/rpc/spend.cpp`, tests
  `src/test/transaction_tests.cpp`, `src/test/key_tests.cpp`, `test/functional/rpc_psbt.py`.
- Questions: Is the fix consensus (then it needs extreme care, a soft-fork-safe design, and
  usually no behaviour change) or policy/RPC? Does the test fail without the fix? Are the
  boundary cases covered? Could the fix itself crash on malformed input?

## Proof-of-work output
Your `mission6_test.go` and a journal entry per mission. Later: the same mutation discipline in a
real test-coverage PR (Stage 19).
