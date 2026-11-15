# Stage 16: Script, Taproot & libsecp256k1 — Reading the Real C++ Interpreter

> Source checked: `/Users/mac/bitcoin` at `f490f5562d Merge bitcoin/bitcoin#32252: [29.x] doc: minor rel notes changes`
> (tag `v29.0`, detached HEAD). Where `master` differs, this README says so; local `master` was at
> `e75b76b12c Merge bitcoin/bitcoin#35261: guix: disable LTO in GCC` when checked.
> Every file, function and constant named below was found with `grep` in the 29.x tree **and**
> re-checked on `master` with `git -C /Users/mac/bitcoin grep <pattern> master`. Anything that
> could not be verified is marked **UNVERIFIED**.
>
> **29.x vs master, for this stage.** The interpreter logic you study here is the same on both. Differences:
> 1. On `master` the flags are no longer a plain `unsigned int`: they are a type-safe
>    `script_verify_flags` built from `enum class script_verify_flag_name` (PR #32998 *Bump SCRIPT_VERIFY
>    flags to 64 bit*, merge `d735e2e9b3`). The flag *names* and meanings are unchanged. Read
>    `git -C /Users/mac/bitcoin show master:src/script/interpreter.h`.
> 2. `MAX_OP_RETURN_RELAY` is 83 on 29.x and uncapped on `master` (see section 6).
> 3. MuSig2 (`src/musig.{h,cpp}`, `musig()` descriptors) exists only on `master` (section 7).
> 4. Many `Span` parameters became `std::span` on `master`. Search by function name, not by full signature.
> You run the regtest exercises with the 29.x binaries you already built; you review against `master`.

**Estimated time:** 18 hours (the `CURRICULUM.md` budget), plus 4–6 h if you do every stretch task.

**The No-Shortcuts Rule applies.** Every exercise is a worksheet. You type every command and
write every line. Hints come in layers and never contain the full answer. Reference solutions
live in [`solutions/`](./solutions/); open them only after a checker passes or after three
honest attempts. Save the commands you type in `my-work/16-script-taproot-and-libsecp256k1/journal.md`.

---

## Objectives (competency IDs)

| ID (from `CURRICULUM.md`) | In this stage you can... |
|----|------------|
| `C-SCRIPT-1` Interpreter | Walk through `EvalScript` and `VerifyScript` in `src/script/interpreter.cpp` and say where each output type (P2PKH, P2SH, P2WPKH, P2WSH, P2TR) branches. |
| `C-SCRIPT-2` SegWit v0 | Trace a P2WPKH/P2WSH spend and explain what the BIP143 sighash commits to (compared with legacy). |
| `C-SCRIPT-3` Taproot | Build a taproot output with a script tree on regtest (descriptors + PSBT), spend it by the key path and by the script path, and explain control blocks, the annex, `OP_SUCCESSx` and `OP_CHECKSIGADD`. |
| `C-SCRIPT-4` Flags & standardness | Explain why `SCRIPT_VERIFY_*` flags exist, and tell `MANDATORY_SCRIPT_VERIFY_FLAGS` (consensus) from `STANDARD_SCRIPT_VERIFY_FLAGS` and `src/policy/policy.cpp` (policy). |
| `C-CRYPTO-2` Curves | Explain the secp256k1 group, private/public keys, and how ECDSA signing and verification work, at reviewer level. |
| `C-CRYPTO-3` Schnorr | Compute BIP340/BIP341 tagged hashes (TapLeaf, TapBranch, TapTweak, TapSighash) by hand and match Core's vectors; explain x-only keys and key tweaking. (This also revisits `C-CRYPTO-1` from Stage 10.) |
| `C-CRYPTO-4` MuSig2 | Explain BIP327 key aggregation, the two signing rounds and the nonce-reuse danger, and where MuSig2 lives in Core (master only). |
| `C-CRYPTO-5` libsecp256k1 | Explain why `src/secp256k1` is a subtree, what constant-time code means, and how review there differs from review in `src/`. |
| `C-CONS-2` Soft-fork history | Map each script flag to its soft fork and activation method (`GetBlockScriptFlags`). |
| `C-TX-3` Timelocks | (Stretch in 16.3) Spend a taproot leaf guarded by `older(n)`. |

