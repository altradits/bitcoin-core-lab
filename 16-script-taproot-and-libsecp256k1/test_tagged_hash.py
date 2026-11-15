#!/usr/bin/env python3
"""Checker for Stage 16 / Exercise 16.4.

Loads YOUR implementation from my-work/16-script-taproot-and-libsecp256k1/tagged_hash.py (or the path given as
the first argument) and compares it against Bitcoin Core's own BIP341 test
vectors in /Users/mac/bitcoin/src/test/data/bip341_wallet_vectors.json.

It prints PASS/FAIL with a reason. It never prints an expected hash.
Override the vector path with BIP341_VECTORS=/path/to/bip341_wallet_vectors.json
"""
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
DEFAULT_IMPL = os.path.join(REPO, "my-work", "16-script-taproot-and-libsecp256k1", "tagged_hash.py")
VECTORS = os.environ.get(
    "BIP341_VECTORS", "/Users/mac/bitcoin/src/test/data/bip341_wallet_vectors.json"
)


def load_impl(path):
    if not os.path.exists(path):
        print(f"FAIL: {path} not found. Copy exercises/tagged_hash_skeleton.py there and fill it in.")
        sys.exit(1)
    spec = importlib.util.spec_from_file_location("learner_tagged_hash", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def leaves(tree, out):
    if tree is None:
        return
    if isinstance(tree, dict):
        out.append(tree)
        return
    for sub in tree:
        leaves(sub, out)


def main():
    impl = load_impl(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_IMPL)
    if not os.path.exists(VECTORS):
        print(f"FAIL: vector file {VECTORS} not found (is /Users/mac/bitcoin checked out?)")
        sys.exit(1)
    with open(VECTORS) as f:
        data = json.load(f)

    failures = 0
    checks = 0

    def check(ok, what):
        nonlocal failures, checks
        checks += 1
        if not ok:
            failures += 1
            print(f"FAIL: {what}")

    # Sanity: tagged_hash must be 32 bytes and depend on the tag.
    try:
        a = impl.tagged_hash("TapLeaf", b"")
        b = impl.tagged_hash("TapBranch", b"")
        check(isinstance(a, bytes) and len(a) == 32, "tagged_hash must return 32 raw bytes")
        check(a != b, "tagged_hash must depend on the tag")
        check(impl.compact_size(252) == bytes([252]), "compact_size(252) should be one byte")
        check(len(impl.compact_size(253)) == 3, "compact_size(253) should be 3 bytes (0xfd prefix)")
    except NotImplementedError:
        print("FAIL: tagged_hash/compact_size still raise NotImplementedError")
        sys.exit(1)

    for idx, vec in enumerate(data["scriptPubKey"]):
        given, inter = vec["given"], vec["intermediary"]
        tree = given["scriptTree"]
        ls = []
        leaves(tree, ls)
        expected_leaves = inter.get("leafHashes") or []
        mine = [
            impl.tapleaf_hash(l["leafVersion"], bytes.fromhex(l["script"])).hex()
            for l in sorted(ls, key=lambda l: l["id"])
        ]
        check(mine == expected_leaves, f"scriptPubKey vector {idx}: leaf hashes differ (check leaf version byte and CompactSize length prefix)")
        root = impl.merkle_root(tree)
        root_hex = root.hex() if root is not None else None
        check(root_hex == inter["merkleRoot"], f"scriptPubKey vector {idx}: merkle root differs (check branch ordering)")
        tweak = impl.taptweak_hash(bytes.fromhex(given["internalPubkey"]), root)
        check(tweak.hex() == inter["tweak"], f"scriptPubKey vector {idx}: tweak differs (what goes in when there is no tree?)")

    # tapbranch must be order independent
    x, y = bytes(range(32)), bytes(range(1, 33))
    check(impl.tapbranch_hash(x, y) == impl.tapbranch_hash(y, x), "tapbranch_hash must not depend on argument order")

    for idx, inp in enumerate(data["keyPathSpending"][0]["inputSpending"]):
        im = inp["intermediary"]
        got = impl.tapsighash(bytes.fromhex(im["sigMsg"])).hex()
        check(got == im["sigHash"], f"keyPathSpending input {idx}: sighash differs (epoch byte counted twice or missing?)")

    if failures:
        print(f"RESULT: FAIL ({failures}/{checks} checks failed)")
        sys.exit(1)
    print(f"RESULT: PASS ({checks} checks against Bitcoin Core's bip341_wallet_vectors.json)")


if __name__ == "__main__":
    main()
