# Stage 15: Validation, Chainstate and Reorgs

> **Source checked.** Teaches **`master`** at `e75b76b12c`; your built binary is **v29.0**
> (`f490f5562d`). Names below were checked with `grep` in both. Differences are marked
> **29.x → master**. No line numbers: find everything with `git grep -n`.

Consensus code is where one bug can split the network or create coins. Reviewers here move slowly,
ask for tests of every branch, and treat "refactor, no behaviour change" claims with suspicion.

**No-Shortcuts Rule.** You trace the code yourself, drive reorgs by typing the RPCs, and write the
reorg functional test from a skeleton. Journal: `my-work/15-validation-chainstate-and-reorgs/journal.md`.
Open [`solutions/`](./solutions/) only after `./check_15.sh` passes or after three honest attempts.

---

## Objectives

| ID | You can... |
|----|------------|
| C-VAL-1 | trace a block from `ProcessNewBlock` through `AcceptBlockHeader`, `CheckBlock`, `AcceptBlock`, `ActivateBestChain`, `ConnectTip`, `ConnectBlock` |
| C-VAL-2 | explain the `CCoinsView` layers, the chainstate LevelDB, `dbcache`, flushing, and undo data (`rev*.dat`) |
| C-VAL-3 | drive a reorg with `invalidateblock`/`reconsiderblock`, and explain `DisconnectBlock` and `MaybeUpdateMempoolForReorg` |
| C-VAL-4 | explain assumeutxo (`dumptxoutset`, `loadtxoutset`, `getchainstates`, background validation) |
| C-VAL-5 | relate headers-first sync and `assumevalid` to the code paths above |
| C-CONS-2 | explain buried deployments vs version-bits (BIP9) deployments in `src/consensus/params.h` |
| C-CONS-4 | say where chainwork is computed and used to pick the best chain |
| C-CPP-2 | say which functions need `cs_main` and why `ActivateBestChain` takes it in steps |
| C-CPP-4 | read `BlockValidationState` results and tell "invalid" from "we failed to process" |

**Prerequisites:** Stages 01, 13. **Estimated time:** 18 hours.

---

## Theory

### 1. The block index
Every header we accept gets a `CBlockIndex` (`src/chain.h`) in `BlockManager::m_block_index`.
`CChain` is a vector of pointers for the **active** chain only. `nStatus` records how far a block got:

| Flag | Meaning |
|------|---------|
| `BLOCK_VALID_TREE` | header valid and connects to a known parent |
| `BLOCK_VALID_TRANSACTIONS` | block data seen and `CheckBlock` passed |
| `BLOCK_VALID_CHAIN` | context checks passed, ancestors valid |
| `BLOCK_VALID_SCRIPTS` | fully connected, scripts verified |
| `BLOCK_HAVE_DATA` / `BLOCK_HAVE_UNDO` | `blk*.dat` / `rev*.dat` stored |
| `BLOCK_FAILED_VALID` | this block failed validation |
| `BLOCK_FAILED_CHILD` | 29.x: set on descendants of a failed block. **29.x → master:** documented as unused. |

`nChainWork` (sum of work from genesis, `GetBlockProof` in `src/chain.cpp`) decides the best chain.

### 2. The flow of a new block (C-VAL-1)
```
ChainstateManager::ProcessNewBlock
 ├─ CheckBlock                       (context-free: merkle root, size, coinbase first, CheckTransaction for each tx)
 ├─ AcceptBlock
 │   ├─ AcceptBlockHeader            (CheckBlockHeader, ContextualCheckBlockHeader: PoW target, time rules, version)
 │   ├─ ContextualCheckBlock         (BIP34 height in coinbase, witness commitment, locktime finality via MTP)
 │   └─ WriteBlockToDisk / store
 └─ ActivateBestChain                (loop: find most-work candidate, call ActivateBestChainStep)
     └─ ActivateBestChainStep
         ├─ DisconnectTip → DisconnectBlock  (uses undo data; txs go to a DisconnectedBlockTransactions pool)
         └─ ConnectTip    → ConnectBlock     (UTXO spends, amounts, sigop limits, script checks, subsidy)
     MaybeUpdateMempoolForReorg (re-add disconnected txs, then removeForReorg)
```
**Which rules live where:** context-free rules in `CheckBlock` (can be checked before we know the
parent); rules that need the parent (time, difficulty, height) in the `Contextual*` functions;
rules that need the UTXO set in `ConnectBlock` (`Consensus::CheckTxInputs` in `src/consensus/tx_verify.cpp`).

### 3. The UTXO set and its caches (C-VAL-2)
`CCoinsViewDB` (`src/txdb.h`, LevelDB in `chainstate/`) ← `CCoinsViewErrorCatcher` ← the big
`CCoinsViewCache` (sized by `-dbcache`) ← temporary `CCoinsViewCache`s per block in `ConnectBlock`.
Children write back to parents only on success, so a failed block leaves no trace. Flushing to disk
(`FlushStateToDisk`) happens when the cache is full, periodically, and on shutdown. Undo data
(`CBlockUndo`, `rev*.dat`) stores the spent coins of each block so `DisconnectBlock` can restore them.