## Prerequisites

- Stage 06 (you built a P2WSH HTLC and saw `OP_CHECKSEQUENCEVERIFY` fail and pass).
- Stage 07 (descriptors and PSBT: `walletcreatefundedpsbt`, `walletprocesspsbt`, `finalizepsbt`).
- Stage 10 (your Go `TaggedHash`, `CompactSize` and toy Script VM). This stage replaces your toy
  with the real interpreter.
- A built `bitcoind`, `bitcoin-cli` and `test_bitcoin` in `/Users/mac/bitcoin/build/bin/`
  (they are already there from your earlier CMake build). **Do not rebuild for this stage.**
- Only one `bitcoind` at a time on your 8 GB M1. Run `./lab.sh rest` before starting one.

---

## Theory

### 1. Where script validation is called from

Script is checked in two places, with two different flag sets:

| Caller | File / function | Flags used |
|--------|-----------------|------------|
| Mempool (policy) | `MemPoolAccept::PolicyScriptChecks` in `src/validation.cpp` | `STANDARD_SCRIPT_VERIFY_FLAGS` |
| Mempool (consensus re-check) | `MemPoolAccept::ConsensusScriptChecks` | flags from `GetBlockScriptFlags` for the tip |
| Blocks | `Chainstate::ConnectBlock` → `CheckInputScripts` | `GetBlockScriptFlags(*pindex, ...)` |

Both end in `CheckInputScripts`, which (through the script-check machinery) calls `VerifyScript`.
Read the comment in `ConsensusScriptChecks` that says *"BUG! PLEASE REPORT THIS!"*: if a tx passes the
strict standard flags but fails the looser consensus flags, something is deeply wrong.

### 2. `VerifyScript` → `EvalScript` → `VerifyWitnessProgram`

Open `src/script/interpreter.cpp` and find these functions (search, do not trust line numbers):

- `bool VerifyScript(const CScript& scriptSig, const CScript& scriptPubKey, const CScriptWitness* witness, unsigned int flags, const BaseSignatureChecker& checker, ScriptError* serror)`
  1. Runs `scriptSig` with `EvalScript` (`SigVersion::BASE`).
  2. Runs `scriptPubKey` on the resulting stack.
  3. If `SCRIPT_VERIFY_WITNESS` and the scriptPubKey is a witness program, calls `VerifyWitnessProgram`.
  4. If `SCRIPT_VERIFY_P2SH` and it is P2SH, re-evaluates the redeem script (and P2SH-wrapped witness).
  5. Applies `SCRIPT_VERIFY_CLEANSTACK` and rejects witness data on non-witness spends (`SCRIPT_ERR_WITNESS_UNEXPECTED`).
- `bool EvalScript(...)` — the opcode loop: `switch (opcode)` over every opcode, the `vfExec`
  condition stack (`ConditionStack`), `MAX_OPS_PER_SCRIPT`, the stack size limit, and the
  `OP_CHECKSIG` family. In tapscript, `OP_CHECKSIG` goes through `EvalChecksigTapscript`, which charges
  `VALIDATION_WEIGHT_PER_SIGOP_PASSED` (50) against a per-input budget (`m_validation_weight_left`).
- `static bool VerifyWitnessProgram(...)` — branches on witness version and program size:
  - v0, 20 bytes → P2WPKH (builds `OP_DUP OP_HASH160 <program> OP_EQUALVERIFY OP_CHECKSIG`).
  - v0, 32 bytes → P2WSH (checks `SHA256(witnessScript) == program`).
  - v1, 32 bytes, not P2SH-wrapped → **Taproot** (only if `SCRIPT_VERIFY_TAPROOT`).
  - `CScript::IsPayToAnchor(...)` → P2A, returns true.
  - anything else → succeeds for future soft forks, unless `SCRIPT_VERIFY_DISCOURAGE_UPGRADABLE_WITNESS_PROGRAM`.
