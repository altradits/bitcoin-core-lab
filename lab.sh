#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITCOIN_ROOT="${BITCOIN_ROOT:-/Users/mac/bitcoin}"
export PATH="$BITCOIN_ROOT/build/bin:$PATH"
CLI="bitcoin-cli -regtest"

ensure_daemon() {
  if ! $CLI getblockchaininfo >/dev/null 2>&1; then
    echo "⚡ Starting bitcoind -regtest daemon..."
    bitcoind -regtest -daemon
    sleep 2
  fi
  for w in kisumu_miner kisumu_merchant sovereign_cold_signer; do
    $CLI createwallet "$w" >/dev/null 2>&1 || $CLI loadwallet "$w" >/dev/null 2>&1 || true
  done
  $CLI createwallet "sovereign_watch_only" true >/dev/null 2>&1 || $CLI loadwallet "sovereign_watch_only" >/dev/null 2>&1 || true
}

show_status() {
  ensure_daemon
  HEIGHT=$($CLI getblockcount)
  MEMPOOL=$($CLI getmempoolinfo | python3 -c "import sys,json; print(json.load(sys.stdin)['size'])")
  MINER_BAL=$($CLI -rpcwallet=kisumu_miner getbalance)
  MERCHANT_BAL=$($CLI -rpcwallet=kisumu_merchant getbalance)
  echo "============================================================"
  echo "⚡ BITCOIN CORE v29.0 REGTEST LAB STATUS"
  echo "============================================================"
  echo "  Block Height      : $HEIGHT"
  echo "  Mempool Tx Count  : $MEMPOOL"
  echo "  Miner Balance     : $MINER_BAL BTC (wallet: kisumu_miner)"
  echo "  Merchant Balance  : $MERCHANT_BAL BTC (wallet: kisumu_merchant)"
  echo "============================================================"
}

practice_stage() {
  ensure_daemon
  STAGE="${1:-01}"
  case "$STAGE" in
    01|1)
      echo "=== Stage 01: Coinbase Maturity (COINBASE_MATURITY = 100) ==="
      echo "C++ Source: $BITCOIN_ROOT/src/consensus/consensus.h"
      "$LAB_DIR/01-node-foundations/verify_coinbase_maturity.sh"
      ;;
    02|2)
      echo "=== Stage 02: Raw Transactions, Implicit Fees & SegWit Weight ==="
      echo "C++ Source: $BITCOIN_ROOT/src/consensus/tx_verify.cpp"
      "$LAB_DIR/02-raw-tx-and-mempool/raw_tx_mempool.sh"
      ;;
    03|3)
      echo "=== Stage 03: BIP125 RBF & Child-Pays-For-Parent (CPFP) ==="
      echo "C++ Source: $BITCOIN_ROOT/src/policy/rbf.cpp"
      "$LAB_DIR/03-rbf-and-cpfp/rbf_and_cpfp.sh"
      ;;
    04|4)
      echo "=== Stage 04: Python Functional Test Framework (2-Node P2P) ==="
      echo "Python Source: $LAB_DIR/04-functional-test-framework/kisumu_pos_rbf_test.py"
      python3 "$LAB_DIR/04-functional-test-framework/kisumu_pos_rbf_test.py" --configfile="$BITCOIN_ROOT/build/test/config.ini"
      ;;
    05|5)
      echo "=== Stage 05: BIP431 TRUC (v3) & 1P1C Package Relay ==="
      echo "C++ Source: $BITCOIN_ROOT/src/policy/truc_policy.cpp"
      "$LAB_DIR/05-truc-package-relay-review/truc_1p1c_package.sh"
      ;;
    06|6)
      echo "=== Stage 06: Lightning P2WSH HTLC State Machine ==="
      echo "C++ Source: $BITCOIN_ROOT/src/script/interpreter.cpp"
      python3 "$LAB_DIR/06-lightning-htlc-state-machine/verify_htlc.py"
      ;;
    07|7)
      echo "=== Stage 07: BIP380 Descriptors & BIP174 Airgapped PSBT ==="
      echo "C++ Source: $BITCOIN_ROOT/src/script/descriptor.cpp & src/psbt.h"
      go -C "$LAB_DIR/07-psbt-descriptors-and-miniscript" test -v ./...
      go -C "$LAB_DIR/07-psbt-descriptors-and-miniscript" run .
      ;;
    08|8)
      echo "=== Stage 08: Sovereign Bitcoin Builder Starter Kit ==="
      go -C "$LAB_DIR/08-builder-starter-kit" test -v ./...
      go -C "$LAB_DIR/08-builder-starter-kit" run . --demo
      ;;
    *)
      echo "Unknown stage: $STAGE (choose 01..08)"
      exit 1
      ;;
  esac
}

case "${1:-help}" in
  status)
    show_status
    ;;
  practice)
    practice_stage "${2:-01}"
    ;;
  verify-all)
    show_status
    for s in 01 02 03 05 06 07 08; do
      echo ""
      practice_stage "$s"
    done
    ;;
  *)
    echo "Usage: ./lab.sh [status | practice <01..08> | verify-all]"
    echo ""
    echo "Commands:"
    echo "  ./lab.sh status          Show bitcoind regtest height, mempool & wallet balances"
    echo "  ./lab.sh practice 01..08 Run and study a specific stage interactively"
    echo "  ./lab.sh verify-all      Execute all protocol stages and Go builder tests"
    ;;
esac
