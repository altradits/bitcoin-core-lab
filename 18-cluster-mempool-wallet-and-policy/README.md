# Stage 18: Cluster Mempool, Wallet Internals and Policy

> **Source checked.** Cluster mempool is **merged on master** (PR #33629 "Cluster mempool", merge
> `fa283d28e2`; `src/txgraph.h` and `getmempoolcluster` exist on master `e75b76b12c`). Your built
> v29.0 binary (`f490f5562d`) still has the ancestor/descendant mempool. Everything below says which
> version it describes. Part B of Exercise 18.3 needs a master build and was **UNVERIFIED** at
> authoring time (only a 29.x build was available); Part A was run and passes on 29.x.

**No-Shortcuts Rule.** You write the linearization code, the package-RBF/cluster functional test
and a coin-selection unit test yourself; you predict coin selection before you ask the wallet.
Journal: `my-work/18-cluster-mempool-wallet-and-policy/journal.md`. Spoilers in [`solutions/`](./solutions/).

---

## Objectives

| ID | You can... |
|----|------------|
| C-MEMPOOL-1 | list the ATMP stages (`PreChecks`, `ReplacementChecks`, `PolicyScriptChecks`, `ConsensusScriptChecks`, `Finalize`) and where package validation differs |
| C-MEMPOOL-2 | explain master's RBF rules: total fee, incremental fee, ≤ 100 clusters, and a **strictly better feerate diagram** |
| C-MEMPOOL-3 | relate packages/TRUC/ephemeral dust (Stage 05) to cluster mempool |
| C-MEMPOOL-4 | compute a linearization's chunks and feerate diagram by hand and in code; explain `TxGraph` and cluster limits |
| C-MEMPOOL-5 | explain fee estimation (`src/policy/fees/` on master) and block template building by chunks |
| C-WALLET-1..4 | explain `CWallet` / `ScriptPubKeyMan` / `DescriptorScriptPubKeyMan`, coin selection (BnB, CoinGrinder, SRD, Knapsack) and waste, and legacy→descriptor migration |
| C-SCRIPT-4 | tell consensus script flags from standardness rules in `src/policy/policy.cpp` |
| C-LN-4 | explain why cluster mempool and TRUC end most pinning attacks Lightning worried about |

**Prerequisites:** Stages 03, 05, 07, 13 (and a master worktree from Stage 17 for Part B).
**Estimated time:** 18 hours.

---

## Theory

### 1. From ancestor sets to clusters
v29 scores a tx by its **ancestor feerate** and limits ancestors/descendants (25 each, 101 kvB).
That score is an approximation: what a miner earns depends on the whole connected component.
A **cluster** = all txs connected through spends. Master keeps every cluster **linearized** (an
order that respects parents-before-children), splits each linearization into **chunks** (maximal
prefixes of best feerate), and mines/evicts by chunk feerate. Limits become per cluster:
`DEFAULT_CLUSTER_LIMIT` = 64 txs and `DEFAULT_CLUSTER_SIZE_LIMIT_KVB` = 101 (`src/policy/policy.h`,
master; options `-limitclustercount`, `-limitclustersize`). Code: `src/cluster_linearize.h`
(algorithms), `src/txgraph.{h,cpp}` (the graph the mempool maintains), `doc/policy/mempool-design.md`.

### 2. Chunks and feerate diagrams (Exercise 18.2)
Given a linearization `L`, repeatedly take the prefix with the highest feerate (ties: the longer
prefix) → chunk; remove it; repeat. Plot cumulative (size, fee) at chunk boundaries: that is the
**feerate diagram**. Diagram A is at least as good as B if it is never below B. A replacement is
accepted on master only if the new mempool's diagram is **strictly better** for the affected
clusters (`ImprovesFeerateDiagram`, `src/policy/rbf.cpp`).

### 3. RBF on master vs v29 (recap from Stage 03)
Removed: "no new unconfirmed inputs" and "feerate higher than each direct conflict". Kept: total
fee ≥ originals, extra fee pays incremental relay (0.1 sat/vB default on master), ≤ 100 distinct
clusters touched. Added: diagram check. Package RBF (1P1C replacing a cluster of ≤ 2) since
PR #28984.

### 4. Fees and block templates
Fee estimation (`CBlockPolicyEstimator`; master `src/policy/fees/block_policy_estimator.cpp`,
v29 `src/policy/fees.cpp`) buckets confirmed txs by feerate and tracks how fast each bucket
confirmed; `estimatesmartfee` answers from that history. The block template on master is built
from chunks (`BlockAssembler::addChunks`); on v29 from ancestor packages (`addPackageTxs`).

