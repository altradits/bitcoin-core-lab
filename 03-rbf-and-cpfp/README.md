# Stage 03: Replace-By-Fee, Child-Pays-For-Parent, and Fee Arithmetic

> Source checked: your binary is Bitcoin Core `v29.0` (`f490f5562d`); upstream `master`
> (`e75b76b12c`) is noted wherever it behaves differently. Teach yourself `master`'s rules, then
> observe `v29.0` on regtest and write down the differences.

**No-Shortcuts Rule.** You build every original, every replacement and every child transaction
yourself with raw-transaction RPCs, and you do the fee arithmetic on paper first. Worksheets give
goals and layered hints, never the finished command. Checkers inspect your node and your
`answers.env`. The old demo script is now the spoiler in
[`solutions/rbf_and_cpfp.sh`](./solutions/rbf_and_cpfp.sh) — open it only after a check passes or
after **3 honest attempts**. Journal: `my-work/03-rbf-and-cpfp/journal.md`.

---

## Objectives

| ID | You can... |
|----|------------|
| C-MEMPOOL-2 | state every current replacement rule (v29 and master), compute the minimum replacement fee by hand, and replace a transaction with raw RPCs; explain CPFP and compute a package (ancestor) feerate |
| C-MEMPOOL-5 (intro) | explain how the block assembler picks transactions (ancestor-feerate packages in v29, chunks in master) and why that makes CPFP work |
| C-TX-2 | build conflicting transactions with `createrawtransaction`, control `nSequence`, and read `testmempoolaccept` errors |

## Prerequisites
Stage 02 (you can build, sign and broadcast a raw tx with exact fees). Your node from Stage 01
with mature coins in `kisumu_miner` and an empty `kisumu_merchant` wallet. Export `BTC_CLI`.

Estimated time: 8 hours.

---

## Theory

### 1. Why fee bumping exists
A transaction sits in mempools until a miner includes it. If the feerate you picked is too low,
you have two tools:

- **RBF (sender side):** broadcast a *conflicting* transaction (spends at least one of the same
  inputs) that pays more. Nodes evict the original and its descendants.
- **CPFP (receiver or sender side):** spend an output of the stuck transaction with a high-fee
  *child*. A miner who wants the child's fee must include the parent first.

