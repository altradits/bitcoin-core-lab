# Stage 10: Protocol Primitives From Scratch (Go, standard library only)

> Source checked: function names and behaviour against `v29.0` (`f490f5562d`); test vectors from
> Core's own unit tests (`src/test/pow_tests.cpp`, `merkle_tests.cpp`, `bech32_tests.cpp`,
> `scriptnum_tests.cpp`), BIP173/350/340, and mainnet block 100000.

**No-Shortcuts Rule.** `primitives.go` in this folder is **your** file. It starts as a skeleton
of TODOs with an exact spec comment above every function. You write every body. The tests tell
you when you are right. The reference is [`solutions/primitives.go`](./solutions/primitives.go).
Open it only after the tests for a lesson pass or after **3 honest attempts**.

```
./lab.sh blank 10    # copy exercises/primitives.go → primitives.go (fresh start; asks before overwriting)
./lab.sh check 10    # go vet + go test in this stage
./lab.sh solve 10    # copy the reference into primitives.go (spoiler)
go test -run TestLesson3 ./...   # one lesson at a time
```

---

## Objectives

| ID | You can... |
|----|------------|
| C-TX-1 | parse legacy and segwit transactions byte by byte; compute txid vs wtxid; reject malformed input |
| C-CRYPTO-1 | SHA256d, BIP340 tagged hashes, Merkle roots, Merkle branches (SPV), and the CVE-2012-2459 mutation |
| C-CONS-3 | explain CVE-2012-2459 and why Core reports `mutated` instead of trusting the root |
| C-CONS-4 | convert `nBits` ↔ target (with negative/overflow flags), verify header PoW, compute a difficulty retarget with the 4× clamps |
| C-SCRIPT-1 (intro) | encode/decode `CScriptNum` minimally and run a tiny script interpreter |
| C-TX-1 (addresses) | Bech32/Bech32m (BIP173/350) checksums and segwit address rules |

## Prerequisites
Stage 02 (you decoded a tx on paper). Go 1.22+. Estimated time: 14 hours.

---

## Lessons (each is a group of TODOs in `primitives.go` and a group of tests)

| Lesson | Functions you write | Core to read first | Tests |
|--------|---------------------|--------------------|-------|
| 1 Hashing & byte order | `Hash256`, `ReverseBytes`, `HashToDisplayHex`, `HashFromDisplayHex`, `TaggedHash` | `src/hash.h`, `src/uint256.h` | `TestLesson1_*` |
| 2 CompactSize | `EncodeCompactSize`, `DecodeCompactSize` (canonical + range checks) | `WriteCompactSize`/`ReadCompactSize` in `src/serialize.h` | `TestLesson2_*` |
| 3 Transactions | `ParseTxSummary` (legacy + segwit, txid/wtxid, malformed input) | `UnserializeTransaction` in `src/primitives/transaction.h` | `TestLesson3_*` |
| 4 Proof of work | `CompactToTarget`, `TargetToCompact`, `VerifyBlockHeaderPoW`, `CalculateNextWorkRequired` | `src/arith_uint256.cpp` (`SetCompact`/`GetCompact`), `src/pow.cpp` | `TestLesson4_*` |
| 5 Merkle | `ComputeMerkleRoot` (+ mutated), `MerkleBranch`, `RootFromBranch` | `src/consensus/merkle.cpp`, `src/test/merkle_tests.cpp` | `TestLesson5_*` |
| 6 Addresses | `Bech32Encode/Decode`, `ConvertBits`, `EncodeSegwitAddress`, `DecodeSegwitAddress` | `src/bech32.cpp`, `src/key_io.cpp`; BIP173, BIP350 | `TestLesson6_*` |
| 7 Script numbers | `ScriptNumEncode/Decode`, `CastToBool`, `EvalMinimalScript` | `CScriptNum` in `src/script/script.h`, `CastToBool` in `src/script/interpreter.cpp` | `TestLesson7_*` |

### Theory notes you will need
- **Byte order.** Hashes are stored and hashed in internal order; RPCs print them reversed
  (`uint256::GetHex`). Every txid you copy from `bitcoin-cli` must be reversed before it goes
  into raw bytes (Lesson 1 tests this both ways).
- **CompactSize must be canonical.** `0xfd 0x05 0x00` encodes 5 but is non-canonical; Core
  rejects it (`non-canonical ReadCompactSize()`). Sizes above `MAX_SIZE` (0x02000000) are rejected
  when range checking is on.
- **Retarget.** `CalculateNextWorkRequired` clamps the actual timespan to [timespan/4,
  timespan×4] and never returns a target above `powLimit`. The tests use the same vectors as
  `src/test/pow_tests.cpp`.
- **CVE-2012-2459.** Odd levels duplicate the last hash, so `[a, b, c]` and `[a, b, c, c]` give
  the same root. Core detects equal adjacent pairs and reports `mutated`; a block with a mutated
  Merkle tree is rejected as `bad-txns-duplicate` *without* marking the header permanently invalid,
  because the same header could also commit to a valid tx list.
- **Bech32 vs Bech32m.** Witness v0 uses Bech32 (constant 1); v1+ (Taproot) uses Bech32m
  (constant 0x2bc830a3) because of a length-extension weakness in Bech32 (BIP350).

---

## Extra challenges (write the code AND the test yourself)
1. Add `OP_ADD` / `OP_SUB` to `EvalMinimalScript` with `CScriptNum` 4-byte input limits; write a
   test with `<2> <3> OP_ADD <5> OP_EQUAL`.
2. Write a test proving the retarget never makes difficulty rise more than 4× in one period.
3. Write a fuzz-style test (`testing.F`) for `DecodeCompactSize` asserting decode(encode(n)) == n
   and that every accepted encoding is canonical.

---

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_10=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).
1. The genesis block hash as printed starts with `000000000019d6…`. What do its first raw bytes look like?
2. Encode 252, 253, 65535, 65536 as CompactSize.
3. Why does the segwit marker byte `0x00` not confuse a legacy parser on a tx with 0 inputs?
4. What does `nBits = 0x1d00ffff` mean as a target?
5. Give the retarget clamps and why they exist.
6. Explain CVE-2012-2459 in two sentences and how Core defends against it.
7. Why does BIP340 use tagged hashes?
8. Why was Bech32m introduced for witness v1+?
9. Minimal encoding of the script number −1 and 128.

## Review lens
- Files: `src/serialize.h`, `src/primitives/transaction.h`, `src/pow.cpp`, `src/arith_uint256.cpp`,
  `src/consensus/merkle.cpp`, `src/bech32.cpp`, `src/script/script.h`; tests
  `src/test/serialize_tests.cpp`, `pow_tests.cpp`, `merkle_tests.cpp`, `bech32_tests.cpp`,
  `scriptnum_tests.cpp`; fuzz targets in `src/test/fuzz/` for each.
- Invariants: serialization round-trips and rejects non-canonical forms; consensus math has no
  overflow (`arith_uint256`); anything consensus-critical is bit-for-bit identical across versions.
- Questions: Does the PR change any serialized format or consensus arithmetic? (If yes: why, and
  is it a soft fork?) Are there new test vectors from the BIP? Is there a fuzz target?

## Proof-of-work output
Your passing `primitives.go`, and one write-up in your own words explaining CVE-2012-2459 with a
diagram — a good first post for your blog or a BitDevs Kisumu session.
