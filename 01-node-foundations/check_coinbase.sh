#!/usr/bin/env bash
# check_coinbase.sh — outcome checker for exercises/03-* and 04-* (maturity, subsidy, coinbase anatomy)
# Compares YOUR answers.env with values it computes from consensus rules and your node.
# It prints PASS/FAIL and a nudge, never the expected value.
#   BTC_CLI, MY_WORK, ANSWERS as in the other checkers.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, os, re, shlex, subprocess, sys

LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ANS_PATH = os.environ.get("ANSWERS", os.path.join(WORK, "answers.env"))
results = []

def check(name, ok, why=""):
    results.append(bool(ok))
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))

def cli(*args, wallet=None):
    cmd = CLI + ([f"-rpcwallet={wallet}"] if wallet else []) + [str(a) for a in args]
    p = subprocess.run(cmd, capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    try:
        return json.loads(p.stdout)
    except ValueError:
        return p.stdout.strip()

A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            A[k.strip()] = v.strip().strip('"').strip("'")
check("answers file exists", os.path.exists(ANS_PATH), f"copy exercises/answers.env.template to {ANS_PATH}")

def num(k):
    try:
        return int(A.get(k, "").replace("_", "").replace(",", ""))
    except ValueError:
        return None

def subsidy(h, interval):
    halvings = h // interval
    return 0 if halvings >= 64 else (50 * 100_000_000) >> halvings

# ---- Part A: offline arithmetic -------------------------------------------------
for key, h, iv in (("SUBSIDY_REGTEST_149", 149, 150), ("SUBSIDY_REGTEST_150", 150, 150),
                   ("SUBSIDY_REGTEST_300", 300, 150), ("SUBSIDY_MAINNET_840000", 840000, 210000)):
    check(f"{key}", num(key) == subsidy(h, iv), "halvings = height // interval; answer in satoshis")
first_zero = next(n for n in range(65) if (50 * 100_000_000) >> n == 0)
check("FIRST_ZERO_HALVING", num("FIRST_ZERO_HALVING") == first_zero, "find the highest power of two <= 5e9 sat")

# ---- Worksheet 4 offline decoding -----------------------------------------------
check("BIP34_HEIGHT_A", num("BIP34_HEIGHT_A") == 0x012c, "little-endian: first data byte is least significant")
check("BIP34_HEIGHT_B", num("BIP34_HEIGHT_B") == 0x0dbba0, "3 data bytes, little-endian")
check("BIP34_HEIGHT_C", num("BIP34_HEIGHT_C") == 0x80, "the push is 2 bytes; why is the second one 00?")
check("WITNESS_COMMITMENT_PREFIX", A.get("WITNESS_COMMITMENT_PREFIX", "").lower() == "6a24aa21a9ed",
      "6 bytes: an opcode, a push length, and a 4-byte magic (BIP141)")

# ---- Node-backed parts ----------------------------------------------------------
try:
    tip = cli("getblockcount")
except Exception as e:
    check("node reachable", False, f"{e}; start your node and export BTC_CLI")
    print(f"\n{sum(results)}/{len(results)} checks passed."); sys.exit(1)

# Part B: UTXO total at a height the learner chose
uh = num("UTXO_HEIGHT")
if uh is None or not (1 <= uh <= tip):
    check("UTXO_TOTAL_SATS", False, "set UTXO_HEIGHT to a height your chain has reached")
else:
    expected = sum(subsidy(h, 150) for h in range(1, uh + 1))
    check("UTXO_TOTAL_SATS matches the subsidy sum for UTXO_HEIGHT", num("UTXO_TOTAL_SATS") == expected,
          "sum subsidies of blocks 1..H epoch by epoch; is the genesis output in the UTXO set?")

# Part C: maturity experiment in wallet maturity_lab
ok_wallet = "maturity_lab" in cli("listwallets")
check("wallet maturity_lab is loaded", ok_wallet, "create it (or loadwallet if it exists)")
cbh = num("CB_HEIGHT")
cbtx = A.get("CB_TXID", "").lower()
if ok_wallet and re.fullmatch(r"[0-9a-f]{64}", cbtx):
    try:
        t = cli("gettransaction", cbtx, wallet="maturity_lab")
        is_cb = t.get("generated", False)
        check("CB_TXID is a coinbase paid to maturity_lab", is_cb, "that txid is not a coinbase of this wallet")
        check("CB_HEIGHT is the height of that coinbase", is_cb and t.get("blockheight") == cbh,
              "read the block height of CB_TXID again")
    except Exception:
        check("CB_TXID is a coinbase paid to maturity_lab", False, "maturity_lab does not know this txid")
else:
    check("CB_TXID is a coinbase paid to maturity_lab", False, "fill CB_TXID (64 hex) and load maturity_lab")
if cbh is not None:
    check("MEMPOOL_ACCEPT_TIP", num("MEMPOOL_ACCEPT_TIP") == cbh + 99,
          "consensus uses the height of the NEXT block (nSpendHeight), not the tip")
    check("WALLET_TRUSTED_TIP", num("WALLET_TRUSTED_TIP") == cbh + 100,
          "read GetTxBlocksToMaturity in src/wallet/wallet.cpp")
    check("chain is past the wallet maturity point", tip >= cbh + 100, "keep mining (to another wallet) and observe")
check("PREMATURE_REJECT_REASON", A.get("PREMATURE_REJECT_REASON") == "bad-txns-premature-spend-of-coinbase",
      "copy the exact reject-reason string testmempoolaccept printed before maturity")

# Worksheet 4 Part C: coinbase value of a block that has a segwit commitment and fees
ch = num("COINBASE_CHECK_HEIGHT")
if ch is None or not (1 <= ch <= tip):
    check("COINBASE_VALUE_SATS", False, "set COINBASE_CHECK_HEIGHT to a block you mined")
else:
    blk = cli("getblock", cli("getblockhash", ch), 2)
    cb = blk["tx"][0]
    value = sum(round(o["value"] * 100_000_000) for o in cb["vout"])
    fees = sum(round(t.get("fee", 0) * 100_000_000) for t in blk["tx"][1:])
    check("COINBASE_CHECK_HEIGHT is a block with at least one fee-paying tx", len(blk["tx"]) > 1 and fees > 0,
          "pick a block that contains your payment, not an empty one")
    check("COINBASE_VALUE_SATS matches that coinbase", num("COINBASE_VALUE_SATS") == value,
          "add up every coinbase output value, in satoshis")
    check("coinbase value obeys subsidy + fees (your block)", value <= subsidy(ch, 150) + fees,
          "this should never fail on a valid chain")

print(f"\n{sum(results)}/{len(results)} checks passed.")
sys.exit(0 if all(results) else 1)
PY