- `static bool ExecuteWitnessScript(...)` — in `SigVersion::TAPSCRIPT` it first scans for
  `OP_SUCCESSx` (`IsOpSuccess` in `src/script/script.cpp`); if one is present the script **succeeds
  immediately** (unless `SCRIPT_VERIFY_DISCOURAGE_OP_SUCCESS`).

### 3. Why flags exist: soft-fork layering

A soft fork can only *tighten* rules. Each tightening becomes a flag bit in
`src/script/interpreter.h` (`SCRIPT_VERIFY_P2SH = (1U << 0)` … `SCRIPT_VERIFY_DISCOURAGE_UPGRADABLE_PUBKEYTYPE = (1U << 20)`).
Old blocks are validated with the flags that were active at their height, so the history of the
chain still validates. Read `GetBlockScriptFlags` in `src/validation.cpp`:

- `P2SH | WITNESS | TAPROOT` are always on, except for the blocks listed in
  `consensus.script_flag_exceptions` (`src/kernel/chainparams.cpp`: one BIP16 exception and one
  Taproot exception on mainnet).
- `DERSIG`, `CHECKLOCKTIMEVERIFY`, `CHECKSEQUENCEVERIFY` and `NULLDUMMY` are turned on by
  `DeploymentActiveAt(...)`.

In `src/policy/policy.h`:

- `MANDATORY_SCRIPT_VERIFY_FLAGS` = the consensus flags (P2SH, DERSIG, NULLDUMMY, CLTV, CSV, WITNESS, TAPROOT).
- `STANDARD_SCRIPT_VERIFY_FLAGS` = mandatory **plus** policy-only flags such as `MINIMALDATA`,
  `CLEANSTACK`, `NULLFAIL`, `LOW_S`, `DISCOURAGE_UPGRADABLE_WITNESS_PROGRAM`,
  `DISCOURAGE_UPGRADABLE_TAPROOT_VERSION`, `DISCOURAGE_OP_SUCCESS`, `DISCOURAGE_UPGRADABLE_PUBKEYTYPE`.

The `DISCOURAGE_*` flags are how Core keeps upgrade hooks (unknown witness versions, unknown leaf
versions, `OP_SUCCESSx`, unknown pubkey types) **valid by consensus** but **not relayed** — so nobody
can build on them before a future soft fork gives them meaning.

### 4. Three signature hashes

| SigVersion | Function | Spec | Key properties |
|-----------|----------|------|----------------|
| `BASE` | `SignatureHash` (legacy branch) | original | Quadratic hashing; `FindAndDelete` on the scriptCode; `SIGHASH_SINGLE` bug (returns `uint256::ONE` when `nIn >= vout.size()`). Search for `ONE` in `SignatureHash`. |
| `WITNESS_V0` | `SignatureHash` (BIP143 branch, uses `PrecomputedTransactionData`) | BIP143 | Commits to the **amount** of the input; `hashPrevouts`, `hashSequence`, `hashOutputs` are cached → linear hashing. |
| `TAPROOT` / `TAPSCRIPT` | `SignatureHashSchnorr` | BIP341 / BIP342 | Starts with `HASHER_TAPSIGHASH` (tag "TapSighash") and `EPOCH = 0`; commits to **all** input amounts and **all** spent scriptPubKeys, the annex hash if present, and for script path the tapleaf hash and `codeseparator_pos`. `SIGHASH_DEFAULT` (0x00) is new. |

Why commit to all amounts and scriptPubKeys? So an offline signer (hardware wallet, PSBT) cannot
be lied to about the fee or about whether an input is its own. Read the `PrecomputedTransactionData`
struct in `interpreter.h` and PR #27122 (see Review lens).

