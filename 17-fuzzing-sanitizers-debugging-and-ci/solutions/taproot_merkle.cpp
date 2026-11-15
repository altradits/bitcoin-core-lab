// SPOILER — Stage 17 / Exercise 17.3 reference harness.
// Open only after check_fuzz_target.py passes on your own file, or after three honest attempts.
// Written against the names in /Users/mac/bitcoin (29.x and master). It was NOT compiled while
// authoring this lab (no builds on the authoring machine) — compiling it is part of your exercise.

// Copyright (c) The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <script/interpreter.h>
#include <test/fuzz/FuzzedDataProvider.h>
#include <test/fuzz/fuzz.h>
#include <test/fuzz/util.h>
#include <uint256.h>

#include <cassert>
#include <cstdint>
#include <vector>

FUZZ_TARGET(taproot_merkle)
{
    FuzzedDataProvider fdp(buffer.data(), buffer.size());

    const uint8_t leaf_version{static_cast<uint8_t>(fdp.ConsumeIntegral<uint8_t>() & TAPROOT_LEAF_MASK)};
    const std::vector<unsigned char> script{ConsumeRandomLengthByteVector<unsigned char>(fdp, 10'000)};
    const uint256 leaf{ComputeTapleafHash(leaf_version, script)};

    // Control block header: leaf version | parity bit, then a 32-byte internal key.
    std::vector<unsigned char> control;
    control.push_back(static_cast<unsigned char>(leaf_version | (fdp.ConsumeBool() ? 1 : 0)));
    const std::vector<unsigned char> internal_key{ConsumeFixedLengthByteVector<unsigned char>(fdp, 32)};
    control.insert(control.end(), internal_key.begin(), internal_key.end());

    // Invariant 2: no path nodes -> the root is the leaf hash.
    assert(ComputeTaprootMerkleRoot(control, leaf) == leaf);

    // Add k path nodes and fold them by hand.
    const size_t k{fdp.ConsumeIntegralInRange<size_t>(0, TAPROOT_CONTROL_MAX_NODE_COUNT)};
    uint256 folded{leaf};
    for (size_t i = 0; i < k; ++i) {
        const std::vector<unsigned char> node{ConsumeFixedLengthByteVector<unsigned char>(fdp, TAPROOT_CONTROL_NODE_SIZE)};
        control.insert(control.end(), node.begin(), node.end());
        folded = ComputeTapbranchHash(folded, node);
    }
    // Invariant 3: hand fold == library fold.
    assert(ComputeTaprootMerkleRoot(control, leaf) == folded);

    // Invariant 1: branch hashing ignores argument order.
    const std::vector<unsigned char> a{ConsumeFixedLengthByteVector<unsigned char>(fdp, 32)};
    const std::vector<unsigned char> b{ConsumeFixedLengthByteVector<unsigned char>(fdp, 32)};
    assert(ComputeTapbranchHash(a, b) == ComputeTapbranchHash(b, a));
}
