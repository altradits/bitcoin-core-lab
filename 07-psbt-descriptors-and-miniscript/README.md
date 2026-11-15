# Stage 07: Descriptors, BIP32 Paths, Miniscript and the PSBT Roles

> **No shortcuts.** In this stage you write the Go code that computes descriptor
> checksums, parses BIP32 paths and parses PSBTs, and you type every `bitcoin-cli`
> command of an air-gapped PSBT spend yourself. Reference answers are in
> [`solutions/`](./solutions/). Open them only after a check passes or after 3 honest attempts.

Source checked: `bitcoin/bitcoin` 29.x at `f490f5562d`, and every path below also exists on `master` (`e75b76b12c`).

## Objectives

| ID | You can... |
| :-- | :-- |
| **C-WALLET-1** | Compute and verify a BIP380 descriptor checksum by hand, and parse and format BIP32 paths the way Core does (`'` and `h`, the 2^31 hardened bit). |
| **C-WALLET-3** | Write a small miniscript policy (`wsh(and_v(v:pk(K),older(N)))`), check it with `getdescriptorinfo`, and derive its address. |
| **C-PSBT-1** | Name the six BIP174 roles (Creator, Updater, Signer, Combiner, Finalizer, Extractor), match each to the RPC that plays it, and parse a PSBT's key-value maps. |
| **C-PSBT-2** | Run a watch-only coordinator plus a key-holding signer (the air-gap pattern in `doc/psbt.md`), and say what PSBTv2 (BIP370) changes. |

