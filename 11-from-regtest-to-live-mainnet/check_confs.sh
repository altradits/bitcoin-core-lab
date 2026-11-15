#!/usr/bin/env bash
# check_confs.sh — reads YOUR signet.conf and mainnet.conf and checks them against the worksheet
# requirements. Starts nothing. Prints reasons, never a finished config.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import os, re, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
res = []
def check(n, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + n + ("" if ok or not why else f" -- {why}"))

def parse(path):
    """Return {section: {key: [values]}}; section '' is the top level."""
    conf, sec, comments = {"": {}}, "", 0
    for raw in open(path):
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            comments += 1; continue
        m = re.fullmatch(r"\[(\w+)\]", line)
        if m:
            sec = m.group(1); conf.setdefault(sec, {}); continue
        if "=" in line:
            k, v = line.split("=", 1)
            conf[sec].setdefault(k.strip(), []).append(v.split("#")[0].strip())
    return conf, comments

def get(conf, key, sec=""):
    return (conf.get(sec, {}).get(key) or conf.get("", {}).get(key) or [None])[-1]

def rpc_safe(conf, label):
    allk = {k for s in conf.values() for k in s}
    check(f"{label}: no rpcpassword / rpcuser (cookie auth)", not ({"rpcpassword", "rpcuser"} & allk))
    binds = [v for s in conf.values() for v in s.get("rpcbind", [])]
    allows = [v for s in conf.values() for v in s.get("rpcallowip", [])]
    local = lambda v: v.split(":")[0] in ("127.0.0.1", "localhost", "[::1]", "::1")
    check(f"{label}: RPC bound to this machine only", all(local(v) for v in binds) and all(v in ("127.0.0.1", "::1", "127.0.0.1/32") for v in allows),
          "rpcbind/rpcallowip may only name localhost")

def comment_ratio(conf, comments, label):
    settings = sum(len(v) for s in conf.values() for v in s.values())
    check(f"{label}: a comment explains each setting", settings and comments >= settings, f"{comments} comments for {settings} settings")

mp = os.path.join(WORK, "mainnet.conf")
if not os.path.exists(mp):
    check("mainnet.conf exists", False, f"write {mp}")
else:
    c, n = parse(mp)
    check("mainnet: server=1", get(c, "server", "main") == "1")
    check("mainnet: daemon=1", get(c, "daemon", "main") == "1")
    try: p = int(get(c, "prune", "main") or 0)
    except ValueError: p = 0
    check("mainnet: prune between the minimum and 10000", 550 <= p <= 10000, "read MIN_DISK_SPACE_FOR_BLOCK_FILES in src/validation.h")
    try: d = int(get(c, "dbcache", "main") or 0)
    except ValueError: d = 0
    check("mainnet: dbcache 450..2048", 450 <= d <= 2048)
    check("mainnet: no txindex", get(c, "txindex", "main") in (None, "0"), "start bitcoind -prune=550 -txindex=1 once and read the error")
    try: mc = int(get(c, "maxconnections", "main") or 0)
    except ValueError: mc = 0
    check("mainnet: maxconnections <= 40", 0 < mc <= 40)
    check("mainnet: no defaults set just for show", get(c, "walletrbf", "main") is None, "walletrbf is already the default")
    check("mainnet: does not select a test network", not any(get(c, k) == "1" for k in ("signet", "testnet", "testnet4", "regtest")))
    rpc_safe(c, "mainnet"); comment_ratio(c, n, "mainnet")

sp = os.path.join(WORK, "signet.conf")
if not os.path.exists(sp):
    check("signet.conf exists", False, f"write {sp}")
else:
    c, n = parse(sp)
    check("signet: selects signet at top level", c.get("", {}).get("signet", [None])[-1] == "1")
    check("signet: has a [signet] section", "signet" in c)
    check("signet: txindex=1 (top level or [signet])", get(c, "txindex", "signet") == "1")
    check("signet: no prune (txindex needs full blocks)", get(c, "prune", "signet") in (None, "0"))
    rpc_safe(c, "signet"); comment_ratio(c, n, "signet")
print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if res and all(res) else 1)
PY