### 5. Taproot in one page

- Output: `OP_1 <32-byte x-only Q>`. `Q = P + t·G`, `t = hashTapTweak(P || merkle_root)` (no tree:
  `t = hashTapTweak(P)`). In Core: `XOnlyPubKey::ComputeTapTweakHash` and `CheckTapTweak` (`src/pubkey.h`).
- **Key path:** witness = `[sig]` (64 bytes, or 65 with an explicit sighash byte). Checked by
  `checker.CheckSchnorrSignature(stack.front(), program, SigVersion::TAPROOT, ...)`.
- **Script path:** witness = `[inputs..., script, control_block]` (+ optional annex last).
  - Control block = 1 byte (`leaf_version | parity`) + 32-byte internal key P + 32·k merkle path.
    Size limits: `TAPROOT_CONTROL_BASE_SIZE = 33`, `TAPROOT_CONTROL_NODE_SIZE = 32`,
    `TAPROOT_CONTROL_MAX_NODE_COUNT = 128` (`interpreter.h`).
  - Leaf hash: `ComputeTapleafHash(control[0] & TAPROOT_LEAF_MASK, script)` = `hashTapLeaf(v || compact_size(len) || script)`.
  - Path: `ComputeTaprootMerkleRoot` folds `ComputeTapbranchHash(k, node)`, which **sorts** the two
    children lexicographically before hashing — so the control block does not need left/right bits.
  - `VerifyTaprootCommitment` recomputes Q from P and the root and checks parity.
  - Leaf version `TAPROOT_LEAF_TAPSCRIPT = 0xc0` → run as tapscript (BIP342). Unknown leaf versions
    succeed (upgrade hook), discouraged by policy.
- **Annex:** if there are ≥ 2 witness elements and the last starts with `ANNEX_TAG = 0x50`, it is
  removed and its hash committed in the sighash. Consensus-valid, **non-standard**
  (`IsWitnessStandard` in `src/policy/policy.cpp`: *"Annexes are nonstandard as long as no semantics are defined for them."*).
- **OP_SUCCESSx:** opcodes listed in `IsOpSuccess` (80, 98, 126–129, 131–134, 137–138, 141–142,
  149–153, 187–254). Present anywhere in a tapscript → script succeeds. This is the main soft-fork
  hook for new opcodes.
- **Tapscript changes vs legacy:** no `OP_CHECKMULTISIG` (use `OP_CHECKSIGADD`), `MINIMALIF` is
  consensus, sigops are budgeted by witness size rather than counted per block.

### 6. Standardness vs consensus for scripts (`src/policy/policy.cpp`)

| Function | What it rejects (policy only) |
|---------|------------------------------|
| `IsStandard(scriptPubKey, max_datacarrier_bytes, whichType)` | Unknown output types, bare multisig over 3 keys, oversized `OP_RETURN`. |
| `IsStandardTx(...)` | Version outside `TX_MAX_STANDARD_VERSION` (3), weight over `MAX_STANDARD_TX_WEIGHT`, big scriptSigs (`MAX_STANDARD_SCRIPTSIG_SIZE`), non-push scriptSigs, dust (`MAX_DUST_OUTPUTS_PER_TX`), multiple `OP_RETURN`s. |
| `AreInputsStandard(tx, mapInputs)` | Spending non-standard outputs; P2SH redeem scripts with too many sigops. |
| `IsWitnessStandard(tx, mapInputs)` | P2WSH: `MAX_STANDARD_P2WSH_SCRIPT_SIZE` (3600), `MAX_STANDARD_P2WSH_STACK_ITEMS` (100), `MAX_STANDARD_P2WSH_STACK_ITEM_SIZE` (80). Taproot: annex present, tapscript stack items over `MAX_STANDARD_TAPSCRIPT_STACK_ITEM_SIZE` (80). |

