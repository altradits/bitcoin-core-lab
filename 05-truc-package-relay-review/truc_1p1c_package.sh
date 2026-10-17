#!/usr/bin/env bash
set -euo pipefail

BITCOIN_CLI="${BITCOIN_CLI:-bitcoin-cli -regtest}"
WALLET="kisumu_miner"
$BITCOIN_CLI loadwallet "$WALLET" 2>/dev/null || true

UTXO_INFO=$($BITCOIN_CLI -rpcwallet="$WALLET" listunspent | python3 -c "import sys,json; u=[x for x in json.load(sys.stdin) if x['amount']>=5.0][0]; print(f\"{u['txid']} {u['vout']} {u['amount']}\")")
read -r UTXO_TXID UTXO_VOUT UTXO_AMT <<< "$UTXO_INFO"

ANCHOR_ADDR=$($BITCOIN_CLI -rpcwallet="$WALLET" getnewaddress "truc_parent")
FINAL_ADDR=$($BITCOIN_CLI -rpcwallet="$WALLET" getnewaddress "truc_child")

RAW_PARENT=$($BITCOIN_CLI createrawtransaction "[{\"txid\":\"$UTXO_TXID\",\"vout\":$UTXO_VOUT}]" "[{\"$ANCHOR_ADDR\":$UTXO_AMT}]" 0 true)
RAW_PARENT_V3="03000000${RAW_PARENT:8}"
SIGNED_PARENT=$($BITCOIN_CLI -rpcwallet="$WALLET" signrawtransactionwithwallet "$RAW_PARENT_V3" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
PARENT_TXID=$($BITCOIN_CLI decoderawtransaction "$SIGNED_PARENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['txid'])")
PREV_SPK=$($BITCOIN_CLI decoderawtransaction "$SIGNED_PARENT" | python3 -c "import sys,json; print(json.load(sys.stdin)['vout'][0]['scriptPubKey']['hex'])")

CHILD_AMT=$(python3 -c "print(f'{float($UTXO_AMT) - 0.00010000:.8f}')")
RAW_CHILD=$($BITCOIN_CLI createrawtransaction "[{\"txid\":\"$PARENT_TXID\",\"vout\":0}]" "[{\"$FINAL_ADDR\":$CHILD_AMT}]")
RAW_CHILD_V3="03000000${RAW_CHILD:8}"
SIGNED_CHILD=$($BITCOIN_CLI -rpcwallet="$WALLET" signrawtransactionwithwallet "$RAW_CHILD_V3" "[{\"txid\":\"$PARENT_TXID\",\"vout\":0,\"scriptPubKey\":\"$PREV_SPK\",\"amount\":$UTXO_AMT}]" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")

$BITCOIN_CLI submitpackage "[\"$SIGNED_PARENT\", \"$SIGNED_CHILD\"]"