### 5. Wallet internals
`CWallet` (`src/wallet/wallet.h`) owns `ScriptPubKeyMan`s; descriptor wallets use
`DescriptorScriptPubKeyMan` (`src/wallet/scriptpubkeyman.h`), one per (output type, internal/external).
Storage is SQLite (`src/wallet/sqlite.cpp`). Legacy (BDB) wallets: v29 can still create them only
with `-deprecatedrpc=create_bdb`; master removed legacy wallet support except for **migration**
(`migratewallet`, `src/wallet/migrate.cpp`).

**Coin selection** (`src/wallet/coinselection.{h,cpp}`, driver `ChooseSelectionResult` in
`src/wallet/spend.cpp`): candidates use **effective value** (value − fee to spend it, PR #17331).
Algorithms: `SelectCoinsBnB` (Branch and Bound: exact match within `cost_of_change`, no change
output), `CoinGrinder` (minimise input weight when feerates are high, PR #27877), `SelectCoinsSRD`
(single random draw), `KnapsackSolver` (legacy approximation). The wallet runs several and picks the
result with the lowest **waste** (`RecalculateWaste`): fee now vs fee at long-term feerate, plus
change cost or excess.

### 6. Standardness vs consensus for scripts
`IsStandardTx`, `AreInputsStandard`, `IsWitnessStandard` (`src/policy/policy.cpp`) and the
`STANDARD_SCRIPT_VERIFY_FLAGS` set are *policy*; `MANDATORY_SCRIPT_VERIFY_FLAGS` and block
validation flags are *consensus*. A non-standard tx can still be valid in a block.

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 18.1 | [Read the policy docs on master vs 29.x](./exercises/18.1-policy-docs.md) | self-check vs `solutions/18.1-answers.md` |
| 18.2 | Write `linearize.py` from [the skeleton](./exercises/linearize_skeleton.py): chunk, diagram, compare | `python3 18-cluster-mempool-wallet-and-policy/test_linearize.py` |
| 18.3 | Complete [the package-RBF / cluster-limit functional test](./exercises/mempool_pkgrbf_cluster_skeleton.py) | `./check_18.sh pkgrbf` |
| 18.4 | [Predict coin selection, then ask the wallet](./exercises/18.4-coin-selection-predict.md) | `./check_18.sh coinsel` |
| 18.5 | [Write a coin-selection unit test in C++](./exercises/18.5-coinselector-unit-test.md) | `./check_18.sh unit` |

---

## Self-check quiz (answers in [`solutions/quiz-answers.md`](./solutions/quiz-answers.md))
1. Why is the ancestor feerate a poor estimate of a transaction's mining value in some clusters? Give an example.
2. Chunk the linearization [A: 1000 sat/200 vB, B: 100/100 (child of A), C: 3000/100 (child of B)].
3. What does "strictly better feerate diagram" mean, and why is it incentive compatible?
4. Which two v29 RBF rules did master remove, and why were they no longer needed?
5. When does BnB produce a transaction without change? What is `cost_of_change`?
6. What is "waste" and how does the wallet use it?
7. What is a `DescriptorScriptPubKeyMan`, and how many does a fresh descriptor wallet have?
8. Can a non-standard transaction be mined? What does that mean for the policy/consensus split?
9. What replaced `-limitancestorcount` on master, and what is it still used for?
10. How do cluster mempool and TRUC together reduce pinning for Lightning?

## Review lens
- Files: `src/txmempool.{h,cpp}`, `src/txgraph.{h,cpp}`, `src/cluster_linearize.h`, `src/validation.cpp`
  (`MemPoolAccept`), `src/policy/{policy,rbf,packages,truc_policy}.cpp`, `src/node/miner.cpp`,
  `src/policy/fees/`, `src/wallet/{coinselection,spend,wallet,scriptpubkeyman,migrate}.cpp`.
- Tests: `mempool_cluster.py` (master), `feature_rbf.py`, `mempool_package_rbf.py`, `rpc_packages.py`,
  `wallet_bumpfee.py`, `wallet_fundrawtransaction.py`, `wallet_migration.py`,
  `src/test/cluster_linearize_tests.cpp`, `src/test/txgraph_tests.cpp`,
  `src/wallet/test/coinselector_tests.cpp`, `coinselection_tests.cpp`, fuzz `cluster_linearize`, `txgraph`, `coinselection`.
- Invariants: mempool and block template agree on what is best; every limit bounds CPU per tx;
  replacements never reduce miner income; coin selection never overpays by more than the waste
  metric allows and never spends unconfirmed coins it was told not to.
- Questions: Does the change keep linearizations **optimal or at least as good** as before (ask
  for fuzz evidence)? What is the worst-case cost of one tx arrival? For wallet PRs: does it change
  which UTXOs are chosen (privacy, fees) — is there a test that pins the new choice?

## Proof-of-work output
Your `linearize.py` with a short explainer (your own diagrams) of chunks and feerate diagrams —
cluster mempool is new, so a clear explanation is valuable for BitDevs Kisumu and your blog.
