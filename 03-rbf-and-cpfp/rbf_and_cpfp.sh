#!/usr/bin/env bash
set -euo pipefail

BITCOIN_CLI="${BITCOIN_CLI:-bitcoin-cli -regtest}"
MINER_WALLET="kisumu_miner"
MERCHANT_WALLET="kisumu_merchant"

$BITCOIN_CLI loadwallet "$MINER_WALLET" 2>/dev/null || true
$BITCOIN_CLI loadwallet "$MERCHANT_WALLET" 2>/dev/null || true

UTXO_JSON=$($BITCOIN_CLI -rpcwallet="$MINER_WALLET" listunspent | python3 -c "import sys,json; u=[x for x in json.load(sys.stdin) if x['amount']>=5.0][0]; print(f\"{u['txid']} {u['vout']} {u['amount']}\")")
read -r TXID VOUT AMOUNT <<< "$UTXO_JSON"

MERCHANT_ADDR=$($BITCOIN_CLI -rpcwallet="$MERCHANT_WALLET" getnewaddress "rbf_cpfp_test")
MINER_CHANGE=$($BITCOIN_CLI -rpcwallet="$MINER_WALLET" getrawchangeaddress "bech32")

CHANGE_V1=$(python3 -c "print(f'{float($AMOUNT) - 2.0 - 0.00000200:.8f}')")
RAW_V1=$($BITCOIN_CLI createrawtransaction \
  "[{\"txid\":\"$TXID\",\"vout\":$VOUT,\"sequence\":4294967293}]" \
  "[{\"$MERCHANT_ADDR\":2.0},{\"$MINER_CHANGE\":$CHANGE_V1}]")
SIGNED_V1=$($BITCOIN_CLI -rpcwallet="$MINER_WALLET" signrawtransactionwithwallet "$RAW_V1" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
TXID_V1=$($BITCOIN_CLI sendrawtransaction "$SIGNED_V1")
echo "[1/3] Broadcasted low-fee RBF parent TX_V1: $TXID_V1"

CHANGE_V2=$(python3 -c "print(f'{float($AMOUNT) - 2.0 - 0.00005000:.8f}')")
RAW_V2=$($BITCOIN_CLI createrawtransaction \
  "[{\"txid\":\"$TXID\",\"vout\":$VOUT,\"sequence\":4294967293}]" \
  "[{\"$MERCHANT_ADDR\":2.0},{\"$MINER_CHANGE\":$CHANGE_V2}]")
SIGNED_V2=$($BITCOIN_CLI -rpcwallet="$MINER_WALLET" signrawtransactionwithwallet "$RAW_V2" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
TXID_V2=$($BITCOIN_CLI sendrawtransaction "$SIGNED_V2")
echo "[2/3] Replaced TX_V1 via BIP125 RBF with TX_V2: $TXID_V2"

MERCHANT_COLD=$($BITCOIN_CLI -rpcwallet="$MERCHANT_WALLET" getnewaddress "cold_storage")
RAW_CHILD=$($BITCOIN_CLI createrawtransaction \
  "[{\"txid\":\"$TXID_V2\",\"vout\":0}]" \
  "[{\"$MERCHANT_COLD\":1.99980000}]")
SIGNED_CHILD=$($BITCOIN_CLI -rpcwallet="$MERCHANT_WALLET" signrawtransactionwithwallet "$RAW_CHILD" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
TXID_CHILD=$($BITCOIN_CLI sendrawtransaction "$SIGNED_CHILD")
echo "[3/3] Attached high-fee CPFP child TX_CHILD: $TXID_CHILD"

$BITCOIN_CLI getmempoolentry "$TXID_CHILD"
