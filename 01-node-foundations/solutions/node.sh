#!/usr/bin/env bash
# REFERENCE start/stop procedure (spoiler) for exercises/02-start-stop-procedure.md
set -euo pipefail

DATADIR=${DATADIR:-$HOME/regtest-lab}
BITCOIND=${BITCOIND:-bitcoind}
CLI_BIN=${CLI_BIN:-bitcoin-cli}
cli() { "$CLI_BIN" -datadir="$DATADIR" "$@"; }

is_up() { cli getblockchaininfo >/dev/null 2>&1; }

case "${1:-}" in
  start)
    if is_up; then echo "already running"; exit 0; fi
    if pgrep -f "bitcoind.*-datadir=$DATADIR" >/dev/null; then
      echo "process exists but RPC is not ready yet; waiting"
    else
      "$BITCOIND" -datadir="$DATADIR" -daemon
    fi
    cli -rpcwait -rpcwaittimeout=60 getblockcount >/dev/null
    echo "up at height $(cli getblockcount)"
    ;;
  stop)
    if ! is_up; then echo "not running"; exit 0; fi
    cli stop
    for _ in $(seq 1 60); do
      pgrep -f "bitcoind.*-datadir=$DATADIR" >/dev/null || { echo "stopped"; exit 0; }
      sleep 1
    done
    echo "still shutting down after 60 s; check the log" >&2; exit 1
    ;;
  status)
    is_up || { echo "not running" >&2; exit 1; }
    cli getblockchaininfo | python3 -c 'import json,sys; d=json.load(sys.stdin); print("chain=%s height=%d" % (d["chain"], d["blocks"]))'
    echo "wallets loaded: $(cli listwallets | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
    ;;
  log)
    tail -n 20 "$DATADIR/regtest/debug.log"
    ;;
  *)
    echo "usage: $0 start|stop|status|log" >&2; exit 2
    ;;
esac
