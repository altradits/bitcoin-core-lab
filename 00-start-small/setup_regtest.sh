#!/usr/bin/env bash
# setup_regtest.sh — ENVIRONMENT HELPER ONLY (allowed by CURRICULUM_CONVENTIONS.md §1).
#
# Starts a regtest bitcoind if one is not already answering RPC. It does NOT create
# wallets, mine blocks or send coins: those are Stage 00 skills you do by hand.
# From Stage 01 onward you replace this file with your own start/stop procedure.
#
# Override the binaries/datadir with environment variables, e.g.
#   BITCOIND="bitcoind -datadir=$HOME/regtest-lab" BTC_CLI="bitcoin-cli -datadir=$HOME/regtest-lab" ./setup_regtest.sh
set -euo pipefail

BITCOIND="${BITCOIND:-bitcoind -regtest}"
BTC_CLI="${BTC_CLI:-bitcoin-cli -regtest}"

if $BTC_CLI getblockchaininfo >/dev/null 2>&1; then
  echo "A regtest node is already answering RPC. Nothing to do."
  exit 0
fi

if pgrep -x bitcoind >/dev/null 2>&1; then
  echo "A bitcoind process is running but is not answering on this RPC config."
  echo "The machine has 8 GB of RAM: stop the other node first (bitcoin-cli ... stop)."
  exit 1
fi

echo "Starting: $BITCOIND -daemon"
$BITCOIND -daemon
for _ in $(seq 1 30); do
  if $BTC_CLI getblockchaininfo >/dev/null 2>&1; then
    echo "Node is up. Now go back to exercises/01-micro-steps.md and type the commands yourself."
    echo "When you finish studying, stop it with:  $BTC_CLI stop"
    exit 0
  fi
  sleep 1
done
echo "Node did not answer within 30 s. Read the end of the regtest debug.log to find out why."
exit 1
