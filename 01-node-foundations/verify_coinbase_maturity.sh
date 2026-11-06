#!/usr/bin/env bash
# Stage 01: prove COINBASE_MATURITY = 100 on regtest.
# Uses a fresh wallet per run, so output is the same on any machine
# no matter how many times you ran it before.
set -euo pipefail

BITCOIN_CLI="${BITCOIN_CLI:-bitcoin-cli -regtest}"
WALLET="stage01_run_$$_$(date +%s)"

$BITCOIN_CLI createwallet "$WALLET" > /dev/null

ADDR=$($BITCOIN_CLI -rpcwallet="$WALLET" getnewaddress)
echo "Mining to Regtest Bech32 address: $ADDR"

echo "[1/3] Mining initial coinbase block..."
FIRST_HASH=$($BITCOIN_CLI generatetoaddress 1 "$ADDR" | python3 -c "import sys,json; print(json.load(sys.stdin)[0])")
SUBSIDY=$($BITCOIN_CLI getblock "$FIRST_HASH" 2 | python3 -c "import sys,json; print(json.load(sys.stdin)['tx'][0]['vout'][0]['value'])")
BAL1=$($BITCOIN_CLI -rpcwallet="$WALLET" getbalance)
echo "Spendable balance after 1 block: $BAL1 (immature coin: $SUBSIDY)"

echo "[2/3] Mining 99 confirmation blocks (100 total, still 1 short of COINBASE_MATURITY=100)..."
$BITCOIN_CLI generatetoaddress 99 "$ADDR" > /dev/null
BAL100=$($BITCOIN_CLI -rpcwallet="$WALLET" getbalance)
echo "Spendable balance after 100 total blocks: $BAL100"

echo "[3/3] Mining 100th confirmation block (101st total block)..."
$BITCOIN_CLI generatetoaddress 1 "$ADDR" > /dev/null
BAL101=$($BITCOIN_CLI -rpcwallet="$WALLET" getbalance)
echo "Spendable balance after 101 total blocks: $BAL101"

$BITCOIN_CLI unloadwallet "$WALLET" > /dev/null 2>&1 || true

if [ "$BAL1" = "0.00000000" ] && [ "$BAL100" = "0.00000000" ] && \
   python3 -c "import sys; sys.exit(0 if abs(float('$BAL101') - float('$SUBSIDY')) < 1e-8 else 1)"; then
  echo "PASS: coinbase unspendable for 100 blocks, spendable after 101 (subsidy $SUBSIDY)."
else
  echo "FAIL: unexpected balances (after1=$BAL1 after100=$BAL100 after101=$BAL101 subsidy=$SUBSIDY)."
  exit 1
fi