`MAX_OP_RETURN_RELAY` is `83` at v29.0; on `master` it is `MAX_STANDARD_TX_WEIGHT / WITNESS_SCALE_FACTOR`
(commit `9f36962b07 policy: uncap datacarrier by default`). This is a good example of policy moving
while consensus stays still.

### 7a. The curve and ECDSA in five lines (`C-CRYPTO-2`)

- secp256k1 is the curve y² = x³ + 7 over the prime field p = 2²⁵⁶ − 2³² − 977, with generator G of prime order n.
- Private key: integer d in [1, n−1]. Public key: P = d·G (33-byte compressed: 0x02/0x03 + x).
- ECDSA sign(m): pick secret nonce k, R = k·G, r = R.x mod n, s = k⁻¹(z + r·d) mod n. Verify: R' = (z/s)·G + (r/s)·P, check R'.x = r.
- Low-S (`SCRIPT_VERIFY_LOW_S`, policy) exists because (r, n−s) is also valid — a malleability source. Strict DER (`SCRIPT_VERIFY_DERSIG`, BIP66, consensus) exists because OpenSSL once parsed non-DER encodings differently on different platforms.
- **Reused or biased k leaks d.** This is why nonces come from RFC6979 inside libsecp256k1, and why every review touching signing asks "where does the nonce come from?"

In Core: `CKey::Sign` (`src/key.cpp`, calls `secp256k1_ecdsa_sign`), `CPubKey::Verify` (`src/pubkey.cpp`).

### 7. Schnorr (BIP340) and MuSig2 (BIP327)

- BIP340: 32-byte x-only pubkeys, 64-byte signatures `(R.x, s)`, `s = k + e·x` with
  `e = hashBIP0340/challenge(R.x || P.x || m)`. Linear → keys and signatures can be aggregated.
  Core signs with `CKey::SignSchnorr` (`src/key.cpp`, calls `secp256k1_schnorrsig_sign32`) and
  verifies with `XOnlyPubKey::VerifySchnorr` (`src/pubkey.cpp`, calls `secp256k1_schnorrsig_verify`).
- BIP327 MuSig2: n-of-n key aggregation → one ordinary-looking taproot key; two signing rounds
  (nonce exchange, partial signatures). **Nonce reuse leaks the private key**, which is why
  reviewers look hard at session handling.