### 4. Reorgs (C-VAL-3)
`invalidateblock <hash>` marks a block failed and makes the node reorg to the best remaining chain;
`reconsiderblock <hash>` clears the failure flags and lets `ActivateBestChain` choose again.
Disconnected transactions are re-submitted to the mempool if still valid (`MaybeUpdateMempoolForReorg`);
coinbase spends that become immature and txs that become non-final are removed (`removeForReorg`).

### 5. Soft-fork deployment (C-CONS-2)
- **Buried deployments** (`enum BuriedDeployment`: `DEPLOYMENT_HEIGHTINCB` (BIP34), `DEPLOYMENT_CLTV`,
  `DEPLOYMENT_DERSIG`, `DEPLOYMENT_CSV`, `DEPLOYMENT_SEGWIT`) are activated at fixed heights in
  `src/kernel/chainparams.cpp`. Burying (PR #16060 for CSV/segwit) removed the BIP9 state machine for
  them once they were deep in the chain.
- **Version-bits deployments** (`enum DeploymentPos`: `DEPLOYMENT_TESTDUMMY`, `DEPLOYMENT_TAPROOT`)
  keep BIP9 signalling logic in `src/versionbits.cpp` (Taproot used Speedy Trial with
  `min_activation_height`).

### 6. AssumeUTXO (C-VAL-4)
`dumptxoutset` writes a UTXO snapshot; `loadtxoutset` loads one whose hash matches the hard-coded
`m_assumeutxo_data` (regtest has entries at heights 110, 200 and 299). The node then has **two
chainstates**: the snapshot chainstate syncs to the tip and serves the wallet, while a background
chainstate validates from genesis to the snapshot height and checks the hash (`getchainstates`).
Read `doc/design/assumeutxo.md` and `test/functional/feature_assumeutxo.py`. Merged in pieces, e.g.
PR #27596 ("assumeutxo (2)") and #30214 (state representation).

### 7. History: where the old bugs are fixed now
| Bug | What happened | Where the protection lives |
|-----|---------------|-----------------------------|
| CVE-2010-5139 (value overflow, Aug 2010) | an output sum overflowed; ~184 billion BTC created | `CheckTransaction` range checks (`src/consensus/tx_check.cpp`), `MoneyRange` |
| BIP50 (Mar 2013 fork) | v0.8 (LevelDB) accepted a large block that v0.7 (BDB lock limits) could not → chain split | lesson: *implicit* limits of a dependency are consensus rules; BIP50 documents the event |
| CVE-2018-17144 | duplicate inputs check skipped in block validation → crash, possible inflation | duplicate-input check back in `CheckTransaction` (PR #14247) |

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | [Trace a block through the code](./exercises/01_trace_block_flow.md) | self-check vs `solutions/trace_answers.md` |
| 2 | [Reorg drill on regtest](./exercises/02_reorg_drill.md) | `./check_15.sh reorg` |
| 3 | [Write the reorg functional test](./exercises/03_feature_kisumu_reorg_mempool.py) | `./check_15.sh test` |
| 4 | [AssumeUTXO: read and run the test](./exercises/04_assumeutxo.md) | self-check |

---

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. Why is `CheckBlock` split from `ContextualCheckBlock`?
2. Where are UTXOs looked up and spent during block connection?
3. What do undo files contain and when are they used?
4. What happens to a tx from a disconnected block that spends a coinbase that is now immature?
5. How does the node decide which chain is best?
6. What does `invalidateblock` change in the block index?
7. What is the difference between a buried deployment and a BIP9 deployment?
8. What does the background chainstate do in assumeutxo, and what happens if the hash does not match?
9. Why is a failed `ConnectBlock` harmless to the UTXO set?
10. What lesson did the 2013 fork teach about consensus code?

## Review lens
- Files: `src/validation.{h,cpp}`, `src/chain.{h,cpp}`, `src/coins.{h,cpp}`, `src/txdb.{h,cpp}`,
  `src/node/blockstorage.{h,cpp}`, `src/consensus/*`, `src/versionbits.cpp`, `src/kernel/chainparams.cpp`.
- Tests: `feature_block.py` (huge consensus test), `mempool_reorg.py`, `rpc_invalidateblock.py`,
  `feature_assumeutxo.py`, `feature_dbcrash.py`, `src/test/validation_*_tests.cpp`, `coins_tests.cpp`,
  fuzz `coins_view`, `utxo_snapshot`.
- Invariants: no consensus change without explicit agreement; the UTXO set after connect+disconnect
  equals the original; a crash at any point leaves a recoverable state; `cs_main` held where required
  (`EXCLUSIVE_LOCKS_REQUIRED(cs_main)` annotations).
- Questions: Is this really behaviour-preserving? (Ask for a test that would fail if not.) Does it
  change *when* something is flushed or written? Does it change block acceptance for any input,
  including invalid ones, or error messages that P2P logic depends on?

## Proof-of-work output
Your reorg functional test and a written walk-through of `ActivateBestChainStep` in your own
words — a good basis for a PR Review Club answer when a validation PR comes up.
