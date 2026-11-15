#!/usr/bin/env bash
# check_conf.sh — outcome checker for exercises/01-write-your-bitcoin-conf.md
# Reads YOUR my-work/01-node-foundations/bitcoin.conf (or the path in $1) and asks your running
# node whether it really uses it. Prints PASS/FAIL with a reason; never prints a config for you.
#   BTC_CLI : how to reach your node (default "bitcoin-cli -regtest")
#   MY_WORK : your work folder (default my-work/01-node-foundations)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, os, re, shlex, subprocess, sys

LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
CONF = sys.argv[1] if len(sys.argv) > 1 else os.path.join(WORK, "bitcoin.conf")
results = []

def check(name, ok, why=""):
    results.append(bool(ok))
    print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))

def cli(*args):
    p = subprocess.run(CLI + [str(a) for a in args], capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip())
    try:
        return json.loads(p.stdout)
    except ValueError:
        return p.stdout.strip()

if not os.path.exists(CONF):
    check("bitcoin.conf exists", False, f"write {CONF} yourself")
    sys.exit(1)
check("bitcoin.conf exists", True)

# Parse: key -> list of (section, value); remember whether the previous line was a comment.
sections, top, regtest = {}, {}, {}
section = ""
opt_lines = commented = 0
prev_comment = False
for raw in open(CONF):
    line = raw.strip()
    if not line:
        prev_comment = False
        continue
    if line.startswith("#"):
        prev_comment = True
        continue
    m = re.fullmatch(r"\[(\w+)\]", line)
    if m:
        section = m.group(1)
        prev_comment = False
        continue
    if "=" not in line:
        prev_comment = False
        continue
    k, v = (x.strip() for x in line.split("=", 1))
    v = v.split("#", 1)[0].strip()
    opt_lines += 1
    commented += prev_comment
    prev_comment = False
    sections.setdefault(section, {})[k] = v
top, regtest = sections.get("", {}), sections.get("regtest", {})

def val(k):
    """Value that applies on regtest: [regtest] section wins over the top section."""
    return regtest.get(k, top.get(k))

check("network selected in the top section", top.get("regtest") == "1" or top.get("chain") == "regtest",
      "the node must pick regtest without a -regtest flag; which key does that, and in which section?")
check("a [regtest] section exists", "regtest" in sections, "network-only options need their own section")

NETWORK_ONLY = {"addnode", "bind", "connect", "port", "rpcbind", "rpcport", "wallet", "walletdir"}
bad = sorted(NETWORK_ONLY & set(top))
check("no network-only option in the top section", not bad,
      f"{', '.join(bad)} in the top section makes bitcoind refuse to start on regtest")

has_plain = any("rpcpassword" in s for s in sections.values())
check("no plain-text rpcpassword", not has_plain, "use cookie auth or -rpcauth (salted HMAC) instead")

try:
    fb = float(val("fallbackfee") or 0)
except ValueError:
    fb = -1
check("fallbackfee set to a sane value", 0 < fb <= 0.001,
      "missing, zero, or above 100 sat/vB; remember the unit is BTC/kvB")
check("txindex enabled", val("txindex") == "1", "getrawtransaction needs a way to find any confirmed tx")
try:
    dbc = int(val("dbcache") or 0)
    mmp = int(val("maxmempool") or 0)
except ValueError:
    dbc = mmp = 0
check("dbcache set and small (<= 1000 MiB)", 0 < dbc <= 1000, "set it explicitly; this machine has 8 GB of RAM")
check("maxmempool set and small (<= 300 MB)", 0 < mmp <= 300, "set it explicitly; read its unit in bitcoind -help")
check("every option has a comment above it (>= 80%)", opt_lines and commented >= 0.8 * opt_lines,
      f"{commented}/{opt_lines} options have a '#' explanation line directly above them")

# Is the running node actually using these settings?
try:
    info = cli("getblockchaininfo")
    check("running node is on regtest", info.get("chain") == "regtest", "the node you reach is not regtest")
    idx = cli("getindexinfo")
    check("running node has txindex", "txindex" in idx,
          "your node does not run with txindex; is it reading this file? (txindex needs a restart)")
except Exception as e:
    check("running node reachable", False, f"{e}; start the node with your config and export BTC_CLI")

print(f"\n{sum(results)}/{len(results)} checks passed.")
sys.exit(0 if all(results) else 1)
PY
