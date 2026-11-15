#!/usr/bin/env bash
# check_lnd_conf.sh — reads YOUR lnd.conf and bitcoin-zmq.conf; starts nothing.
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
    d, sec, comments, settings = {}, "", 0, 0
    for raw in open(path):
        l = raw.strip()
        if not l: continue
        if l.startswith(("#", ";")): comments += 1; continue
        m = re.fullmatch(r"\[(.+)\]", l)
        if m: sec = m.group(1).strip().lower(); continue
        if "=" in l:
            k, v = l.split("=", 1); d[k.strip().lower()] = (v.split(";")[0].split("#")[0].strip(), sec); settings += 1
    return d, comments, settings
lp, zp = os.path.join(WORK, "lnd.conf"), os.path.join(WORK, "bitcoin-zmq.conf")
check("lnd.conf exists", os.path.exists(lp), f"write {lp}")
check("bitcoin-zmq.conf exists", os.path.exists(zp), f"write {zp}")
if not (os.path.exists(lp) and os.path.exists(zp)):
    print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(1)
L, lc, ls = parse(lp); Z, zc, zs = parse(zp)
val = lambda k: L.get(k, ("", ""))[0]
sec = lambda k: L.get(k, ("", ""))[1]
check("bitcoin.regtest=1 in [Bitcoin]", val("bitcoin.regtest") in ("1", "true") and sec("bitcoin.regtest") == "bitcoin")
check("bitcoin.node=bitcoind in [Bitcoin]", val("bitcoin.node") == "bitcoind" and sec("bitcoin.node") == "bitcoin")
check("no obsolete bitcoin.active", "bitcoin.active" not in L, "lnd 0.21 has no such option; check lnd --help")
host = val("bitcoind.rpchost")
check("bitcoind.rpchost is 127.0.0.1:<regtest RPC port> in [Bitcoind]", re.fullmatch(r"(127\.0\.0\.1|localhost):\d+", host) and sec("bitcoind.rpchost") == "bitcoind")
check("cookie auth (bitcoind.rpccookie), no rpcuser/rpcpass", val("bitcoind.rpccookie").endswith(".cookie") and "bitcoind.rpcuser" not in L and "bitcoind.rpcpass" not in L)
zb, zt = val("bitcoind.zmqpubrawblock"), val("bitcoind.zmqpubrawtx")
port = lambda s: (re.fullmatch(r"tcp://(127\.0\.0\.1|localhost):(\d+)", s) or [None, None, None])[2]
check("lnd ZMQ endpoints are localhost tcp", port(zb) and port(zt))
check("block and tx use different ports", port(zb) and port(zb) != port(zt))
check("alias set in [Application Options]", val("alias") and sec("alias") == "application options")
zbb = Z.get("zmqpubrawblock", ("", ""))[0]; ztt = Z.get("zmqpubrawtx", ("", ""))[0]
check("bitcoind publishes rawblock on the port lnd listens to", port(zbb) and port(zbb) == port(zb))
check("bitcoind publishes rawtx on the port lnd listens to", port(ztt) and port(ztt) == port(zt))
check("every setting has a comment", lc >= ls and zc >= zs, f"lnd.conf {lc}/{ls}, zmq {zc}/{zs}")
print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if all(res) else 1)
PY
