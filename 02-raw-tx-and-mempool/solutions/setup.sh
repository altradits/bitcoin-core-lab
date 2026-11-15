#!/usr/bin/env bash
# REFERENCE SOLUTION (spoiler) for exercises/01-your-own-setup.md
set -euo pipefail
read -r -a CLI <<< "${BTC_CLI:-bitcoin-cli -regtest}"
NODE_SH="${NODE_SH:-$(dirname "$0")/../../01-node-foundations/node.sh}"   # adjust to your my-work path

if ! "${CLI[@]}" getblockchaininfo >/dev/null 2>&1; then
  "$NODE_SH" start
fi

for w in kisumu_miner kisumu_merchant; do
  if "${CLI[@]}" listwallets | grep -q "\"$w\""; then
    continue                                   # already loaded
  elif "${CLI[@]}" listwalletdir | grep -q "\"name\": \"$w\""; then
    "${CLI[@]}" loadwallet "$w" >/dev/null     # on disk, not loaded
  else
    "${CLI[@]}" createwallet "$w" >/dev/null   # does not exist
  fi
done

have=$("${CLI[@]}" -rpcwallet=kisumu_miner listunspent | grep -c '"txid"' || true)
if [ "$have" -lt 5 ]; then
  # Each block adds one coinbase; a coinbase needs 100 blocks on top of it (wallet: depth 101).
  # Mining (5 - have) + 100 blocks to the miner always yields >= 5 mature outputs.
  "${CLI[@]}" generatetoaddress $(( 5 - have + 100 )) "$("${CLI[@]}" -rpcwallet=kisumu_miner getnewaddress)" >/dev/null
fi

echo "height: $("${CLI[@]}" getblockcount)"
for w in kisumu_miner kisumu_merchant; do
  echo "$w trusted: $("${CLI[@]}" -rpcwallet=$w getbalances | python3 -c 'import json,sys; print(json.load(sys.stdin)["mine"]["trusted"])')"
done
