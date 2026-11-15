#!/usr/bin/env python3
"""Construct, fund, and verify both branches of a P2WSH Lightning HTLC on Bitcoin Core regtest."""

import hashlib
import json
import os
import shlex
import subprocess
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", "/Users/mac/bitcoin")
# Full CLI command override, same convention as the stage shell scripts,
# e.g. BITCOIN_CLI="bitcoin-cli -regtest -datadir=/tmp/x -rpcport=28332".
BITCOIN_CLI = os.environ.get("BITCOIN_CLI")
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

from test_framework.key import ECKey
from test_framework.messages import (
    COIN,
    COutPoint,
    CTransaction,
    CTxIn,
    CTxInWitness,
    CTxOut,
    tx_from_hex,
)
from test_framework.script import (
    CScript,
    OP_CHECKSEQUENCEVERIFY,
    OP_CHECKSIG,
    OP_DROP,
    OP_ELSE,
    OP_ENDIF,
    OP_EQUALVERIFY,
    OP_IF,
    OP_SHA256,
    SIGHASH_ALL,
    SegwitV0SignatureHash,
)


def cli(*args):
    if BITCOIN_CLI:
        cmd = [*shlex.split(BITCOIN_CLI), *args]
    else:
        cmd = [os.path.join(BITCOIN_ROOT, "build/bin/bitcoin-cli"), "-regtest", *args]
    out = subprocess.check_output(cmd, text=True).strip()
    try:
        return json.loads(out)
    except Exception:
        return out


def main():
    sender_key = ECKey()
    sender_key.set(hashlib.sha256(b"kisumu_htlc_sender_key").digest(), True)
    merchant_key = ECKey()
    merchant_key.set(hashlib.sha256(b"kisumu_htlc_merchant_key").digest(), True)

    preimage = b"kisumu_lightning_htlc_secret_001"
    payment_hash = hashlib.sha256(preimage).digest()
    csv_delay = 10

    htlc_script = CScript([
        OP_IF,
            OP_SHA256, payment_hash, OP_EQUALVERIFY,
            merchant_key.get_pubkey().get_bytes(), OP_CHECKSIG,
        OP_ELSE,
            csv_delay, OP_CHECKSEQUENCEVERIFY, OP_DROP,
            sender_key.get_pubkey().get_bytes(), OP_CHECKSIG,
        OP_ENDIF,
    ])
    htlc_address = cli("decodescript", htlc_script.hex())["segwit"]["address"]

    utxo = [u for u in cli("-rpcwallet=kisumu_miner", "listunspent") if u["amount"] >= 5.0][0]
    change_addr = cli("-rpcwallet=kisumu_miner", "getrawchangeaddress", "bech32")
    change_amt = round(float(utxo["amount"]) - 2.0 - 0.0001, 8)

    raw_fund = cli(
        "createrawtransaction",
        json.dumps([{"txid": utxo["txid"], "vout": utxo["vout"]}]),
        json.dumps([{htlc_address: 1.0}, {change_addr: change_amt}]),
    )
    fund_tx = tx_from_hex(raw_fund)
    fund_tx.vout.insert(1, CTxOut(1 * COIN, fund_tx.vout[0].scriptPubKey))
    signed_fund = cli("-rpcwallet=kisumu_miner", "signrawtransactionwithwallet", fund_tx.serialize().hex())["hex"]
    fund_txid = cli("sendrawtransaction", signed_fund)
    cli("generatetoaddress", "1", change_addr)

    sink_addr = cli("-rpcwallet=kisumu_merchant", "getnewaddress", "htlc_settled")
    sink_spk = bytes.fromhex(cli("-rpcwallet=kisumu_merchant", "getaddressinfo", sink_addr)["scriptPubKey"])

    # Branch A: Preimage Claim
    claim_tx = CTransaction()
    claim_tx.version = 2
    claim_tx.vin = [CTxIn(COutPoint(int(fund_txid, 16), 0), nSequence=0xFFFFFFFD)]
    claim_tx.vout = [CTxOut(int(0.9999 * COIN), sink_spk)]
    sighash_claim = SegwitV0SignatureHash(htlc_script, claim_tx, 0, SIGHASH_ALL, 1 * COIN)
    sig_merchant = merchant_key.sign_ecdsa(sighash_claim) + bytes([SIGHASH_ALL])
    claim_tx.wit.vtxinwit = [CTxInWitness()]
    claim_tx.wit.vtxinwit[0].scriptWitness.stack = [sig_merchant, preimage, b"\x01", bytes(htlc_script)]

    # Branch A1: wrong preimage must fail OP_EQUALVERIFY.
    bad_claim = CTransaction()
    bad_claim.version = 2
    bad_claim.vin = [CTxIn(COutPoint(int(fund_txid, 16), 0), nSequence=0xFFFFFFFD)]
    bad_claim.vout = [CTxOut(int(0.9999 * COIN), sink_spk)]
    bad_sighash = SegwitV0SignatureHash(htlc_script, bad_claim, 0, SIGHASH_ALL, 1 * COIN)
    bad_sig = merchant_key.sign_ecdsa(bad_sighash) + bytes([SIGHASH_ALL])
    bad_claim.wit.vtxinwit = [CTxInWitness()]
    bad_claim.wit.vtxinwit[0].scriptWitness.stack = [
        bad_sig, b"wrong_secret_preimage_0000000000", b"\x01", bytes(htlc_script),
    ]
    bad_result = cli("testmempoolaccept", json.dumps([bad_claim.serialize().hex()]))[0]
    print(f"Wrong preimage: allowed={bad_result['allowed']} reject-reason={bad_result.get('reject-reason')!r}")
    assert not bad_result["allowed"] and "OP_EQUALVERIFY" in bad_result.get("reject-reason", "")

    claim_txid = cli("sendrawtransaction", claim_tx.serialize().hex())
    print(f"Preimage Claim TXID: {claim_txid}")

    # Branch B: CSV Timeout Refund
    refund_tx = CTransaction()
    refund_tx.version = 2
    refund_tx.vin = [CTxIn(COutPoint(int(fund_txid, 16), 1), nSequence=csv_delay)]
    refund_tx.vout = [CTxOut(int(0.9999 * COIN), sink_spk)]
    sighash_refund = SegwitV0SignatureHash(htlc_script, refund_tx, 0, SIGHASH_ALL, 1 * COIN)
    sig_sender = sender_key.sign_ecdsa(sighash_refund) + bytes([SIGHASH_ALL])
    refund_tx.wit.vtxinwit = [CTxInWitness()]
    refund_tx.wit.vtxinwit[0].scriptWitness.stack = [sig_sender, b"", bytes(htlc_script)]

    # Branch B1: refund before 10 confirmations must fail BIP68.
    early_result = cli("testmempoolaccept", json.dumps([refund_tx.serialize().hex()]))[0]
    print(f"Early refund: allowed={early_result['allowed']} reject-reason={early_result.get('reject-reason')!r}")
    assert not early_result["allowed"] and "non-BIP68-final" in early_result.get("reject-reason", "")

    cli("generatetoaddress", "9", change_addr)
    refund_txid = cli("sendrawtransaction", refund_tx.serialize().hex())
    cli("generatetoaddress", "1", change_addr)
    print(f"CSV Timeout Refund TXID: {refund_txid}")
    print("PASS: HTLC preimage claim and CSV refund both verified.")


if __name__ == "__main__":
    main()
