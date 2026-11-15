#!/usr/bin/env bash
# Outcome checker for the Stage 07 PSBT worksheet (README "Exercise 4").
# It inspects regtest STATE and the files you saved. It never runs the flow for you
# and never prints the commands. Start your own regtest bitcoind first.
#   Usage: ./check_psbt_flow.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/my-work/07-psbt-descriptors-and-miniscript"
CLI="${BITCOIN_CLI:-bitcoin-cli} -regtest"
WATCH=w07_watch
SIGNER=w07_signer
fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fails=$((fails+1)); }

if ! $CLI getblockcount >/dev/null 2>&1; then
  echo "FAIL: cannot reach a regtest node with '$CLI'. Start YOUR bitcoind -regtest (or set BITCOIN_CLI)."
  exit 1
fi

# 1. Journal exists (you choose what goes in it; the checker only needs it to exist and be non-trivial).
if [ -s "$WORK/journal.md" ] && [ "$(wc -l < "$WORK/journal.md")" -ge 10 ]; then
  pass "my-work/07-psbt-descriptors-and-miniscript/journal.md has your command log"
else
  fail "my-work/07-psbt-descriptors-and-miniscript/journal.md missing or shorter than 10 lines — record every command you typed"
fi

# 2. Two wallets with the right properties.
wi=$($CLI -rpcwallet=$WATCH getwalletinfo 2>/dev/null)
if echo "$wi" | grep -q '"private_keys_enabled": false' && echo "$wi" | grep -q '"descriptors": true'; then
  pass "$WATCH is a descriptor wallet with private keys disabled"
else
  fail "$WATCH must be loaded, descriptor-based, and created with private keys DISABLED"
fi
si=$($CLI -rpcwallet=$SIGNER getwalletinfo 2>/dev/null)
if echo "$si" | grep -q '"private_keys_enabled": true'; then
  pass "$SIGNER holds private keys"
else
  fail "$SIGNER must be loaded and hold private keys"
fi

# 3. The descriptor you exported carries a valid checksum and is active in the watch-only wallet.
if [ -s "$WORK/descriptor.txt" ]; then
  d=$(head -n1 "$WORK/descriptor.txt" | tr -d '[:space:]')
  case "$d" in *"#"????????) ;; *) fail "descriptor.txt must end in #<8-char checksum>";; esac
  if $CLI getdescriptorinfo "$d" >/dev/null 2>&1; then pass "descriptor.txt parses and its checksum is valid"; else fail "getdescriptorinfo rejects descriptor.txt"; fi
  if $CLI -rpcwallet=$WATCH listdescriptors 2>/dev/null | grep -qF "${d%%#*}"; then pass "that descriptor is imported in $WATCH"; else fail "descriptor.txt is not among $WATCH's descriptors"; fi
  case "$d" in *"prv"*) fail "descriptor.txt contains a PRIVATE key (xprv/tprv) — export the public form";; esac
else
  fail "my-work/07-psbt-descriptors-and-miniscript/descriptor.txt missing (one public descriptor with checksum)"
fi

# 4. The spend: created by the watch-only wallet, signed elsewhere, confirmed.
if [ -s "$WORK/final_txid.txt" ]; then
  txid=$(head -n1 "$WORK/final_txid.txt" | tr -d '[:space:]')
  tx=$($CLI -rpcwallet=$WATCH gettransaction "$txid" true 2>/dev/null)
  if [ -z "$tx" ]; then
    fail "$WATCH does not know txid $txid"
  else
    conf=$(echo "$tx" | sed -n 's/.*"confirmations": \([0-9-]*\).*/\1/p' | head -n1)
    if [ "${conf:-0}" -ge 1 ]; then pass "tx $txid is confirmed ($conf conf)"; else fail "tx $txid is not confirmed yet — mine a block"; fi
    if echo "$tx" | grep -q '"category": "send"'; then pass "$WATCH sees the tx as a SEND from its own coins"; else fail "the tx must spend coins that belong to $WATCH"; fi
  fi
else
  fail "my-work/07-psbt-descriptors-and-miniscript/final_txid.txt missing (the txid sendrawtransaction returned)"
fi

# 5. PSBT snapshots at each role, validated by the node itself.
for stage in created processed; do
  f="$WORK/psbt_$stage.txt"
  if [ -s "$f" ]; then
    next=$($CLI analyzepsbt "$(tr -d '[:space:]' < "$f")" 2>/dev/null | sed -n 's/.*"next": "\([a-z]*\)".*/\1/p')
    case "$stage:$next" in
      created:signer|created:updater) pass "psbt_created.txt is unsigned (next role: $next)";;
      processed:finalizer|processed:extractor) pass "psbt_processed.txt is signed (next role: $next)";;
      *) fail "psbt_$stage.txt has unexpected next role '${next:-unparseable}'";;
    esac
  else
    fail "my-work/07-psbt-descriptors-and-miniscript/psbt_$stage.txt missing"
  fi
done

# 6. Miniscript: a wsh() policy with a relative timelock, and the address you derived from it.
if [ -s "$WORK/miniscript_desc.txt" ] && [ -s "$WORK/miniscript_address.txt" ]; then
  md=$(head -n1 "$WORK/miniscript_desc.txt" | tr -d '[:space:]')
  ma=$(head -n1 "$WORK/miniscript_address.txt" | tr -d '[:space:]')
  case "$md" in wsh\(*older\(*) ok=1;; *) ok=0;; esac
  if [ $ok = 1 ] && $CLI deriveaddresses "$md" 2>/dev/null | grep -qF "\"$ma\""; then
    pass "miniscript descriptor is valid, uses wsh() + older(), and derives $ma"
  else
    fail "miniscript_desc.txt must be wsh(...older(N)...) with checksum, and derive the address in miniscript_address.txt"
  fi
else
  fail "my-work/07-psbt-descriptors-and-miniscript/miniscript_desc.txt and miniscript_address.txt missing"
fi

echo
if [ $fails -eq 0 ]; then echo "ALL CHECKS PASSED — now (and only now) compare with solutions/psbt_flow_reference.md"; else echo "$fails check(s) failed."; exit 1; fi
