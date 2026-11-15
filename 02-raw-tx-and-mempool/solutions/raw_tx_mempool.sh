#!/usr/bin/env bash
# REFERENCE SOLUTION (spoiler) for exercises/03-build-sign-broadcast.md.
# Under the No-Shortcuts Rule you type these steps yourself first; open this file only after
# ../check_raw_tx.sh passes or after 3 honest attempts.
# Point it at your node with BITCOIN_CLI="bitcoin-cli -datadir=..." (default: bitcoin-cli -regtest).
# At the end it prints the Worksheet 3 lines for answers.env.
set -euo pipefail

read -r -a CLI <<< "${BITCOIN_CLI:-bitcoin-cli -regtest}"
MINER=kisumu_miner
MERCHANT=kisumu_merchant

# 1. Pick a mature coinbase UTXO (the wallet marks coinbase txs as "generated").
UTXO=""
while read -r txid vout amount; do
  if "${CLI[@]}" -rpcwallet=$MINER gettransaction "$txid" | grep -q '"generated": true'; then
    UTXO="$txid $vout $amount"; break
  fi
done < <("${CLI[@]}" -rpcwallet=$MINER listunspent | python3 -c '
import json, sys
for u in json.load(sys.stdin):
    print(u["txid"], u["vout"], format(u["amount"], ".8f"))')
read -r TXID VOUT AMOUNT <<< "$UTXO"

# 2. Arithmetic in integer satoshis, then back to an 8-decimal BTC string.
IN_SATS=$(python3 -c "from decimal import Decimal; print(int(Decimal('$AMOUNT') * 100000000))")
CHANGE_SATS=$(( IN_SATS - 100000000 - 10000 ))
CHANGE_BTC=$(python3 -c "print(f'{$CHANGE_SATS / 1e8:.8f}')")

MERCHANT_ADDR=$("${CLI[@]}" -rpcwallet=$MERCHANT getnewaddress "pos_invoice" bech32)
CHANGE_ADDR=$("${CLI[@]}" -rpcwallet=$MINER getrawchangeaddress bech32)

RAW=$("${CLI[@]}" createrawtransaction \
  "[{\"txid\":\"$TXID\",\"vout\":$VOUT}]" \
  "[{\"$MERCHANT_ADDR\":1.0},{\"$CHANGE_ADDR\":$CHANGE_BTC}]")
SIGNED=$("${CLI[@]}" -rpcwallet=$MINER signrawtransactionwithwallet "$RAW" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hex"])')

# 3. Test before broadcasting.
"${CLI[@]}" testmempoolaccept "[\"$SIGNED\"]"
SPEND_TXID=$("${CLI[@]}" sendrawtransaction "$SIGNED")
"${CLI[@]}" getmempoolentry "$SPEND_TXID"

# 4. Confirm it.
"${CLI[@]}" generatetoaddress 1 "$("${CLI[@]}" -rpcwallet=$MINER getnewaddress)" >/dev/null

"${CLI[@]}" getrawtransaction "$SPEND_TXID" 1 | python3 -c '
import json, sys
t = json.load(sys.stdin)
print("# answers.env lines (Worksheet 3)")
print("RAW_TXID=" + t["txid"]); print("RAW_WTXID=" + t["hash"])
print("PREDICTED_WEIGHT=%d" % t["weight"]); print("PREDICTED_VSIZE=%d" % t["vsize"])
print("FEERATE_SAT_VB_RAW=%.2f" % (10000 / t["vsize"]))'
echo "RAW_TX_BLOCK_HEIGHT=$("${CLI[@]}" getblockcount)"
