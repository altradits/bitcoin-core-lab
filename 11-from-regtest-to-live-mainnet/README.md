# Stage 11: From Regtest to Signet to Your Own Pruned Mainnet Node

> Source checked: ports, prune minimum and wallet defaults against `v29.0` (`f490f5562d`):
> `src/chainparamsbase.cpp`, `src/kernel/chainparams.cpp`, `src/validation.h`
> (`MIN_DISK_SPACE_FOR_BLOCK_FILES`), `src/init.cpp`, `src/wallet/wallet.h` (`DEFAULT_WALLET_RBF`).

**No-Shortcuts Rule.** You write your own signet and mainnet `bitcoin.conf` from the requirements
below, you run the sync yourself, and you do the wallet safety drill by hand. The Go file in this
stage is yours too (`./lab.sh blank|check|solve 11`). The old ready-made config and wallet
ceremony are in [`solutions/`](./solutions/).

---

## Objectives

| ID | You can... |
|----|------------|
| C-VAL-5 | explain headers-first IBD, `assumevalid`, pruning, and read `getblockchaininfo` during sync |
| C-WALLET-4 | create an encrypted descriptor wallet, back it up, **prove** the backup restores, and build a watch-only wallet from public descriptors |
| C-TX-1 (applied) | estimate vsize for P2PKH/P2WPKH/P2TR transactions and choose fee strategies (batching, consolidation, RBF, CPFP) |

## Prerequisites
Stages 01–03 and 07. About 1 GB free for signet; ~16 GB for a pruned mainnet node. Estimated time: 6 hours plus sync time.

---

## Theory

### 1. The four networks
| Network | Flag | HRP | P2P / RPC port | Use |
|---------|------|-----|----------------|-----|
| regtest | `-regtest` | `bcrt` | 18444 / 18443 | your private sandbox |
| signet | `-signet` | `tb` | 38333 / 38332 | real global P2P, blocks signed by a known key (BIP325), free coins |
| testnet4 | `-testnet4` | `tb` | 48333 / 48332 | global PoW test network (BIP94) |
| mainnet | (none) | `bc` | 8333 / 8332 | real money |

You will fill the same table in Go from the source (Exercise 1), not from this README.

### 2. Initial block download (IBD)
Headers first (`getheaders`/`headers`), then blocks are downloaded in parallel from several peers
and connected in order. Signatures in blocks before the `assumevalid` block are not re-checked
(everything else — amounts, UTXOs, PoW — still is). `-prune=N` (N ≥ 550 MiB) deletes old block
and undo files once validated; the UTXO set (chainstate) is kept in full. Pruning is incompatible
with `-txindex` (`Prune mode is incompatible with -txindex.`). On an 8 GB M1 a `dbcache` of
1–2 GB speeds up IBD without swapping; drop it back after sync.

### 3. Wallet safety (descriptor wallets)
A descriptor wallet's keys come from one BIP32 seed, described by output descriptors
(`listdescriptors`). Public descriptors let a second wallet *watch* without spending. A backup is
only a backup after you have **restored it** somewhere else and seen the same addresses and
balance. `walletrbf` is already on by default (`DEFAULT_WALLET_RBF = true`), so wallet transactions
can always be fee-bumped.

### 4. Fees in practice
- Address type matters: per input ~148 vB (P2PKH) vs 68 vB (P2WPKH) vs 57.5 vB (P2TR key path).
- Many small UTXOs cost you later; consolidate when feerates are low.
- Batch payments into one tx; use RBF (`bumpfee`) for your own payments and CPFP for incoming ones (Stage 03).
- Withdrawing from a custodial Lightning wallet: withdraw in larger, fewer chunks; check that your
  node marks the receiving address `ismine` and `solvable` **before** sending.

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | Go: fill `AllBitcoinNetworks` and `EstimateTxVBytes` from the source (`sovereign_wallet_builder.go`) | `./lab.sh check 11` |
| 2 | [Write your own signet and mainnet `bitcoin.conf`](./exercises/01-write-your-confs.md) | `./check_confs.sh` |
| 3 | [Sync signet and read IBD](./exercises/02-sync-signet.md) | `./check_signet.sh` (reads your synced signet node) |
| 4 | [Wallet safety drill: encrypt, back up, restore, watch-only](./exercises/03-wallet-safety-drill.md) | `./check_wallet_drill.sh` |

---

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_11=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).
1. What does `assumevalid` skip, and what does it never skip?
2. Minimum prune target, and why can a pruned node not run `-txindex`?
3. Why must you restore a backup before trusting it?
4. What can a watch-only wallet built from public descriptors do and not do?
5. Estimate the vsize of a 3-input, 2-output P2WPKH transaction.
6. Why can a signet coin never be worth anything, and why is that useful?
7. Which `getblockchaininfo` fields tell you IBD is finished?

## Review lens
- Files: `src/node/blockstorage.cpp` (pruning), `src/validation.cpp` (`IsInitialBlockDownload`,
  `assumevalid` handling in `ConnectBlock`), `src/kernel/chainparams.cpp`, `src/wallet/rpc/backup.cpp`,
  `src/wallet/load.cpp`; tests `feature_pruning.py`, `feature_assumevalid.py`,
  `wallet_backup.py`, `wallet_descriptor.py`.
- Questions: Does the change affect what a pruned node can serve or rescan? Does it change a
  default (always a release-note item)? Could it make a backup silently incomplete?

## Proof-of-work output
A running signet node and a short public write-up (your own words) of your wallet safety drill —
without any keys, descriptors with private parts, or amounts you do not want public.
