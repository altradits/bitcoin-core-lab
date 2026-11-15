#!/usr/bin/env python3
"""Stage 16 / Exercise 16.4 skeleton: BIP340 + BIP341 tagged hashes, by hand.

Copy this file to my-work/16-script-taproot-and-libsecp256k1/tagged_hash.py and fill in every TODO yourself.
Use only the Python standard library (hashlib). Read the specs, not a library:
  - BIP340, section "Tagged Hashes"
  - BIP341, section "Script validation rules" and "Constructing and spending Taproot outputs"
  - C++ cross-check: /Users/mac/bitcoin/src/script/interpreter.cpp (ComputeTapleafHash,
    ComputeTapbranchHash) and /Users/mac/bitcoin/src/pubkey.cpp (ComputeTapTweakHash)

Then run:  python3 16-script-taproot-and-libsecp256k1/test_tagged_hash.py
The checker compares your output with src/test/data/bip341_wallet_vectors.json.
"""
import hashlib  # noqa: F401  (you will need it)


def tagged_hash(tag: str, msg: bytes) -> bytes:
    """Return the 32-byte BIP340 tagged hash of msg under tag."""
    # TODO: write the formula from BIP340 in one or two lines.
    raise NotImplementedError


def compact_size(n: int) -> bytes:
    """Bitcoin CompactSize encoding of n (you wrote this in Go in Stage 10)."""
    # TODO
    raise NotImplementedError


def tapleaf_hash(leaf_version: int, script: bytes) -> bytes:
    """BIP341 leaf hash. Which three things go into it, in which order?"""
    # TODO
    raise NotImplementedError


def tapbranch_hash(a: bytes, b: bytes) -> bytes:
    """BIP341 branch hash of two 32-byte child hashes. Does order matter? Why not?"""
    # TODO
    raise NotImplementedError


def taptweak_hash(internal_xonly: bytes, merkle_root) -> bytes:
    """BIP341 tweak. merkle_root is None when there is no script tree."""
    # TODO
    raise NotImplementedError


def tapsighash(sig_msg_with_epoch: bytes) -> bytes:
    """Hash a BIP341 signature message. Read the vector file: does its 'sigMsg'
    already include the epoch byte? Decide, then write one line."""
    # TODO
    raise NotImplementedError


def merkle_root(tree):
    """tree is the 'scriptTree' JSON value: None, a leaf dict
    {'id','leafVersion','script'}, or a list [left, right] of subtrees.
    Return the 32-byte merkle root (or None)."""
    # TODO: recursion. Leaves -> tapleaf_hash, pairs -> tapbranch_hash.
    raise NotImplementedError
