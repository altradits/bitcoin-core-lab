#!/usr/bin/env python3
"""SPOILER: reference solution for Stage 16, Exercise 16.4 (BIP340/BIP341 tagged hashes).

Open this file only after test_tagged_hash.py passes on your own code, or after
three honest attempts. Your version lives in my-work/16-script-taproot-and-libsecp256k1/tagged_hash.py.

Every line here follows the text of BIP340 ("tagged hashes") and BIP341
("Constructing and spending Taproot outputs"). Compare with the C++ in
~/bitcoin/src/script/interpreter.cpp:
  ComputeTapleafHash, ComputeTapbranchHash, ComputeTaprootMerkleRoot
and ~/bitcoin/src/pubkey.cpp: XOnlyPubKey::ComputeTapTweakHash.
"""
import hashlib


def tagged_hash(tag: str, msg: bytes) -> bytes:
    # BIP340: SHA256(SHA256(tag) || SHA256(tag) || msg)
    tag_digest = hashlib.sha256(tag.encode()).digest()
    return hashlib.sha256(tag_digest + tag_digest + msg).digest()


def compact_size(n: int) -> bytes:
    if n < 0xfd:
        return bytes([n])
    if n <= 0xffff:
        return b"\xfd" + n.to_bytes(2, "little")
    if n <= 0xffffffff:
        return b"\xfe" + n.to_bytes(4, "little")
    return b"\xff" + n.to_bytes(8, "little")


def tapleaf_hash(leaf_version: int, script: bytes) -> bytes:
    # BIP341: hashTapLeaf(v || compact_size(size of s) || s)
    return tagged_hash("TapLeaf", bytes([leaf_version]) + compact_size(len(script)) + script)


def tapbranch_hash(a: bytes, b: bytes) -> bytes:
    # BIP341: children are sorted lexicographically before hashing
    if b < a:
        a, b = b, a
    return tagged_hash("TapBranch", a + b)


def taptweak_hash(internal_xonly: bytes, merkle_root) -> bytes:
    # BIP341: t = hashTapTweak(p || km); with no script tree, km is empty
    return tagged_hash("TapTweak", internal_xonly + (merkle_root or b""))


def tapsighash(sig_msg_with_epoch: bytes) -> bytes:
    # BIP341: hashTapSighash(0x00 || SigMsg(...)). In bip341_wallet_vectors.json the
    # 'sigMsg' field ALREADY starts with the 0x00 epoch byte (look: "0003..." = epoch 0,
    # hash_type 3). So do not add it twice. The C++ does `ss << EPOCH` in
    # SignatureHashSchnorr (src/script/interpreter.cpp).
    return tagged_hash("TapSighash", sig_msg_with_epoch)


def merkle_root(tree):
    """tree is the JSON 'scriptTree' from bip341_wallet_vectors.json:
    a leaf dict {'id','leafVersion','script'} or a list of two subtrees."""
    if tree is None:
        return None
    if isinstance(tree, dict):
        return tapleaf_hash(tree["leafVersion"], bytes.fromhex(tree["script"]))
    left, right = tree
    return tapbranch_hash(merkle_root(left), merkle_root(right))
