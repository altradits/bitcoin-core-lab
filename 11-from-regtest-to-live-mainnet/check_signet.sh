#!/usr/bin/env bash
# check_signet.sh — outcome checker for exercises/02-sync-signet.md.
# Looks at YOUR signet node and your journal; never prints an answer.
#   SIGNET_CLI  how to reach your signet node (default: "bitcoin-cli -signet").
#               Example: SIGNET_CLI="bitcoin-cli -datadir=$HOME/.bitcoin-signet -signet"
# Reads my-work/<stage>/answers.env: SIGNET_WALLET, FAUCET_TXID, SIGNET_TIP_SEEN
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LAB_DIR="$(dirname "$HERE")" STAGE="$(basename "$HERE")"
exec python3 - "$@" <<'PY'
import json, os, re, shlex, subprocess, sys
LAB, STAGE = os.environ["LAB_DIR"], os.environ["STAGE"]
WORK = os.environ.get("MY_WORK", os.path.join(LAB, "my-work", STAGE))
CLI = shlex.split(os.environ.get("SIGNET_CLI", "bitcoin-cli -signet"))
res = []
def check(name, ok, why=""):
    res.append(bool(ok)); print(("PASS: " if ok else "FAIL: ") + name + ("" if ok or not why else f" -- {why}"))
def cli(*a):
    p = subprocess.run(CLI + [str(x) for x in a], capture_output=True, text=True)
    if p.returncode: raise RuntimeError(p.stderr.strip() or p.stdout.strip())
    try: return json.loads(p.stdout)
    except ValueError: return p.stdout.strip()
A = {}
ans = os.path.join(WORK, "answers.env")
if os.path.exists(ans):
    for l in open(ans):
        if "=" in l and not l.lstrip().startswith("#"):
            k, v = l.strip().split("=", 1); A[k.strip()] = v.strip().strip('"')
journal = os.path.join(WORK, "journal.md")
j = open(journal).read() if os.path.exists(journal) else ""
check("journal has at least 3 getblockchaininfo samples (blocks/headers/verificationprogress)",
      len(re.findall(r"verificationprogress", j)) >= 3, f"record samples in {journal} while syncing")
check("journal records 3 peers' transport_protocol_type", len(re.findall(r"transport_protocol_type|\bv2\b|\bv1\b", j)) >= 3,
      "step 3: getpeerinfo for 3 peers")
try:
    info = cli("getblockchaininfo")
except Exception as e:
    check("signet node reachable", False, f"{e} (set SIGNET_CLI to reach your signet node)")
    print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(1)
check("node is on signet", info.get("chain") == "signet", f"chain is {info.get('chain')!r}")
check("initial block download finished", info.get("initialblockdownload") is False, "keep syncing")
check("verificationprogress is about 1", info.get("verificationprogress", 0) > 0.9999, "keep syncing")
tip_seen = A.get("SIGNET_TIP_SEEN", "")
try:
    h = cli("getblockheader", tip_seen)
    check("SIGNET_TIP_SEEN is a block in your active signet chain", h.get("confirmations", -1) >= 1)
except Exception:
    check("SIGNET_TIP_SEEN is a block in your active signet chain", False,
          "write the best block hash you saw when sync finished (getbestblockhash) as SIGNET_TIP_SEEN")
wallet, txid = A.get("SIGNET_WALLET", ""), A.get("FAUCET_TXID", "")
try:
    tx = cli(f"-rpcwallet={wallet}", "gettransaction", txid)
    received = any(d.get("category") == "receive" for d in tx.get("details", []))
    check("FAUCET_TXID paid your signet wallet", received, "the tx must pay an address of SIGNET_WALLET")
    check("faucet tx has at least 1 confirmation", tx.get("confirmations", 0) >= 1, "wait for a block")
except Exception as e:
    check("FAUCET_TXID found in SIGNET_WALLET", False, f"set SIGNET_WALLET and FAUCET_TXID ({str(e)[:80]})")
print(f"\n{sum(res)}/{len(res)} checks passed."); sys.exit(0 if all(res) else 1)
PY