### 2. Signalling: BIP125 vs full-RBF
BIP125 said: a tx is replaceable if any input has `nSequence <= 0xfffffffd` (`MAX_BIP125_RBF_SEQUENCE`,
`src/util/rbf.h`) or an unconfirmed ancestor signals. Core history (`doc/policy/mempool-replacements.md`):
- v24.0: `-mempoolfullrbf` option added (PR #25353).
- **v28.0: full-RBF is the default** (PR #30493): every unconfirmed tx can be replaced, signalling or not.
- PR #30592 removed the option; signalling is no longer consulted.

`bip125-replaceable` still appears in some RPC output — it reports the old signal, **not** whether
your node will accept a replacement. You prove this yourself in Worksheet 1.

### 3. The replacement rules
`v29.0` (your binary), from `doc/policy/mempool-replacements.md`:

| # | Rule | Where in code |
|---|------|---------------|
| 2 | no *new* unconfirmed inputs (unless they were already inputs of a conflict) | `HasNoNewUnconfirmed` in `src/policy/rbf.cpp` → `replacement-adds-unconfirmed` |
| 3 | replacement absolute fee ≥ sum of fees of everything it evicts | `PaysForRBF` |
| 4 | *additional* fee ≥ `incrementalrelayfee × replacement vsize` (1 sat/vB default in v29) | `PaysForRBF` → `insufficient fee` |
| 5 | at most 100 original txs evicted (`MAX_REPLACEMENT_CANDIDATES`) | `GetEntriesForConflicts` → `too many potential replacements` |
| 6 | replacement feerate > feerate of every directly conflicting tx | `PaysMoreThanConflicts` → `insufficient fee` |
| — | the replacement must not spend an output of a tx it replaces | `EntriesAndTxidsDisjoint` → `bad-txns-spends-conflicting-tx` |

`master` (cluster mempool, v31.0 onward): rules 2 and the old 6 are **removed**; rule 4's default
incremental feerate is **0.1 sat/vB** (PR #33106, `DEFAULT_INCREMENTAL_RELAY_FEE{100}` in
`src/policy/policy.h`); rule 5 counts distinct **clusters** (≤ 100); new rule 6 says the mempool's
**feerate diagram must strictly improve** (`ImprovesFeerateDiagram` in `src/policy/rbf.cpp`).
Stage 18 teaches the diagram.

Rule 4 on paper: `min_new_fee = old_fee_total + ceil(incremental_sat_per_vB × new_vsize)`.
Rule 3 alone is not enough: without rule 4 an attacker could make the whole network relay a
transaction again and again for 1 extra sat each time.

### 4. CPFP and the ancestor package
For every mempool entry, v29 tracks the **ancestor set** (itself plus unconfirmed parents, recursively):
`fees.ancestor` and `ancestorsize` in `getmempoolentry`. The package feerate is

```
package_feerate = (parent_fee + child_fee) / (parent_vsize + child_vsize)
```

The v29 block assembler (`BlockAssembler::addPackageTxs`, `src/node/miner.cpp`) sorts candidates
by ancestor feerate, so a rich child drags its parent in. Limits (v29 `src/policy/policy.h`):
25 ancestors / 25 descendants, 101 kvB each way, plus the **CPFP carve-out**
(`EXTRA_DESCENDANT_TX_SIZE_LIMIT` = 10,000 vB) that lets one extra small child through — important
for Lightning's two-party channels (Stage 05 and 18).

On `master`, block building uses **chunks** of a linearized cluster (`BlockAssembler::addChunks`,
`GetBlockBuilderChunk`), and `getmempoolentry` adds `chunkweight` and `fees.chunk`. The idea is the
same — a child raises the feerate of the group that contains its parent — and the result is more
exact.

### 5. Who uses which tool
- Wallets: `bumpfee` (RBF) and `psbtbumpfee`. Read `src/wallet/feebumper.cpp` — it builds the
  replacement exactly as you do by hand, then checks the same rules.
- Lightning: commitment transactions are pre-signed, so their fee cannot be changed by RBF alone →
  anchor outputs + CPFP, later TRUC (Stage 05).
- Exchanges: batch payouts → RBF to add outputs ("payjoin" and batching interactions).

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | [RBF by hand: fail rule 4, then replace](./exercises/01-rbf-by-hand.md) | `./check_rbf.sh` |
| 2 | [Full-RBF: replace a tx that does not signal](./exercises/02-full-rbf-no-signal.md) | `./check_rbf.sh` |
| 3 | [CPFP: pull a stuck parent into a block](./exercises/03-cpfp-package-feerate.md) | `./check_cpfp.sh` |
| 4 | [Read the code: rbf.cpp, feebumper.cpp, miner.cpp](./exercises/04-read-the-code.md) | `./check_code_reading.sh` |

Copy [`exercises/answers.env.template`](./exercises/answers.env.template) to
`my-work/03-rbf-and-cpfp/answers.env` and fill it as you go. Checkers read `BTC_CLI` (default
`bitcoin-cli -regtest`), `MY_WORK` and `ANSWERS` from the environment.

---

## Checkpoint

```bash
./lab.sh check 03
```

Runs: ./check_rbf.sh, ./check_cpfp.sh, ./check_code_reading.sh. Each prints PASS/FAIL with a reason, never the answer. Start your own regtest node first; the checkers read its state and your `answers.env`.
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (from memory; answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. A 200 vB tx paid 400 sat. On v29 with default settings, what is the smallest fee its 210 vB replacement can pay? On master?
2. Why does rule 3 (absolute fee) exist when rule 6 already demands a higher feerate?
3. Your tx's input has `nSequence = 0xffffffff`. Can your v29 node replace it? Why might the `bip125-replaceable` field say `no`?
4. Parent 150 vB / 150 sat, child 110 vB. What child fee gives a 20 sat/vB package?
5. What is the CPFP carve-out and which user of Bitcoin needed it?
6. Why can a Lightning commitment transaction not be fee-bumped with RBF by one party alone?
7. What does `replacement-adds-unconfirmed` protect against, and why did master drop it?
8. Name the function that implements rule 4 and the file it lives in.

---

## Review lens
When a PR touches replacement or fee-bumping:
- Files: `src/policy/rbf.{h,cpp}`, `src/validation.cpp` (`MemPoolAccept::ReplacementChecks`,
  `PackageMempoolChecks`), `src/txmempool.{h,cpp}`, `src/wallet/feebumper.cpp`,
  `doc/policy/mempool-replacements.md`, tests `test/functional/feature_rbf.py`,
  `mempool_package_rbf.py`, `wallet_bumpfee.py`, `src/test/rbf_tests.cpp`.
- Invariants: replacements never lower total fees in the next block (incentive compatibility);
  every replacement pays for its own relay (no free relay); eviction work is bounded (rule 5).
- Questions to ask: Does the change alter what a *miner* earns, or only what a *node relays*? Can
  an attacker now pin a victim's transaction (make it expensive or impossible to replace)? Is the
  doc in `doc/policy/` updated in the same PR? Do the functional tests cover both acceptance and
  each reject string?

## Proof-of-work output
A short write-up in your own words in `my-work/03-rbf-and-cpfp/` explaining full-RBF vs BIP125
signalling, with the txids you replaced on regtest. Suitable later for a BitDevs Kisumu
discussion slot or a blog post. Do not publish someone else's numbers as yours.