## Prerequisites
- Stage 02 (raw transactions, txid vs wtxid) and Stage 10 Lesson 2 (CompactSize). You can do Stage 10 first.
- A regtest `bitcoind` that **you** start, with a funded wallet (you did this in Stages 01–02).
- Offline reading: `bip-0032`, `bip-0174`, `bip-0370`, `bip-0379`, `bip-0380` in `~/bitcoin-references/bips/`, plus [`doc/psbt.md`](https://github.com/bitcoin/bitcoin/blob/master/doc/psbt.md) and [`doc/descriptors.md`](https://github.com/bitcoin/bitcoin/blob/master/doc/descriptors.md).

## Theory

### 1. Descriptors and their checksum
A descriptor such as `wpkh([d34db33f/84h/1h/0h]tpub.../0/*)#xxxxxxxx` describes a set of output scripts. The 8-character suffix is a checksum computed by `DescriptorChecksum` in [`src/script/descriptor.cpp`](https://github.com/bitcoin/bitcoin/blob/master/src/script/descriptor.cpp). Each character's position in a 96-symbol charset is split into two parts: the low 5 bits, and a "group" number (0–2). Group numbers are packed three at a time. The polynomial (`PolyMod`) is a BCH code over 32 symbols, the same idea as bech32 but with a longer checksum. `CheckChecksum` gives the errors you will reproduce: `Multiple '#' symbols`, `Missing checksum`, `Expected 8 character checksum, not N characters`, `Provided checksum '…' does not match computed checksum '…'`.

### 2. BIP32 paths
A child index is a `uint32`. Indices `>= 2^31` are *hardened*, so `84h` means `84 | 0x80000000`. `ParseKeyPathNum` (descriptor.cpp) accepts `'` or `h`, rejects values above `0x7FFFFFFF` ("Key path value N is out of range"), and keeps note of which marker you used so it can print the same one back. `FormatHDKeypath` in [`src/util/bip32.cpp`](https://github.com/bitcoin/bitcoin/blob/master/src/util/bip32.cpp) prints `h` unless asked for apostrophes. BIP84 `m/84h/1h/0h` is purpose / coin type (1 = test networks) / account. Then `0/*` is the receive chain and `1/*` is change.

### 3. Miniscript, in brief
Miniscript ([`src/script/miniscript.h`](https://github.com/bitcoin/bitcoin/blob/master/src/script/miniscript.h), BIP379) is a structured subset of Script that a wallet can analyse: what satisfies it, at what cost, and whether it is malleable. Fragments have *types*. For example `pk(K)` is type B (pushes a boolean), the wrapper `v:` turns it into V (verify, pushes nothing), and `and_v(V,B)` gives B. So `and_v(v:pk(K),older(144))` means "K signs AND the input is at least 144 blocks old (BIP68 relative lock)". Core uses miniscript inside `wsh()` and `tr()` descriptors. The reference test is [`test/functional/wallet_miniscript.py`](https://github.com/bitcoin/bitcoin/blob/master/test/functional/wallet_miniscript.py).

### 4. PSBT structure and roles (BIP174)
```
"psbt" 0xff | global map | input map × n_in | output map × n_out
map = (<CompactSize keylen> <key = type || keydata> <CompactSize vallen> <value>)* 0x00
```
The global map must hold `PSBT_GLOBAL_UNSIGNED_TX` (type `0x00`, key exactly 1 byte). That transaction is in **non-witness** serialization and has **empty** scriptSigs, because signatures live in the input maps. All constants are in [`src/psbt.h`](https://github.com/bitcoin/bitcoin/blob/master/src/psbt.h). The error strings ("Duplicate Key…", "Separator is missing…", "Unsigned tx does not have empty scriptSigs and scriptWitnesses.") are in the `Unserialize` methods there, plus "extra data after PSBT" in `src/psbt.cpp`.

| Role | What it does | Core RPC(s) |
| :-- | :-- | :-- |
| Creator | builds the unsigned tx | `createpsbt`, `walletcreatefundedpsbt`, `converttopsbt` |
| Updater | adds UTXOs, scripts, BIP32 paths | `utxoupdatepsbt`, `descriptorprocesspsbt`, `walletprocesspsbt` with `sign=false`; `walletcreatefundedpsbt` also updates |
| Signer | adds partial signatures | `walletprocesspsbt`, `descriptorprocesspsbt` |
| Combiner | merges PSBTs of the same tx | `combinepsbt` (`joinpsbts` merges *different* txs, which is not the Combiner role) |
| Finalizer | builds final scriptSig/witness, drops partial data | `finalizepsbt` (and `walletprocesspsbt` finalizes by default) |
| Extractor | produces the network tx | `finalizepsbt` with `extract=true` (default) |

`analyzepsbt` reports the `next` role. Its logic is `AnalyzePSBT` in [`src/node/psbt.cpp`](https://github.com/bitcoin/bitcoin/blob/master/src/node/psbt.cpp). You write a simplified version.

**PSBTv2 (BIP370)** removes the global unsigned tx and stores per-input/per-output fields instead, so inputs and outputs can be added after creation. Read `bip-0370.mediawiki`. On `master`, check yourself whether Core can parse v2 (`git grep PSBT_GLOBAL_VERSION master -- src/psbt.h`). The lab does not claim either way: **UNVERIFIED**.

## Exercises

### Exercise 1–3 (Go): `./lab.sh blank 07`, then write `psbt_descriptors.go`
Your working file starts as a skeleton: each function has a precise spec comment and `// TODO`.
```
./lab.sh blank 07          # copies exercises/psbt_descriptors.go to the stage root (backs up yours first)
./lab.sh check 07          # = go test ./... in this directory
go test -run TestA ./...   # Part A only (checksums), then TestB (paths), then TestC (PSBT)
```
Tests use BIP380 and BIP174 test vectors plus checksums named in `src/test/descriptor_tests.cpp`. All of them fail until you write the code.

<details><summary>Hint 1 (concept)</summary>For the checksum, keep two accumulators: the polynomial state <code>c</code> and the group accumulator <code>cls</code>. For PSBT, write a <code>readMap</code> helper first. The global map, input maps and output maps all use the same encoding.</details>
<details><summary>Hint 2 (where)</summary><code>DescriptorChecksum</code> is about 30 lines in <code>src/script/descriptor.cpp</code>. Translate it line by line. For PSBT, follow <code>PartiallySignedTransaction::Unserialize</code> in <code>src/psbt.h</code> from the magic-byte check down to the outputs loop.</details>

When the tests pass, run your parser on a real PSBT you made in Exercise 4: `go run ./cmd/psbtinspect "<psbt>"`. Compare it with `bitcoin-cli -regtest decodepsbt` and `analyzepsbt`.

### Exercise 4 (CLI worksheet): an air-gapped spend you type yourself
Save every command you type in `my-work/07-psbt-descriptors-and-miniscript/journal.md`. Use exactly these wallet names: `w07_signer` (holds keys) and `w07_watch` (watch-only).

1. Create `w07_signer` as a normal descriptor wallet. Create `w07_watch` so that it **cannot** hold private keys. Read `help createwallet` and find the argument.
2. Export the signer's **public** descriptors (`listdescriptors`, read its `private` argument). Pick the external BIP84 `wpkh` one. Check its checksum with `getdescriptorinfo` and save it to `my-work/07-psbt-descriptors-and-miniscript/descriptor.txt`.
3. Import the signer's `wpkh` receive **and** change descriptors into `w07_watch` (`importdescriptors`). Mark them active and set `internal` correctly for change.
4. Get a receive address from `w07_watch`. Fund it from your mining wallet and confirm the funding.
5. **Creator + Updater:** in `w07_watch`, fund a PSBT that pays 0.25 BTC to an address from another wallet (`walletcreatefundedpsbt`). Save the base64 to `my-work/07-psbt-descriptors-and-miniscript/psbt_created.txt`. Run `decodepsbt` and `analyzepsbt` on it, and note in your journal which input fields are present.
6. **Signer (+ Finalizer):** move the PSBT "across the air gap" (copy the text) and process it with `w07_signer` (`walletprocesspsbt`). Save the result to `my-work/07-psbt-descriptors-and-miniscript/psbt_processed.txt`. Run `analyzepsbt` again.
7. **Combiner (practice):** process the *original* PSBT a second time with `sign=false`, then `combinepsbt` both. Write in your journal why combining is safe: the combined PSBT must commit to the same unsigned tx.
8. **Finalizer + Extractor:** `finalizepsbt`, then broadcast the hex (`sendrawtransaction`). Mine one block and save the txid to `my-work/07-psbt-descriptors-and-miniscript/final_txid.txt`.
9. **Miniscript:** take one pubkey from `w07_signer` (`getaddressinfo` → `pubkey`). Write a `wsh()` descriptor that needs that key **and** a 144-block relative timelock. Add its checksum with `getdescriptorinfo`, derive its regtest address with `deriveaddresses`, and save both to `my-work/07-psbt-descriptors-and-miniscript/miniscript_desc.txt` / `miniscript_address.txt`.

<details><summary>Hint 1 (concept)</summary>The watch-only wallet can create and update a PSBT because it knows the scripts and UTXOs. It cannot sign because it has no keys. Signing happens only where the keys are.</details>
<details><summary>Hint 2 (which RPC and arguments)</summary>Read <code>help walletcreatefundedpsbt</code>: inputs can be <code>[]</code>, so the wallet picks coins. Outputs are an array of <code>{"address": amount}</code>. For miniscript, read the <code>and_v</code>, <code>v:</code> and <code>older</code> fragments in <code>bip-0379.md</code>.</details>

Check your outcome:
```
./07-psbt-descriptors-and-miniscript/check_psbt_flow.sh
```
The checker inspects your node's state and your saved files. It never prints the commands. The full reference walkthrough is in [`solutions/psbt_flow_reference.md`](./solutions/psbt_flow_reference.md).

## Self-check quiz (answers: [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. Why does the descriptor checksum charset put hex digits and `()[],'/*` in the first group of 32?
2. What is the numeric value of `0h`? Of `2147483647h`? Why is `2147483648` (unhardened) invalid in a path?
3. Why must the unsigned tx inside a PSBT have empty scriptSigs, and why is it serialized without witness?
4. A PSBT input has a partial signature but no final scriptWitness. What does `analyzepsbt` say next, and when could Core's answer differ from your `NextRole`?
5. `combinepsbt` and `joinpsbts`: which one is the BIP174 Combiner and what does the other do?
6. Why does a hardware signer want `PSBT_IN_WITNESS_UTXO` (or the full previous tx) before it signs?
7. In `and_v(v:pk(K),older(144))`, what does the `v:` wrapper do to the script, and what does `older(144)` turn into on-chain?
8. What attack does a duplicate key in a PSBT map enable if a parser silently keeps "the last one"?

## Review lens: reading a wallet/PSBT PR
- **Files:** `src/psbt.h`, `src/psbt.cpp`, `src/node/psbt.cpp`, `src/script/descriptor.cpp`, `src/script/miniscript.h`, `src/wallet/rpc/spend.cpp`, `src/rpc/rawtransaction.cpp`.
- **Tests to run and read:** `test/functional/rpc_psbt.py` (and its vectors in `test/functional/data/rpc_psbt.json`), `test/functional/wallet_miniscript.py`, `test/functional/wallet_descriptor.py`, `src/test/descriptor_tests.cpp`, the fuzz target `src/test/fuzz/psbt.cpp`.
- **Invariants to ask about:** Does a new PSBT field reject a wrong key length and duplicate keys? Does it round-trip (serialize → parse → equal)? Does `Merge` (the Combiner) refuse PSBTs for a different unsigned tx? Do descriptor changes keep `ToString()` round-trip and checksum stability? Is a new miniscript fragment's type and malleability property tested?
- **Question to ask yourself:** "If an attacker controls the coordinator, what can they make this signer believe?"

## Proof of work
- A passing `./lab.sh check 07` run on code **you** wrote (paste the output in your journal).
- A short gist in your own words: "The six PSBT roles, mapped to the RPCs I typed." Include your miniscript descriptor (public keys only).
