# Stage 05: TRUC (v3) Transactions, Package Relay, Ephemeral Dust — and Your First Concept Review

> Source checked: `v29.0` (`f490f5562d`) for the regtest behaviour; `master` (`e75b76b12c`) for
> current code. PR numbers below were verified as merge commits on `master` with
> `git log --merges --grep`.

**No-Shortcuts Rule.** You hand-edit the version bytes, build every parent and child, and submit
every package yourself. The old demo is the spoiler in
[`solutions/truc_1p1c_package.sh`](./solutions/truc_1p1c_package.sh). Journal:
`my-work/05-truc-package-relay-review/journal.md`.

---

## Objectives

| ID | You can... |
|----|------------|
| C-MEMPOOL-3 | explain and use package validation (`submitpackage`), 1P1C relay, TRUC rules (BIP431), sibling eviction, and ephemeral dust |
| C-REVIEW-2 | write a Concept/Approach review of a policy PR from its motivation, discussion and trade-offs — in your own words |
| C-LN-4 | explain pinning and why Lightning needed TRUC, package relay and ephemeral anchors |

## Prerequisites
Stage 03 (RBF/CPFP arithmetic) and Stage 04 (you can read `mempool_truc.py`). Estimated time: 10 hours.

---

## Theory

### 1. The problem: pre-signed transactions and pinning
A Lightning commitment transaction is signed by both parties when the channel state changes —
maybe months before it is broadcast. Nobody knows the right feerate then. Two failure modes:
1. **Too low to enter any mempool.** A 0-fee or 1 sat/vB commitment is rejected (`min relay fee
   not met`, `mempool min fee not met`), so the CPFP child never gets a chance: the child's
   parent is not in the mempool.
2. **Pinning.** The counterparty attaches a huge, low-feerate child. Replacing the commitment now
   requires paying for that whole child (rule 3), or the descendant limit blocks your own CPFP.

### 2. Package validation (`doc/policy/packages.md`, `src/policy/packages.{h,cpp}`)
`submitpackage` evaluates a **child-with-parents** package together. Limits: `MAX_PACKAGE_COUNT`
= 25, `MAX_PACKAGE_WEIGHT` = 404,000. Parents below the minimum feerate can be accepted if the
package feerate pays for them (*package CPFP*). On the P2P side, PR #28970 added **opportunistic
1P1C relay**: when a node receives a low-fee orphan child whose parent it rejected for low fee,
it tries the pair as a package (`p2p_opportunistic_1p1c.py`). Package RBF for clusters of size 2:
PR #28984.

### 3. TRUC — Topologically Restricted Until Confirmation (BIP431; PR #28948, #29873)
A transaction with `nVersion = 3` opts in to (`src/policy/truc_policy.h`):

| Constant | Value | Meaning |
|----------|-------|---------|
| `TRUC_ANCESTOR_LIMIT` | 2 | itself + at most 1 unconfirmed parent |
| `TRUC_DESCENDANT_LIMIT` | 2 | itself + at most 1 unconfirmed child |
| `TRUC_MAX_VSIZE` | 10,000 vB | any TRUC tx |
| `TRUC_CHILD_MAX_VSIZE` | 1,000 vB | a TRUC tx with an unconfirmed parent |

Also: an unconfirmed TRUC tx can only be spent by TRUC, and a TRUC tx can only spend unconfirmed
TRUC outputs (version inheritance). TRUC txs are always replaceable. Since only one child can
exist, a new child may **replace its sibling** (sibling eviction) if it pays rules 3/4. With the
child capped at 1,000 vB, the most an attacker can pin is ~1,000 vB of fee — bounded and known.
`TX_MAX_STANDARD_VERSION` became 3 in PR #29496.

### 4. Ephemeral dust (PR #30239, `src/policy/ephemeral_policy.{h,cpp}`)
A transaction may have **one** dust output (`MAX_DUST_OUTPUTS_PER_TX` = 1) only if the tx itself
pays **0 fee** and the dust is spent by a child in the same package. This gives Lightning a
keyless "anchor" anyone can use for CPFP, without leaving dust in the UTXO set. Test:
`mempool_ephemeral_dust.py`.

### 5. Concept vs approach review (C-REVIEW-2)
- **Concept ACK/NACK:** is the *problem* real and worth solving in Core?
- **Approach ACK/NACK:** is *this design* the right way (vs alternatives: package RBF only,
  cluster mempool first, CPFP carve-out extensions)?
- Then code review and testing (Stage 19). You may only write what you yourself believe and
  checked. Never post text you did not write (`doc/AI_POLICY.md` on master).

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | [Zero-fee TRUC parent: alone, wrong child, right child](./exercises/01-zero-fee-truc-package.md) | `./check_truc.sh` |
| 2 | [Sibling eviction](./exercises/02-sibling-eviction.md) | `./check_truc.sh` |
| 3 | [Ephemeral dust anchor](./exercises/03-ephemeral-dust.md) | `./check_truc.sh` |
| 4 | [Concept/approach review of PR #28948 (private notes)](./exercises/04-concept-review.md) | `./check_review_notes.sh` |

Copy [`exercises/answers.env.template`](./exercises/answers.env.template) to
`my-work/05-truc-package-relay-review/answers.env`.

---

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. Why can a 0-fee commitment transaction never be CPFP'd without package validation?
2. State the four TRUC numeric limits and what each one prevents.
3. What does "sibling eviction" let a TRUC child do, and why is it only safe with TRUC?
4. Which 4 bytes do you change to turn a v2 transaction into a v3 one, and what do they become?
5. When is a dust output standard, and what happens to it if the child is never broadcast?
6. Opportunistic 1P1C relay: what triggers it on a receiving node?
7. Difference between Concept ACK and Approach ACK, with a TRUC example of each.
8. What does pinning cost an attacker under TRUC compared with plain v2 + CPFP carve-out?

---

## Review lens
- Files: `src/policy/truc_policy.{h,cpp}`, `src/policy/packages.{h,cpp}`,
  `src/policy/ephemeral_policy.{h,cpp}`, `src/validation.cpp` (`AcceptPackage`,
  `AcceptMultipleTransactions`, `PackageMempoolChecks`), `src/node/txdownloadman_impl.cpp` and
  `src/txorphanage.cpp` (1P1C on master), `doc/policy/packages.md`.
- Tests: `mempool_truc.py`, `rpc_packages.py`, `mempool_package_rbf.py`,
  `mempool_ephemeral_dust.py`, `p2p_opportunistic_1p1c.py`, `p2p_1p1c_network.py`,
  `src/test/txpackage_tests.cpp`.
- Invariants: no package lets a tx in that would not be mined profitably; work per package is
  bounded; TRUC rules hold for every tx after reorgs (see PR #33504 on master, which stops
  enforcing TRUC checks for txs re-added on reorg); orphan handling cannot be used to exhaust memory.
- Questions: Can an attacker now pin at lower cost? Does relay match what miners would mine
  (incentive compatibility)? Does the doc in `doc/policy/` change in the same PR?

## Proof-of-work output
Your private concept/approach review notes in `my-work/05-truc-package-relay-review/`. When you
next see an open policy PR, write your own review from scratch in the same shape, test it, and
only then decide whether to post (Stage 19).
