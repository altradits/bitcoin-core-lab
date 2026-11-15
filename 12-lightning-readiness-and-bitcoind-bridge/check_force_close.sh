#!/usr/bin/env bash
# check_force_close.sh — outcome checker for exercises/03-force-close-on-chain.md.
# Inspects the transactions YOU recorded on the Polar backend bitcoind; never prints an answer.
#   POLAR_CLI  how to reach Polar's backend bitcoind. Default:
#              "bitcoin-cli -regtest -rpcport=18446 -rpcuser=polaruser -rpcpassword=polarpass"
#              (check your network's ports/credentials in Polar: node > Connect).
# Reads my-work/<stage>/answers.env:
#   COMMITMENT_TXID      the force-close (commitment) transaction
#   COMMITMENT_VERSION   its nVersion, read by you from decoderawtransaction
#   IS_TRUC              yes/no: is it a TRUC (v3) transaction?
#   CSV_DELAY            to_self_delay from `lncli pendingchannels` (blocks)
#   SWEEP_TXID           the transaction that later spent the to_local output
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, os, shlex, subprocess, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
CLI = shlex.split(os.environ.get("POLAR_CLI",
      "bitcoin-cli -regtest -rpcport=18446 -rpcuser=polaruser -rpcpassword=polarpass"))
res = []
def check(name, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))
def cli(*a):
    p = subprocess.run(CLI + [str(x) for x in a], capture_output=True, text=True)
    if p.returncode: raise RuntimeError(p.stderr.strip() or p.stdout.strip())
    try: return json.loads(p.stdout)
    except ValueError: return p.stdout.strip()
def done():
    print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if res and all(res) else 1)
A = {}
ans = os.path.join(WORK, "answers.env")
if os.path.exists(ans):
    for l in open(ans):
        if "=" in l and not l.lstrip().startswith("#"):
            k, v = l.strip().split("=", 1); A[k.strip()] = v.strip().strip('"')
try:
    cli("getblockcount")
except Exception as e:
    check("Polar backend bitcoind reachable", False, f"{str(e)[:100]} (start the Polar network; set POLAR_CLI)")
    done()
try:
    c = cli("getrawtransaction", A.get("COMMITMENT_TXID", ""), 1)
except Exception as e:
    check("COMMITMENT_TXID found on the backend", False, f"{str(e)[:100]} (Polar's bitcoind runs with -txindex)")
    done()
seq = c["vin"][0]["sequence"]
check("COMMITMENT_TXID is a BOLT 3 commitment transaction (obscured commitment number in locktime/sequence)",
      (c["locktime"] >> 24) == 0x20 and (seq >> 24) == 0x80 and len(c["vin"]) == 1,
      "that tx does not look like a commitment tx; find the force-close tx itself")
check("the commitment transaction is confirmed", c.get("confirmations", 0) >= 1, "mine a block in Polar")
check("COMMITMENT_VERSION matches the transaction", A.get("COMMITMENT_VERSION") == str(c["version"]),
      "decode the transaction and read its version")
truc = "yes" if c["version"] == 3 else "no"
check("IS_TRUC is right for this transaction", A.get("IS_TRUC", "").lower() == truc, "what version makes a tx TRUC?")
try:
    s = cli("getrawtransaction", A.get("SWEEP_TXID", ""), 1)
except Exception as e:
    check("SWEEP_TXID found on the backend", False, f"{str(e)[:80]} (mine past the delay, let lnd sweep, record the txid)")
    done()
vin = [v for v in s["vin"] if v.get("txid") == c["txid"]]
check("SWEEP_TXID spends an output of the commitment transaction", bool(vin), "pick the tx that spends to_local")
if vin:
    wit = vin[0].get("txinwitness", [])
    asm = cli("decodescript", wit[-1]).get("asm", "") if wit else ""
    toks = asm.split()
    delay = None
    # to_local (BOLT 3): OP_IF <revocationpubkey> OP_ELSE <to_self_delay> OP_CSV OP_DROP <delayedpubkey> OP_ENDIF OP_CHECKSIG.
    # (to_remote on anchor channels also has "1 OP_CSV", so the OP_IF/OP_ELSE shape is what identifies to_local.)
    if toks[:1] == ["OP_IF"] and "OP_ELSE" in toks and "OP_CHECKSEQUENCEVERIFY" in toks:
        i = toks.index("OP_CHECKSEQUENCEVERIFY")
        try: delay = int(toks[i - 1])
        except (ValueError, IndexError): delay = None
    check("the spent output is to_local (OP_IF ... OP_ELSE <delay> OP_CHECKSEQUENCEVERIFY script)", delay is not None,
          "SWEEP_TXID must spend the to_local output, not to_remote or an anchor")
    check("CSV_DELAY matches the delay inside the to_local script", delay is not None and A.get("CSV_DELAY") == str(delay),
          "read to_self_delay from lncli pendingchannels")
    sq = vin[0]["sequence"]
    check("the sweep input's nSequence enforces that delay (BIP68)",
          delay is not None and not (sq >> 31) & 1 and not (sq >> 22) & 1 and (sq & 0xFFFF) >= delay)
    check("the sweep is confirmed", s.get("confirmations", 0) >= 1, "mine a block")
done()
PY