- Status in the tree you have:
  - `v29.0`: the `musig` module is vendored (`src/secp256k1/include/secp256k1_musig.h`) but
    **disabled**: `set(SECP256K1_ENABLE_MODULE_MUSIG OFF CACHE BOOL "" FORCE)` in `src/CMakeLists.txt`.
  - `master`: turned **on** in `cmake/secp256k1.cmake` (commit `fac0ee0bfc build: Enable secp256k1 musig module`).
  - `master`: `src/musig.cpp`/`src/musig.h` exist, `musig()` descriptors are parsed in
    `src/script/descriptor.cpp`, and the wallet can receive/spend MuSig2 inputs (PRs #31244 and
    #29675, both verified in `git log master`). Read them on `master` with
    `git -C /Users/mac/bitcoin show master:src/musig.h`.

### 8. libsecp256k1 (`src/secp256k1`) — why review there is special

- It is a **git subtree** of `bitcoin-core/secp256k1`. Changes are made and reviewed **upstream**,
  then pulled in by commits titled `Squashed 'src/secp256k1/' changes from ...`. A PR to
  `bitcoin/bitcoin` that edits `src/secp256k1/` directly is wrong; `test/lint/git-subtree-check.sh`
  checks this.
- **Constant-time discipline:** code touching secret keys or nonces must not branch or index memory
  based on secret data (timing/cache side channels). See `src/secp256k1/CONTRIBUTING.md`:
  *"Operations involving secret data should be tested for being constant time with respect to the
  secrets (see src/ctime_tests.c)."* `src/secp256k1/src/checkmem.h` lets valgrind/MSan flag
  secret-dependent branches.
- Review there needs math (field/scalar arithmetic, group law), test-vector discipline, and
  side-channel thinking — not just C correctness. As a reviewer of a Core PR, your job is usually
  to check that Core **uses** the API correctly (context randomisation, `secp256k1_context_static`
  for verify-only, clearing secrets — see [`../pr-reviews/PR-36550-AUDIT.md`](../pr-reviews/PR-36550-AUDIT.md) for a cleanse example).

---

## Exercises

Create `my-work/16-script-taproot-and-libsecp256k1/` first and keep `journal.md` in it. Each exercise says *what* to achieve, not
the commands.

### 16.1 Interpreter reading drill (3–4 h) — `C-SCRIPT-1`, `C-SCRIPT-2`, `C-SCRIPT-4`, `C-CONS-2`
Worksheet: [`exercises/16.1-interpreter-reading.md`](./exercises/16.1-interpreter-reading.md).
You trace a P2WPKH spend and a P2TR script-path spend through `VerifyScript` with only `grep`,
`less` and your own notes, and fill a flag table from `policy.h`/`validation.cpp`.

### 16.2 Sighash comparison table (2–3 h) — `C-SCRIPT-2`, `C-SCRIPT-3`
Worksheet: [`exercises/16.2-sighash-table.md`](./exercises/16.2-sighash-table.md).

### 16.3 Build and spend a taproot output both ways on regtest (5–6 h) — `C-SCRIPT-3`, `C-TX-3` (stretch)
Worksheet: [`exercises/16.3-taproot-regtest.md`](./exercises/16.3-taproot-regtest.md).
Checker: `python3 16-script-taproot-and-libsecp256k1/test_taproot_spends.py <keypath_txid> <scriptpath_txid>`.

### 16.4 Tagged hashes by hand (2–3 h) — `C-CRYPTO-3` (revisits `C-CRYPTO-1`)
Copy [`exercises/tagged_hash_skeleton.py`](./exercises/tagged_hash_skeleton.py) to
`my-work/16-script-taproot-and-libsecp256k1/tagged_hash.py`, fill every TODO from BIP340/BIP341 text, then run
`python3 16-script-taproot-and-libsecp256k1/test_tagged_hash.py`. It checks your code against
Core's `src/test/data/bip341_wallet_vectors.json` (33 checks) and never prints an expected value.

### 16.5 Read the test vectors (3–4 h) — `C-SCRIPT-1`, `C-SCRIPT-3`, `C-SCRIPT-4`
Worksheet: [`exercises/16.5-test-vectors.md`](./exercises/16.5-test-vectors.md)
(`src/test/data/script_tests.json`, `src/test/script_tests.cpp`, `test/functional/feature_taproot.py`).

### 16.6 Curves, libsecp256k1 and MuSig2 reading (2–3 h) — `C-CRYPTO-2`, `C-CRYPTO-4`, `C-CRYPTO-5`
Worksheet: [`exercises/16.6-secp256k1-musig.md`](./exercises/16.6-secp256k1-musig.md).

---

## Self-check quiz (answer from memory, then compare with [`solutions/quiz-answers.md`](./solutions/quiz-answers.md))

1. Name the function that turns a block's height/hash into the script flags used to validate it, and say which three flags are on for (almost) every block.
2. What is the difference between `MANDATORY_SCRIPT_VERIFY_FLAGS` and `STANDARD_SCRIPT_VERIFY_FLAGS`, and what happens to a peer that relays a tx violating only the second?
3. What does BIP143 commit to that the legacy sighash does not, and which attack does that stop?
4. List the elements of a taproot script-path witness in order. How does Core recognise the annex?
5. Why does `ComputeTapbranchHash` sort its inputs?
6. What happens when a tapscript contains `OP_SUCCESS80`? Under consensus? Under policy?
7. A control block is 97 bytes. What is the depth of the leaf in the tree? What is in byte 0?
8. Why is the annex non-standard if it is consensus-valid?
9. Where would you send a patch that changes `src/secp256k1/src/ecmult_gen_impl.h`, and why?
10. What does `EvalChecksigTapscript` subtract from `m_validation_weight_left`, and why does tapscript use a budget instead of the legacy sigop count?

---

## Review lens — using this stage on a real `bitcoin/bitcoin` PR

**Files to open first:** `src/script/interpreter.{h,cpp}`, `src/script/script.{h,cpp}`,
`src/policy/policy.{h,cpp}`, `src/validation.cpp` (`GetBlockScriptFlags`, `CheckInputScripts`,
`PolicyScriptChecks`, `ConsensusScriptChecks`), `src/pubkey.{h,cpp}`, `src/key.{h,cpp}`,
`src/script/sign.cpp`, `src/script/descriptor.cpp`, `src/test/script_tests.cpp`,
`src/test/data/script_tests.json`, `test/functional/feature_taproot.py`.

**Invariants to protect:**
- Consensus code must not change behaviour for any historical block. A PR that touches
  `interpreter.cpp` must not change what is valid unless it is a soft fork with activation logic.
- Every policy (`STANDARD_*`) rule must be *stricter* than consensus, never looser.
- Sighash: the message a signer signs must commit to everything an attacker could swap
  (amounts, scriptPubKeys, outputs per hashtype).
- Secret data must not leak through branches, early returns or un-cleansed memory.

**Questions to ask in a review:**
1. Is this a consensus change, a policy change, or a refactor? Does the PR say so? Is there a
   `script_tests.json` / `feature_taproot.py` case proving "no behaviour change"?
2. If a refactor moves code in `interpreter.cpp`: are the `ScriptError` codes still identical
   (tests compare them)? Is evaluation order (and therefore which error is reported first) unchanged?
3. Does a new `SCRIPT_VERIFY_*` flag appear in the right flag set (`policy.h`), in `mapFlagNames` (`src/test/transaction_tests.cpp`, used to parse the flags column of `script_tests.json`/`tx_valid.json`), and in the `script_flags` fuzz target?
4. Does a change in `src/secp256k1/` come through a subtree merge?

**Real merged PRs in this area (verified with `git -C /Users/mac/bitcoin log --oneline --merges --grep=... master`):**
- `#19953` — *Implement BIP 340-342 validation (Schnorr/taproot/tapscript)* (merge `3caee16946`). The original taproot PR; read its test plan.
- `#31640` — *tests: improves tapscript unit tests* (merge `728e86e3f3`). A good model of a test-only PR in this area.
- `#33961` — *script: Add a separate ScriptError for empty pubkeys encountered in Tapscript* (merge `29ed608dc7`, on `master`). Small, reviewable, touches `interpreter.cpp` error paths.
- Also useful: `#27122` *script: BIP341 txdata cannot be precomputed without spent outputs* (merge `ad46141602`); `#31244` *descriptors: MuSig2* (merge `5ee4e79669`).

Do the Review Club–style walk: pick one of these, run `git -C /Users/mac/bitcoin show <merge>^2 --stat`,
read the diff, and write *your own* answers to the four questions above in `my-work/16-script-taproot-and-libsecp256k1/review-notes.md`.

---

## Proof-of-work output

- `my-work/16-script-taproot-and-libsecp256k1/tagged_hash.py` passing `test_tagged_hash.py` (you may publish it as a gist).
- The two regtest txids and your annotated witness breakdown (key path vs script path) in
  `my-work/16-script-taproot-and-libsecp256k1/journal.md`, passing `test_taproot_spends.py`.
- A short write-up (your words) of one PR from the Review lens list: what it changed, how it was
  tested, and one question you would have asked. Suitable for a BitDevs Kisumu session or a Btrust
  application "evidence of learning" link. Nothing here is pre-written for you.
