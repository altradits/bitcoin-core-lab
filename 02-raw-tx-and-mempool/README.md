# Stage 02: Raw Transactions, Serialization by Hand, and Mempool Admission

> Source checked: Bitcoin Core `v29.0` (`f490f5562d`). All reject strings below were observed on a
> v29.0 regtest node while writing this stage.

**No-Shortcuts Rule.** From this stage on you own the environment: you write your own
`setup.sh`, decode transactions byte by byte on paper, and type every raw-transaction RPC.
Worksheets give goals and layered hints, never the finished command. Checkers inspect your node
and files. Reference answers are in [`solutions/`](./solutions/) — open them only after a check
passes or after **3 honest attempts**. Keep your command journal in
`my-work/02-raw-tx-and-mempool/journal.md`.

The old automation script (`raw_tx_mempool.sh`) now lives in
[`solutions/`](./solutions/raw_tx_mempool.sh) as the reference for Worksheet 3.

---

## Objectives

| ID | You can... |
|----|------------|
| C-TX-1 | decode a segwit transaction byte by byte; compute base size, total size, weight, vsize, txid and wtxid by hand (including byte order) |
| C-TX-2 | build, sign, test (`testmempoolaccept`) and broadcast a raw transaction with RPCs only, with exact fee arithmetic |
| C-SCRIPT-2 | explain P2WPKH spending vs legacy P2PKH, the DER signature + sighash byte, and what BIP143 commits to |
| C-MEMPOOL-1 | name the stages of `AcceptToMemoryPool` and sort any reject reason into consensus, policy or RPC guard |
| C-TX-3 (intro) | explain `nLockTime` finality (height vs time, BIP113 median-time-past) and observe `non-final` |

## Prerequisites
Stage 01: your own `bitcoin.conf` (with `txindex=1`, `fallbackfee`), your `node.sh`, and
`BTC_CLI` exported.

---

## Theory

### 1. Transaction serialization (BIP144 wire format)
```
version (4, LE)
[marker 0x00, flag 0x01]                 ← only if any input has witness data
vin count (CompactSize)
  prev txid (32, internal byte order) | prev vout (4, LE) | scriptSig len | scriptSig | nSequence (4, LE)
vout count (CompactSize)
  value (8, LE, satoshis) | scriptPubKey len | scriptPubKey
[witness: per input: item count | (len | item)*]
nLockTime (4, LE)
```
Code: `SerializeTransaction` / `UnserializeTransaction` in `src/primitives/transaction.h`;
CompactSize in `src/serialize.h`.

**Byte order.** Hashes are computed and stored as 32 raw bytes; RPCs and explorers print them
**reversed** (a historical convention from treating them as little-endian 256-bit integers,
`uint256::GetHex`). Every time you copy a txid into raw hex, reverse it.

**txid vs wtxid.** `txid = SHA256d(serialization without marker/flag/witness)`; `wtxid =
SHA256d(full serialization)`. Because the txid does not cover signatures, a third party cannot
change a segwit tx's txid by tweaking its signature (malleability fix, BIP141). This is what makes
chains of unconfirmed transactions — e.g. Lightning funding + commitment — safe.

### 2. Weight, vsize, feerate
`weight = base_size × 3 + total_size` (`GetTransactionWeight`, `src/consensus/validation.h`;
`WITNESS_SCALE_FACTOR = 4`). `vsize = ceil(weight / 4)`. In policy, "vsize" means
*sigops-adjusted* vsize (`GetVirtualTransactionSize`, `src/policy/policy.cpp`), which equals the
plain vsize for normal transactions. Feerate = fee / vsize (sat/vB). RPCs often use BTC/kvB:
1 sat/vB = 0.00001 BTC/kvB.

### 3. Legacy vs SegWit v0
| | Legacy P2PKH | SegWit v0 P2WPKH | SegWit v0 P2WSH |
|-|--------------|------------------|-----------------|
| scriptPubKey | `OP_DUP OP_HASH160 <20> OP_EQUALVERIFY OP_CHECKSIG` (25 B) | `OP_0 <20-byte HASH160(pubkey)>` (22 B) | `OP_0 <32-byte SHA256(script)>` (34 B) |
| signature lives in | scriptSig (counts ×4) | witness (counts ×1) | witness |
| sighash algorithm | legacy (`SigVersion::BASE`) | BIP143 (`SigVersion::WITNESS_V0`) | BIP143 |
| txid malleable by third parties | yes | no | no |

Both go through `VerifyScript` → `VerifyWitnessProgram` (`src/script/interpreter.cpp`).

### 4. Signatures and sighash types
An ECDSA signature in a witness is DER (`30 len 02 rlen R 02 slen S`) plus **one sighash byte**.
`SIGHASH_ALL (0x01)` commits to all inputs and outputs; `NONE (0x02)` to no outputs; `SINGLE (0x03)`
to the output with the same index; `| ANYONECANPAY (0x80)` commits to only this input. BIP143
also commits to the **amount** of the spent output, so a signer cannot be lied to about the fee
(legacy signers had to see whole previous transactions). Code: `SignatureHash` in
`src/script/interpreter.cpp`. Core grinds for low-R signatures, so they are usually 71 bytes
(`CKey::Sign`, `src/key.cpp`).

### 5. Consensus vs policy vs RPC guards
- **Consensus**: rules every node applies to blocks. Breaking one makes a block invalid
  (`src/consensus/`, `CheckTxInputs`, `IsFinalTx`, script verification with consensus flags).
