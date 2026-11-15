#!/usr/bin/env bash
# check_htlc_script.sh — offline checker for exercises/01-assemble-the-script.md
# Parses YOUR script hex and checks it against YOUR preimage/keys/delay. Prints no answers.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import hashlib, os, re, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ANS_PATH = os.environ.get("ANSWERS", os.path.join(WORK, "answers.env"))
res = []
def check(n, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + n + ("" if ok or not why else f" -- {why}"))
A = {}
if os.path.exists(ANS_PATH):
    for line in open(ANS_PATH):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1); A[k.strip()] = v.strip().strip('"').strip("'")
check("answers file exists", os.path.exists(ANS_PATH))
def hx(k, n=None):
    v = A.get(k, "").lower()
    return bytes.fromhex(v) if re.fullmatch(r"([0-9a-f]{2})+", v) and (n is None or len(v) == 2 * n) else None
R, H = hx("PREIMAGE_HEX", 32), hx("PAYMENT_HASH_HEX", 32)
M, S = hx("MERCHANT_PUBKEY", 33), hx("SENDER_PUBKEY", 33)
check("PREIMAGE_HEX is 32 bytes", R)
check("PAYMENT_HASH_HEX = SHA256(preimage bytes)", R and H and hashlib.sha256(R).digest() == H, "hash the raw bytes, not the hex text")
check("pubkeys are 33-byte compressed (02/03)", M and S and M[0] in (2, 3) and S[0] in (2, 3))
try:
    d = int(A.get("CSV_DELAY", ""))
except ValueError:
    d = -1
check("CSV_DELAY between 5 and 20", 5 <= d <= 20)
script = hx("HTLC_SCRIPT_HEX")
check("HTLC_SCRIPT_HEX is hex", script)
if script and H and M and S and 5 <= d <= 20:
    push_n = bytes([0x50 + d]) if d <= 16 else bytes([1, d])
    want = (bytes([0x63, 0xa8, 0x20]) + H + bytes([0x88, 0x21]) + M + bytes([0xac, 0x67]) + push_n
            + bytes([0xb2, 0x75, 0x21]) + S + bytes([0xac, 0x68]))
    # piecewise diagnostics, never printing the expected bytes
    check("starts with OP_IF OP_SHA256 <32-byte push>", script[:3] == want[:3])
    check("payment hash in the script is yours", script[3:35] == H)
    check("OP_EQUALVERIFY then a 33-byte push of the MERCHANT key", script[35:37] == want[35:37] and script[37:70] == M)
    check("OP_CHECKSIG OP_ELSE", script[70:72] == want[70:72])
    check("delay push is minimal and equals CSV_DELAY", script[72:72 + len(push_n)] == push_n, "small numbers use OP_1..OP_16; above 16 a 1-byte push")
    k = 72 + len(push_n)
    check("OP_CHECKSEQUENCEVERIFY OP_DROP <33-byte SENDER key>", script[k:k + 3] == want[k:k + 3] and script[k + 3:k + 36] == S)
    check("ends OP_CHECKSIG OP_ENDIF and nothing else", script[k + 36:] == want[k + 36:])
    spk = hx("P2WSH_SPK_HEX", 34)
    check("P2WSH_SPK_HEX = 0x00 0x20 SHA256(script)", spk == b"\x00\x20" + hashlib.sha256(script).digest())
    check("P2WSH_ADDRESS is a regtest bech32 v0 address", re.fullmatch(r"bcrt1q[02-9ac-hj-np-z]{58}", A.get("P2WSH_ADDRESS", "")))
print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if all(res) else 1)
PY
