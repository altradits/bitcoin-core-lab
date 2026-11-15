#!/usr/bin/env bash
# check_decode.sh — offline checker for exercises/02-decode-a-tx-by-hand.md
# Parses the worksheet's transaction itself and compares with YOUR answers.env.
# Prints PASS/FAIL per field; never prints the expected value.
#   MY_WORK / ANSWERS as in the other checkers.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import hashlib, os, re, sys

LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ANS_PATH = os.environ.get("ANSWERS", os.path.join(WORK, "answers.env"))
SHEET = os.path.join(LAB, STAGE, "exercises", "02-decode-a-tx-by-hand.md")
PREVOUT_SATS = 50 * 100_000_000
results = []

def check(name, ok, why=""):
    results.append(bool(ok))
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))

A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            A[k.strip()] = v.strip().strip('"').strip("'")
check("answers file exists", os.path.exists(ANS_PATH), f"copy exercises/answers.env.template to {ANS_PATH}")

hexes = re.findall(r"\b(0[12]000000[0-9a-f]{100,})\b", open(SHEET).read())
raw = bytes.fromhex(hexes[0])

# --- minimal BIP144 parser -----------------------------------------------------------
pos = 0
def take(n):
    global pos
    b = raw[pos:pos + n]; pos += n; return b
def cs():
    n = take(1)[0]
    if n < 0xfd: return n
    return int.from_bytes(take({0xfd: 2, 0xfe: 4, 0xff: 8}[n]), "little")

version = int.from_bytes(take(4), "little")
marker_flag = raw[pos:pos + 2]
segwit = marker_flag == b"\x00\x01"
if segwit: take(2)
vin = []
for _ in range(cs()):
    prev = take(32)[::-1].hex(); vout = int.from_bytes(take(4), "little")
    ss = take(cs()); seq = int.from_bytes(take(4), "little")
    vin.append((prev, vout, ss, seq))
vouts = []
for _ in range(cs()):
    val = int.from_bytes(take(8), "little"); spk = take(cs()); vouts.append((val, spk))
wit_start = pos
wit = []
if segwit:
    for _ in vin:
        wit.append([take(cs()) for _ in range(cs())])
wit_end = pos
locktime = int.from_bytes(take(4), "little")
total = len(raw)
base = total - 2 - (wit_end - wit_start) if segwit else total
stripped = raw[:4] + raw[6:wit_start] + raw[wit_end:] if segwit else raw
weight = base * 3 + total
vsize = (weight + 3) // 4
fee = PREVOUT_SATS - sum(v for v, _ in vouts)
dsha = lambda b: hashlib.sha256(hashlib.sha256(b).digest()).digest()[::-1].hex()

def eq(key, expected, why, norm=str.lower):
    got = A.get(key, "")
    check(key, got != "" and norm(got) == norm(str(expected)), why)

eq("VERSION", version, "4 bytes, little-endian")
eq("MARKER_FLAG", marker_flag.hex(), "the 2 bytes right after the version")
eq("INPUT_COUNT", len(vin), "CompactSize after marker/flag")
eq("PREV_TXID", vin[0][0], "RPCs show hashes byte-reversed")
eq("PREV_VOUT", vin[0][1], "4 bytes little-endian after the 32-byte hash")
eq("SCRIPTSIG_LEN", len(vin[0][2]), "segwit inputs keep the signature elsewhere")
eq("SEQUENCE", vin[0][3], "4 bytes little-endian; convert to decimal")
eq("OUTPUT_COUNT", len(vouts), "CompactSize before the outputs")
eq("OUT0_SATS", vouts[0][0], "8 bytes little-endian, in satoshis")
eq("OUT1_SATS", vouts[1][0], "8 bytes little-endian, in satoshis")
eq("OUT0_SPK", vouts[0][1].hex(), "the script after the length byte (not including it)")
eq("WITNESS_ITEMS", len(wit[0]), "item count comes first in the witness section")
eq("SIG_LEN", len(wit[0][0]), "the length byte of the first witness item")
eq("SIGHASH_BYTE", wit[0][0][-1:].hex(), "last byte of the signature item, 2 hex digits")
eq("PUBKEY_PREFIX", wit[0][1][:1].hex(), "first byte of the second item, 2 hex digits")
eq("LOCKTIME", locktime, "last 4 bytes")
eq("TOTAL_SIZE", total, "count bytes = hex characters / 2")
eq("BASE_SIZE", base, "remove marker, flag and all witness bytes")
eq("WEIGHT", weight, "base*3 + total")
eq("VSIZE", vsize, "ceil(weight / 4)")
eq("FEE_SATS", fee, "the spent output was 50 BTC")
try:
    fr_ok = abs(float(A.get("FEERATE_SAT_VB", "x")) - fee / vsize) < 0.006
except ValueError:
    fr_ok = False
check("FEERATE_SAT_VB", fr_ok, "fee / vsize, 2 decimals")
eq("SIGNALS_BIP125", "yes" if any(s < 0xfffffffe for *_, s in vin) else "no", "compare nSequence with 0xfffffffe")
eq("TXID", dsha(stripped), "double-SHA256 of the non-witness serialization, then reverse")
eq("WTXID", dsha(raw), "double-SHA256 of the full serialization, then reverse")

print(f"\n{sum(results)}/{len(results)} checks passed.")
sys.exit(0 if all(results) else 1)
PY
