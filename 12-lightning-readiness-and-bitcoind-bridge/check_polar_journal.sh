#!/usr/bin/env bash
# check_polar_journal.sh — checks that polar_journal.md documents each lifecycle step with real output.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
J="${MY_WORK:-$(dirname "$HERE")/my-work/$(basename "$HERE")}/polar_journal.md"
[ -f "$J" ] || { echo "FAIL: write $J"; exit 1; }
pass=0; total=0
t() { total=$((total+1)); if grep -qiE "$2" "$J"; then pass=$((pass+1)); echo "PASS: $1"; else echo "FAIL: $1 -- $3"; fi; }
for n in 1 2 3 4 5 6 7 8; do t "has '## Step $n'" "^## Step $n\b" "use the headings from the worksheet"; done
t "a 66-hex node pubkey appears" "\b0[23][0-9a-f]{64}\b" "record A's and D's identity pubkeys"
t "a 64-hex funding/closing txid appears" "\b[0-9a-f]{64}\b" "record the txids you looked up"
t "lncli openchannel used" "lncli.*openchannel" "type the command yourself and paste it"
t "lncli decodepayreq used before paying" "lncli.*decodepayreq" "decode before you pay"
t "an invoice (lnbcrt...) appears" "lnbcrt[0-9a-z]+" "paste the invoice you decoded"
t "bitcoin-cli used on the backend" "bitcoin-cli" "funding and confirmation go through the backend bitcoind"
t "lncli closechannel used" "lncli.*closechannel"
echo; echo "$pass/$total checks passed."; [ "$pass" -eq "$total" ]