- **Policy (standardness)**: what *your* node relays and mines by default (`src/policy/`:
  `IsStandardTx`, dust, `MAX_STANDARD_TX_WEIGHT`, min relay feerate, mempool limits, RBF rules).
  A valid block may contain a non-standard tx.
- **RPC guards**: client-safety checks such as `maxfeerate` in `sendrawtransaction`
  (`BroadcastTransaction`, `src/node/transaction.cpp`) — they protect *you* and are not rules of
  the network.

### 6. How the mempool admits a transaction (`src/validation.cpp`)
`AcceptToMemoryPool` → `MemPoolAccept::AcceptSingleTransaction` →
`PreChecks` (standardness, finality, inputs exist, `CheckTxInputs`, fees, limits) →
`ReplacementChecks` (if it conflicts; Stage 03) → `PolicyScriptChecks` (standard script flags) →
`ConsensusScriptChecks` (consensus flags, fills the script cache) → submit.
`testmempoolaccept` runs this without adding the tx.

### 7. Absolute timelocks (intro to C-TX-3)
`nLockTime` < 500,000,000 is a block height, otherwise a UNIX time. A tx is final if
`nLockTime < (height or time)` of the block it would be in, or if every input has
`nSequence = 0xffffffff` (`IsFinalTx`, `src/consensus/tx_verify.cpp`). The mempool tests against
tip height + 1 (`CheckFinalTxAtTip`). Time locks compare with the **median time past** of the
previous 11 blocks (BIP113), not the block's own timestamp. Relative locks (BIP68/112) come in
Stage 06.

---

## Exercises (in order)

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | [`exercises/01-your-own-setup.md`](./exercises/01-your-own-setup.md) — your `setup.sh` | `./02-raw-tx-and-mempool/check_setup.sh` |
| 2 | [`exercises/02-decode-a-tx-by-hand.md`](./exercises/02-decode-a-tx-by-hand.md) — bytes, weight, txid on paper | `./02-raw-tx-and-mempool/check_decode.sh` (offline) |
| 3 | [`exercises/03-build-sign-broadcast.md`](./exercises/03-build-sign-broadcast.md) — your raw tx, exact fee | `./02-raw-tx-and-mempool/check_raw_tx.sh` |
| 4 | [`exercises/04-policy-vs-consensus.md`](./exercises/04-policy-vs-consensus.md) — five rejections, classified | `./02-raw-tx-and-mempool/check_policy.sh` |

Copy [`exercises/answers.env.template`](./exercises/answers.env.template) to
`my-work/02-raw-tx-and-mempool/answers.env`.

---

## Checkpoint

```bash
./lab.sh check 02
```

Runs: ./check_setup.sh, ./check_decode.sh, ./check_raw_tx.sh, ./check_policy.sh. Each prints PASS/FAIL with a reason, never the answer. Start your own regtest node first; the checkers read its state and your `answers.env`.
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. A tx has base size 113 and total size 222. Weight? vsize?
2. Why does the 32-byte prev-txid in raw hex look different from the txid `listunspent` prints?
3. What exactly is hashed to get the txid of a segwit tx, and why does that matter for Lightning?
4. Where does the fee of a transaction appear in its serialization?
5. What is the P2WPKH dust threshold at the default dust relay feerate, and how is it computed?
6. Classify: `bad-txns-in-belowout`, `dust`, `non-final`, `version`, `max-fee-exceeded`.
7. What does `SIGHASH_SINGLE | ANYONECANPAY` sign?
8. Why did BIP143 add the input amount to the signature hash?
9. A tx has `nLockTime = 1000` and one input with `nSequence = 0xfffffffd`. At which chain tip does the mempool first accept it?
10. Name the `MemPoolAccept` methods a transaction passes through, in order.

## Review lens
For PRs touching transaction serialization, RPCs that build transactions, or mempool admission:
- **Files:** `src/primitives/transaction.{h,cpp}`, `src/core_read.cpp`/`core_write.cpp`
  (hex/JSON), `src/rpc/rawtransaction.cpp`, `src/rpc/rawtransaction_util.cpp`,
  `src/rpc/mempool.cpp` (`testmempoolaccept`, `getmempoolentry`), `src/node/transaction.cpp`,
  `src/validation.cpp` (`MemPoolAccept`), `src/policy/policy.{h,cpp}`.
- **Invariants to ask about:** Does the change alter what is *consensus* (needs a soft fork — almost
  never acceptable in a normal PR) or only *policy*? Does a policy change open a DoS vector or a
  pinning vector? Does serialization stay byte-for-byte compatible (old nodes, PSBT, wallets)? Are
  fee/amount conversions done in integer satoshis (`CAmount`) and never in floating point?
- **Tests to read and run:** `test/functional/mempool_accept.py`, `rpc_rawtransaction.py`,
  `mempool_dust.py`, `feature_segwit.py`; unit tests `src/test/transaction_tests.cpp`,
  `src/test/sighash_tests.cpp`, data in `src/test/data/tx_valid.json`.
- **Master note:** on `master` (cluster mempool) the admission flow gains cluster-limit checks
  (`too-large-cluster`) and the default `-minrelaytxfee`/`-incrementalrelayfee` is 0.1 sat/vB
  (100 sat/kvB) instead of 1 sat/vB on 29.x. Your 29.x node's numbers are the 29.x ones.

## Proof-of-work output
A public write-up in your own words: "Decoding a segwit transaction by hand" — your annotated
byte split, your weight and txid calculations, and what `decoderawtransaction` confirmed.

## Next
Stage 03 ([`../03-rbf-and-cpfp/README.md`](../03-rbf-and-cpfp/README.md)): replace and bump the
transactions you can now build.
