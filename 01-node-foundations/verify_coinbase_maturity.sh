#!/usr/bin/env bash
set -euo pipefail

BITCOIN_CLI="${BITCOIN_CLI:-bitcoin-cli -regtest}"
WALLET="kisumu_miner"

$BITCOIN_CLI createwallet "$WALLET" 2>/dev/null || $BITCOIN_CLI loadwallet "$WALLET" 2>/dev/null || true

ADDR=$($BITCOIN_CLI -rpcwallet="$WALLET" getnewaddress)
echo "Mining to Regtest Bech32 address: $ADDR"

echo "[1/3] Mining initial coinbase block..."
$BITCOIN_CLI generatetoaddress 1 "$ADDR" > /dev/null
echo "Spendable balance after 1 block: $($BITCOIN_CLI -rpcwallet="$WALLET" getbalance)"

echo "[2/3] Mining 99 confirmation blocks (1 short of COINBASE_MATURITY=100)..."
$BITCOIN_CLI generatetoaddress 99 "$ADDR" > /dev/null
echo "Spendable balance after 100 total blocks: $($BITCOIN_CLI -rpcwallet="$WALLET" getbalance)"

echo "[3/3] Mining 100th confirmation block (101st total block)..."
$BITCOIN_CLI generatetoaddress 1 "$ADDR" > /dev/null
echo "Spendable balance after 101 total blocks: $($BITCOIN_CLI -rpcwallet="$WALLET" getbalance)"

$BITCOIN_CLI -rpcwallet="$WALLET" listunspent
