#!/usr/bin/env bash
# check_wallet_drill.sh — outcome checker for exercises/03-wallet-safety-drill.md
#   BTC_CLI (default "bitcoin-cli -regtest"), MY_WORK; reads wallet_drill.env
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, os, shlex, subprocess, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
CLI = shlex.split(os.environ.get("BTC_CLI", "bitcoin-cli -regtest"))
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
ENV = os.path.join(WORK, "wallet_drill.env")
res = []
def check(n, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + n + ("" if ok or not why else f" -- {why}"))
def done():
    print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if res and all(res) else 1)
def cli(*a, w=None):
    p = subprocess.run(CLI + ([f"-rpcwallet={w}"] if w else []) + [str(x) for x in a], capture_output=True, text=True)
    if p.returncode: raise RuntimeError(p.stderr.strip())
    try: return json.loads(p.stdout)
    except ValueError: return p.stdout.strip()
A = {}
if os.path.exists(ENV):
    for line in open(ENV):
        if "=" in line and not line.startswith("#"):
            k, v = line.strip().split("=", 1); A[k] = v.strip('"')
check("wallet_drill.env exists", A, f"write {ENV}")
try: loaded = cli("listwallets")
except Exception as e: check("node reachable", False, str(e)); done()
hot, rest, watch = A.get("HOT_WALLET"), A.get("RESTORED_WALLET"), A.get("WATCH_WALLET")
for w in (hot, rest, watch):
    check(f"wallet {w} is loaded", w in loaded, "load it before running the checker")
if not all(w in loaded for w in (hot, rest, watch)): done()
ih, ir, iw = cli("getwalletinfo", w=hot), cli("getwalletinfo", w=rest), cli("getwalletinfo", w=watch)
check("hot wallet is a descriptor wallet", ih.get("descriptors") is True)
check("hot wallet is encrypted", "unlocked_until" in ih, "use a passphrase")
check("hot wallet has a confirmed balance", float(cli("getbalance", w=hot)) > 0)
check("restored wallet has the same balance", cli("getbalance", w=hot) == cli("getbalance", w=rest))
pub = lambda w: sorted(d["desc"] for d in cli("listdescriptors", w=w)["descriptors"])
check("restored wallet has the same descriptors", pub(hot) == pub(rest), "restore from the backup file, do not create a new wallet")
check("watch wallet has private keys disabled", iw.get("private_keys_enabled") is False)
check("watch wallet tracks the same descriptors", set(pub(hot)) <= set(pub(watch)), "import every active descriptor, receive AND change")
check("watch wallet sees the same balance", cli("getbalance", w=watch) == cli("getbalance", w=hot))
check("LOCKED_SEND_ERROR_CODE", A.get("LOCKED_SEND_ERROR_CODE") == "-13", "copy the error code of a send from a locked wallet")
done()
PY
