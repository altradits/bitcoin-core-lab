# ⚙️ Stage 10: Bitcoin Protocol Primitives From Scratch (Zero-Dependency Systems Programming)

## Objective
Stop treating `bitcoind` as a black box. To handle any challenge in Bitcoin Core, Lightning, or sovereign wallet engineering, you must be able to **write the binary wire protocol, cryptographic hash structures, Proof-of-Work target math, Merkle trees, and Script stack machine from scratch**.

This module implements 5 core Bitcoin engines in pure, zero-dependency Go ([`primitives.go`](./primitives.go)) and verifies them against Satoshi Nakamoto's real Mainnet Genesis Block (`000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f`) in [`primitives_test.go`](./primitives_test.go).

---

## 1. The 5 Core Protocol Engines in [`primitives.go`](./primitives.go)

| Engine | Functions Implemented | Upstream `bitcoin/bitcoin` C++ Equivalent |
| :--- | :--- | :--- |
| **1. Cryptographic Hashing & BIP340 Tagged Hashes** | `Hash256`, `ReverseBytes32`, `TaggedHash` | [`src/crypto/sha256.cpp`](file:///Users/mac/bitcoin/src/crypto/sha256.cpp), [`src/hash.h`](file:///Users/mac/bitcoin/src/hash.h) |
| **2. Canonical Wire Serialization (`CompactSize`)** | `EncodeCompactSize`, `DecodeCompactSize` | [`src/serialize.h`](file:///Users/mac/bitcoin/src/serialize.h) (`WriteCompactSize` / `ReadCompactSize`) |
| **3. 80-Byte Block Header PoW & `nBits` Target Math** | `CompactBitsToTarget`, `VerifyBlockHeaderPoW`, `CalculateNextWorkRequired` | [`src/pow.cpp`](file:///Users/mac/bitcoin/src/pow.cpp), [`src/arith_uint256.cpp`](file:///Users/mac/bitcoin/src/arith_uint256.cpp) |
| **4. Binary Merkle Tree Engine** | `ComputeMerkleRoot` | [`src/consensus/merkle.cpp`](file:///Users/mac/bitcoin/src/consensus/merkle.cpp) |
| **5. Stack-Based Bitcoin Script Virtual Machine** | `EvalMinimalScript` (`OP_DUP`, `OP_SHA256`, `OP_EQUAL`, `OP_EQUALVERIFY`) | [`src/script/interpreter.cpp`](file:///Users/mac/bitcoin/src/script/interpreter.cpp) (`EvalScript`) |

---

## 2. Run the Verification Suite

```bash
go test -v ./...
# or from the repository root:
./lab.sh practice 10
```

```text
=== RUN   TestGenesisBlockHeaderProofOfWork
--- PASS: TestGenesisBlockHeaderProofOfWork (0.00s)
=== RUN   TestCompactSizeCanonicalSerialization
--- PASS: TestCompactSizeCanonicalSerialization (0.00s)
=== RUN   TestMerkleRootSingleAndMultiTx
--- PASS: TestMerkleRootSingleAndMultiTx (0.00s)
=== RUN   TestEvalMinimalScriptHTLCHashlock
--- PASS: TestEvalMinimalScriptHTLCHashlock (0.00s)
PASS
```

---

## 3. Five Programmer Mastery Challenges (Write These in `primitives.go`!)

To prove you can solve any Bitcoin programming problem from first principles, implement these 5 extensions in [`primitives.go`](./primitives.go) and add unit tests in [`primitives_test.go`](./primitives_test.go):

### Challenge 1: Enforce the 2016-Block Retarget Bounds (`TestCalculateNextWorkRequired`)
- Write a unit test in `primitives_test.go` that passes `actualTimespanSec = 100` (way faster than 2 weeks / `1,209,600` seconds) into `CalculateNextWorkRequired` and proves that the new target never drops below `oldTarget / 4` (the `4x` maximum difficulty increase clamp per retarget period in `src/pow.cpp`).

### Challenge 2: Add `OP_ADD` (`0x93`) and `OP_SUB` (`0x94`) to `EvalMinimalScript`
- In Bitcoin Script (`CScriptNum` in `src/script/script.h`), small integers are pushed onto the stack and popped by arithmetic opcodes. Add `OP_ADD` (`0x93`) to `EvalMinimalScript` and write a test verifying that `<2> <3> OP_ADD <5> OP_EQUALVERIFY OP_1` succeeds.

### Challenge 3: Implement `VerifyMerkleProof(txid [32]byte, branch [][32]byte, index uint32, expectedRoot [32]byte) bool`
- Given a single transaction's 32-byte internal hash, its $O(\log_2 N)$ sibling hashes along the path to the root (`branch`), and the bitmask of left/right positions (`index`), compute the root hash and compare it against the 80-byte block header's `MerkleRoot`.

### Challenge 4: Detect the `CVE-2012-2459` Merkle Tree Duplication Vulnerability
- Look at `ComputeMerkleRoot` in `primitives.go`: when `len(level)` is odd, it duplicates the last element (`level = append(level, level[len(level)-1])`).
- Why is that dangerous for P2P block caching? Because `[tx1, tx2, tx3]` and `[tx1, tx2, tx3, tx3]` produce the **exact same Merkle Root** (`[tx1, tx2, tx3, tx3]` has duplicate `tx3` at the end, which is invalid by consensus, yet has the same block hash!).
- Update `ComputeMerkleRoot(txHashes [][32]byte) ([32]byte, bool, error)` to return a `mutated bool` flag set to `true` if any two adjacent hashes being paired are identical (`level[i] == level[i+1]`), matching `ComputeMerkleRoot(leaves, &mutated)` in [`src/consensus/merkle.cpp`](file:///Users/mac/bitcoin/src/consensus/merkle.cpp)!

### Challenge 5: Implement `ParseRawLegacyTx(rawBytes []byte)`
- Using `DecodeCompactSize` and `binary.LittleEndian`, parse a raw non-witness transaction's `version` (`int32`), input count, `prevout` (`32-byte hash + uint32 vout`), `scriptSig`, `nSequence`, output count, `nValue` (`int64` satoshis), `scriptPubKey`, and `nLockTime` (`uint32`), and verify `Hash256(rawBytes)` matches `bitcoin-cli decoderawtransaction`.
