// Stage 17 / Exercise 17.3 skeleton — a NEW fuzz target you write yourself.
//
// Copy this file to <your master worktree>/src/test/fuzz/taproot_merkle.cpp
// (see the worksheet for the worktree), then replace every TODO.
//
// Functions under test (src/script/interpreter.h):
//   uint256 ComputeTapleafHash(uint8_t leaf_version, <span of bytes> script);
//   uint256 ComputeTapbranchHash(<span of bytes> a, <span of bytes> b);
//   uint256 ComputeTaprootMerkleRoot(<span of bytes> control, const uint256& tapleaf_hash);
// On 29.x the span type is `Span`; on master it is `std::span`. Passing a
// std::vector<unsigned char> or a uint256 works for both.
//
// Invariants you must assert (write them as plain `assert(...)`):
//   1. ComputeTapbranchHash(a, b) == ComputeTapbranchHash(b, a)            (order independence)
//   2. A control block with ZERO path nodes gives back the leaf hash itself.
//   3. Folding the path nodes by hand with ComputeTapbranchHash gives the same
//      result as ComputeTaprootMerkleRoot.
// Remember ComputeTaprootMerkleRoot ASSERTS on bad sizes — your harness must only
// build well-formed control blocks (33 + 32*k bytes, k <= TAPROOT_CONTROL_MAX_NODE_COUNT).
// Why is that the harness's job and not the function's? Write the answer in your journal.

// TODO: copyright header in the same style as the other files in src/test/fuzz/

// TODO: includes. You need the header that declares the three functions, uint256,
//       FuzzedDataProvider, fuzz.h and fuzz/util.h. Look at another fuzz target
//       (e.g. src/test/fuzz/fee_rate.cpp) for the include style.

#include <cassert>
#include <cstdint>
#include <vector>

FUZZ_TARGET(taproot_merkle)
{
    // TODO: construct a FuzzedDataProvider over `buffer`.

    // TODO: consume a leaf version byte and a script of random length (bounded!),
    //       compute the leaf hash.

    // TODO: consume a small number k of 32-byte path nodes
    //       (use LIMITED_WHILE or ConsumeIntegralInRange so inputs stay small).

    // TODO: build the control block: 1 byte + 32-byte (fake) internal key + nodes.

    // TODO: invariant 2 (empty path) — build a 33-byte control block and assert.

    // TODO: invariant 3 — fold by hand and compare with ComputeTaprootMerkleRoot.

    // TODO: invariant 1 — two random 32-byte values, both argument orders.
}
