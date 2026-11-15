#!/usr/bin/env python3
"""YOUR HTLC funder/spender. Copy to my-work/06-lightning-htlc-state-machine/htlc_spend.py.

Fill every TODO. Talk to YOUR node through BTC_CLI (default: "bitcoin-cli -regtest").
Print every txid and reject reason you need for answers.env.
"""
import hashlib
import json
import os
import shlex
import subprocess
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", os.path.expanduser("~/bitcoin"))
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

from test_framework.key import ECKey  # noqa: E402
from test_framework.messages import COIN, COutPoint, CTransaction, CTxIn, CTxInWitness, CTxOut, tx_from_hex  # noqa: E402,F401
from test_framework.script import (  # noqa: E402,F401
    CScript, OP_CHECKSEQUENCEVERIFY, OP_CHECKSIG, OP_DROP, OP_ELSE, OP_ENDIF,
    OP_EQUALVERIFY, OP_IF, OP_SHA256, SIGHASH_ALL, SegwitV0SignatureHash,
)

CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))


def cli(*args):
    out = subprocess.run(CLI + [str(a) for a in args], capture_output=True, text=True)
    if out.returncode != 0:
        raise RuntimeError(out.stderr.strip())
    try:
        return json.loads(out.stdout)
    except ValueError:
        return out.stdout.strip()


def build_script(payment_hash: bytes, merchant_pub: bytes, sender_pub: bytes, delay: int) -> CScript:
    # TODO: return the CScript for the toy HTLC (README Theory 1). Compare .hex() with your
    #       hand-assembled HTLC_SCRIPT_HEX from Worksheet 1 — they must be identical.
    raise NotImplementedError


def sign_input(tx: CTransaction, script: CScript, amount_sats: int, key: ECKey) -> bytes:
    # TODO: BIP143 sighash for input 0, ECDSA-sign it, append the SIGHASH_ALL byte.
    raise NotImplementedError


def main():
    # TODO: make the two keys (ECKey, compressed), the preimage, the hash and the delay.
    # TODO: build the script and get its P2WSH address with decodescript.
    # TODO: fund two 1-BTC outputs to that address from kisumu_miner (your own raw tx or a
    #       wallet RPC — you already mastered raw funding in Stage 02), mine 1 block.
    # TODO: wrong-preimage claim -> testmempoolaccept -> print reject-reason.
    # TODO: real claim of vout 0 -> sendrawtransaction -> print txid.
    # TODO: refund of vout 1 with nSequence = delay -> testmempoolaccept -> print reason.
    # TODO: mine BLOCKS_TO_MINE blocks, broadcast the SAME refund, mine 1 block, print txid.
    raise NotImplementedError


if __name__ == "__main__":
    main()
