#!/usr/bin/env python3
"""Checker for Stage 16 / Exercise 16.3 (taproot key-path AND script-path spends on regtest).

Usage:
  python3 16-script-taproot-and-libsecp256k1/test_taproot_spends.py <keypath_txid> <scriptpath_txid>

Environment:
  BITCOIN_CLI   command used to reach your ONE running regtest node
                (default: "bitcoin-cli -regtest"). Example:
                BITCOIN_CLI="$HOME/bitcoin/build/bin/bitcoin-cli -regtest -datadir=$HOME/.bitcoin-lab16"

Your node must be started with -txindex=1 (or the txs must still be in the mempool),
and both transactions must be CONFIRMED (mine a block after broadcasting).

What it checks (outcomes, not keystrokes):
  * both txs are confirmed
  * each tx spends at least one witness_v1_taproot output
  * the key-path tx's taproot input has exactly one witness element of 64 or 65 bytes
  * the script-path tx's taproot input has >= 3 elements, its last element is a
    well-formed control block (33 + 32*k bytes, leaf version 0xc0 after masking)
It never prints what the "right" witness is.
"""
import json
import shlex
import subprocess
import sys

CLI = shlex.split(__import__("os").environ.get("BITCOIN_CLI", "bitcoin-cli -regtest"))


def rpc(*args):
    try:
        out = subprocess.run(CLI + [str(a) for a in args], capture_output=True, text=True, check=True).stdout
    except FileNotFoundError:
        print(f"FAIL: cannot run {CLI[0]!r}; set BITCOIN_CLI")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"FAIL: RPC {' '.join(map(str, args[:1]))} failed: {e.stderr.strip()}")
        sys.exit(1)
    return json.loads(out)


def taproot_inputs(tx):
    return [vin for vin in tx["vin"]
            if vin.get("prevout", {}).get("scriptPubKey", {}).get("type") == "witness_v1_taproot"]


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    key_txid, script_txid = sys.argv[1], sys.argv[2]
    ok = True

    for label, txid in (("key-path", key_txid), ("script-path", script_txid)):
        tx = rpc("getrawtransaction", txid, 2)
        if tx.get("confirmations", 0) < 1:
            print(f"FAIL: {label} tx {txid[:16]}... is not confirmed yet (mine a block)")
            ok = False
            continue
        tins = taproot_inputs(tx)
        if not tins:
            print(f"FAIL: {label} tx spends no witness_v1_taproot output (or prevout data unavailable)")
            ok = False
            continue
        wit = tins[0].get("txinwitness", [])
        # strip an annex if present (it would be non-standard anyway)
        if len(wit) >= 2 and wit[-1].startswith("50"):
            print(f"FAIL: {label} witness carries an annex; that is non-standard (see IsWitnessStandard)")
            ok = False
            continue
        if label == "key-path":
            if len(wit) != 1 or len(bytes.fromhex(wit[0])) not in (64, 65):
                print("FAIL: key-path input should have exactly one 64/65-byte Schnorr signature in its witness")
                ok = False
            else:
                print("PASS: key-path spend has a single Schnorr signature witness")
        else:
            if len(wit) < 3:
                print("FAIL: script-path input needs at least <stack items...> <script> <control block>")
                ok = False
                continue
            cb = bytes.fromhex(wit[-1])
            if len(cb) < 33 or (len(cb) - 33) % 32 != 0 or len(cb) > 33 + 32 * 128:
                print("FAIL: last witness element is not a valid-size control block")
                ok = False
            elif cb[0] & 0xfe != 0xc0:
                print("FAIL: control block leaf version is not tapscript (0xc0)")
                ok = False
            else:
                depth = (len(cb) - 33) // 32
                print(f"PASS: script-path spend with a control block of merkle depth {depth}")
    if ok:
        print("RESULT: PASS. Now explain each witness element in my-work/16-script-taproot-and-libsecp256k1/journal.md.")
    else:
        print("RESULT: FAIL")
        sys.exit(1)


if __name__ == "__main__":
    main()
