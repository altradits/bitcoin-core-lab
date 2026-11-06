# Stage 10: Protocol code from scratch

You implement the core Bitcoin data structures in pure Go with no
Bitcoin libraries: hashing, wire serialization, proof of work math,
Merkle trees, and a small Script interpreter. Every piece is checked
against real network values, including the genesis block.

## Goal

After this stage you can hash, serialize, and verify blocks and
scripts from first principles, and read the matching C++ code.

## Why it matters

Contributors debug serialization and consensus code, not just RPCs.
`CompactSize` framing, the `nBits` target formula, Merkle pairing,
and stack based Script execution appear in almost every consensus
pull request. Writing them once in Go makes the C++ originals
(`src/serialize.h`, `src/pow.cpp`, `src/consensus/merkle.cpp`,
`src/script/interpreter.cpp`) readable.

## Prerequisites

* Go 1.22 or later.
* Stages 02 and 06 (weight, witnesses, timelocks) for context.
* No node needed. This stage is pure Go.

## Setup

```bash
go -C ./10-protocol-primitives-from-scratch test ./...
```

Expected output:

```text
ok  	github.com/altradits/bitcoin-core-lab/10-protocol-primitives-from-scratch	0.831s
```

## Steps

### Step 1: Run the suite verbosely

```bash
go -C ./10-protocol-primitives-from-scratch test -v ./...
```

Expected output:

```text
--- PASS: TestGenesisBlockHeaderProofOfWork (0.00s)
--- PASS: TestTaggedHashBIP340Vector (0.00s)
--- PASS: TestCompactSizeCanonicalSerialization (0.00s)
--- PASS: TestMerkleRootSingleAndMultiTx (0.00s)
--- PASS: TestEvalMinimalScriptHTLCHashlock (0.00s)
ok
```

### Step 2: Verify the genesis block by hand

Open [primitives.go](./primitives.go) and find `VerifyBlockHeaderPoW`.
It reads `nBits` from header bytes 72 to 76, expands it with
`CompactBitsToTarget`, hashes the 80 bytes twice, and compares. The
test feeds the exact mainnet genesis header (version 1, timestamp
1231006505, bits `0x1d00ffff`, nonce 2083236893) and requires the
hash `000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f`
with valid proof of work. If any byte were wrong, the hash would not
match.

Compare with `CheckProofOfWork` in `src/pow.cpp`. Same three steps:
expand bits, hash header, compare.

### Step 3: Trace one value through each engine

Pick the number 100000 and follow it through the code:

* `EncodeCompactSize(100000)` returns 5 bytes: `fe` plus
  `100000` little endian. `DecodeCompactSize` rejects the same value
  with an `fd` or `ff` prefix as non canonical. Upstream:
  `WriteCompactSize` / `ReadCompactSize` in `src/serialize.h`.
* `ComputeMerkleRoot` pairs hashes left to right and duplicates the
  last hash on odd levels. Upstream: `ComputeMerkleRoot` in
  `src/consensus/merkle.cpp`.
* `EvalMinimalScript` runs pushes, `OP_DUP`, `OP_SHA256`,
  `OP_EQUAL`, and `OP_EQUALVERIFY` on a byte stack. Feed it
  `<preimage> OP_SHA256 <hash> OP_EQUALVERIFY OP_1` as the test
  does. Upstream: `EvalScript` in `src/script/interpreter.cpp`.

### Step 4: Check the tagged hash vector

The test pins `TaggedHash("BIP0340/challenge", "hello")` to
`a97ff4dc59e2e158c00a7d9cf1e7d60fb090ecf5f728b6d17be7cbbb0fc572dd`,
computed independently with Python `hashlib`. This is the BIP340
domain separation construction (`SHA256(tag) || SHA256(tag) || msg`)
that Taproot uses for tweaks and challenges.

## Checkpoint

```bash
./lab.sh check 10
```

Expected output:

```text
PASS: stage 10. all five primitive suites pass.
```

The check runs the Go suite. You can also rerun Step 1 by hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `expected Genesis hash ..., got ...` | You edited the header hex | Restore the 80 bytes exactly; check the nonce last |
| `expected error for non-canonical CompactSize` | Canonical check removed | `DecodeCompactSize` must reject overlong encodings |
| `TaggedHash mismatch` | Prefix written once instead of twice | Write `tagHash` twice before the message |
| `unsupported opcode 0x..` in your own script | Opcode outside the mini set | The VM only knows pushes, DUP, SHA256, EQUAL, EQUALVERIFY |

## Going further

1. Pin the retarget clamp. Write a test that passes
   `actualTimespanSec = 100` to `CalculateNextWorkRequired` and
   proves the new target never drops below `oldTarget / 4`. Done
   when the test passes. Upstream: `src/pow.cpp`.
2. Flag Merkle mutation (CVE-2012-2459). Change `ComputeMerkleRoot`
   to also return `mutated=true` when any paired siblings are
   identical, matching the C++ `mutated` out parameter. Done when
   `[a, b, c, c]` reports mutated and `[a, b, c]` does not.
3. Add `OP_ADD` (0x93) to the VM with a test for
   `<2> <3> OP_ADD <5> OP_EQUALVERIFY OP_1`. Done when the script
   succeeds. Note: real `CScriptNum` has sign and minimality rules;
   document what your version skips.
4. Implement `VerifyMerkleProof(txid, branch, index, root)`. Done
   when a proof for a 4 transaction tree verifies and a flipped bit
   fails.

## Contribution task

Find one fuzz target upstream that covers code from this stage (for
example `deserialize`, `parse_script`, `eval_script`, or `merkleblock`
under `src/test/fuzz/`), and report that it builds and runs on your
machine:

```bash
ls ~/bitcoin/src/test/fuzz/ | grep -i "deserialize\|parse_script\|eval_script\|merkleblock"
```

Build and run one harness for 60 seconds following `doc/fuzzing.md`.
If it fails, open a lab bug issue with the output. Do not file
upstream until a maintainer confirms.

## Sources

* `src/serialize.h` (`WriteCompactSize`, `ReadCompactSize`).
* `src/pow.cpp` (`CheckProofOfWork`, retargeting) and
  `src/arith_uint256.cpp` (`SetCompact`).
* `src/consensus/merkle.cpp` (`ComputeMerkleRoot`, `mutated` flag).
* `src/script/interpreter.cpp` (`EvalScript`).
* BIP340 (Schnorr signatures): the tagged hash construction.
