#!/usr/bin/env bash
set -euo pipefail

BITCOIN_CLI="${BITCOIN_CLI:-bitcoin-cli -regtest}"
MINER_WALLET="kisumu_miner"
MERCHANT_WALLET="kisumu_merchant"

$BITCOIN_CLI createwallet "$MERCHANT_WALLET" 2>/dev/null || $BITCOIN_CLI loadwallet "$MERCHANT_WALLET" 2>/dev/null || true
$BITCOIN_CLI loadwallet "$MINER_WALLET" 2>/dev/null || true

UTXO_JSON=$($BITCOIN_CLI -rpcwallet="$MINER_WALLET" listunspent | python3 -c "import sys,json; u=[x for x in json.load(sys.stdin) if x['amount']>=2.0][0]; print(f\"{u['txid']} {u['vout']} {u['amount']}\")")
read -r TXID VOUT AMOUNT <<< "$UTXO_JSON"

MERCHANT_ADDR=$($BITCOIN_CLI -rpcwallet="$MERCHANT_WALLET" getnewaddress "pos_invoice")
CHANGE_ADDR=$($BITCOIN_CLI -rpcwallet="$MINER_WALLET" getrawchangeaddress "bech32")
CHANGE_AMT=$(python3 -c "print(f'{float($AMOUNT) - 1.0 - 0.0001:.8f}')")

echo "Spending UTXO $TXID:$VOUT ($AMOUNT BTC)"
echo " -> 1.00000000 BTC to $MERCHANT_ADDR"
echo " -> $CHANGE_AMT BTC change to $CHANGE_ADDR (0.00010000 BTC fee)"

RAW_TX=$($BITCOIN_CLI createrawtransaction \
  "[{\"txid\":\"$TXID\",\"vout\":$VOUT}]" \
  "[{\"$MERCHANT_ADDR\":1.0},{\"$CHANGE_ADDR\":$CHANGE_AMT}]")

SIGNED_HEX=$($BITCOIN_CLI -rpcwallet="$MINER_WALLET" signrawtransactionwithwallet "$RAW_TX" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
SPEND_TXID=$($BITCOIN_CLI sendrawtransaction "$SIGNED_HEX")

echo "Broadcasted TXID: $SPEND_TXID"
$BITCOIN_CLI getmempoolentry "$SPEND_TXID"
