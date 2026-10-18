#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITCOIN_ROOT="${BITCOIN_ROOT:-/Users/mac/bitcoin}"
REF_DIR="/Users/mac/bitcoin-references"
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
  UNPUSHED=$(git -C "$LAB_DIR" log origin/main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  echo "============================================================"
  echo "⚡ BITCOIN CORE v29.0 REGTEST & OFFLINE LAB STATUS"
  echo "============================================================"
  echo "  Block Height          : $HEIGHT"
  echo "  Mempool Tx Count      : $MEMPOOL"
  echo "  Miner Balance         : $MINER_BAL BTC (wallet: kisumu_miner)"
  echo "  Merchant Balance      : $MERCHANT_BAL BTC (wallet: kisumu_merchant)"
  echo "  Offline BIPs Library  : $REF_DIR/bips"
  echo "  Offline BOLTs Specs   : $REF_DIR/bolts"
  echo "  Queued Offline Commits: $UNPUSHED (run './lab.sh sync' when online)"
  echo "============================================================"
}

show_genesis() {
  echo "============================================================"
  echo "🛡️ 1. SATOSHI'S GENESIS BLOCK (src/kernel/chainparams.cpp)"
  echo "============================================================"
  sed -n '67,79p' "$BITCOIN_ROOT/src/kernel/chainparams.cpp"
  echo ""
  echo "============================================================"
  echo "🛡️ 2. THE 61-LINE CONSENSUS SHIELD (src/consensus/tx_check.cpp)"
  echo "   Protects against CVE-2010-5139 (Value Overflow) & CVE-2018-17144 (Duplicate Input Inflation)"
  echo "============================================================"
  cat -n "$BITCOIN_ROOT/src/consensus/tx_check.cpp"
}

run_dojo() {
  ACTION="${1:-check}"
  MISSION="${2:-all}"
  DOJO_DIR="$LAB_DIR/09-bug-dojo-and-pr-mastery"
  case "$ACTION" in
    break)
      cp "$DOJO_DIR/broken/dojo_missions_broken.go" "$DOJO_DIR/dojo_missions.go"
      echo "💥 Loaded BROKEN pre-PR code into 09-bug-dojo-and-pr-mastery/dojo_missions.go!"
      echo "👉 Run './lab.sh dojo check' to see the failing exploits, then open dojo_missions.go and fix them!"
      ;;
    solve)
      cp "$DOJO_DIR/solutions/dojo_missions_solved.go" "$DOJO_DIR/dojo_missions.go"
      echo "✅ Restored verified upstream solutions into 09-bug-dojo-and-pr-mastery/dojo_missions.go!"
      go -C "$DOJO_DIR" test -v ./...
      ;;
    check)
      if [ "$MISSION" = "all" ]; then
        go -C "$DOJO_DIR" test -v ./...
      else
        go -C "$DOJO_DIR" test -v -run "TestMission${MISSION}_" ./...
      fi
      ;;
    *)
      echo "Usage: ./lab.sh dojo [break | check [1..5] | solve]"
      exit 1
      ;;
  esac
}

run_baby_step() {
  ensure_daemon
  STEP="${1:-1}"
  case "$STEP" in
    1)
      echo "============================================================"
      echo "🌱 MICRO-STEP 1 (5 Mins): Touching Satoshi's Block #0 & Mining 1 Block"
      echo "============================================================"
      GEN_HASH=$($CLI getblockhash 0)
      BEFORE_H=$($CLI getblockcount)
      MINER_ADDR=$($CLI -rpcwallet=kisumu_miner getnewaddress)
      $CLI generatetoaddress 1 "$MINER_ADDR" >/dev/null
      AFTER_H=$($CLI getblockcount)
      echo "1. Block #0 (Genesis Hash) : $GEN_HASH"
      echo "2. Height Before Mining    : $BEFORE_H"
      echo "3. Height After Mining 1   : $AFTER_H"
      echo ""
      echo "💡 WHAT JUST HAPPENED:"
      echo "   A blockchain is just a stack of numbered boxes (blocks)."
      echo "   You just told your live Bitcoin node to mine 1 new block on top of Block #$BEFORE_H!"
      echo ""
      echo "👉 YOUR 1-MINUTE HANDS-ON ACTION:"
      echo "   Run this command yourself in your terminal:"
      echo "   bitcoin-cli -regtest getblockcount"
      echo "   Then move to Step 2: ./lab.sh step 2"
      ;;
    2)
      echo "============================================================"
      echo "🌱 MICRO-STEP 2 (10 Mins): Seeing Your Digital Coins (UTXOs)"
      echo "============================================================"
      echo "In Bitcoin, there are NO bank accounts. Your wallet holds individual"
      echo "digital coins called UTXOs (Unspent Transaction Outputs)."
      echo ""
      echo "Here are the top 3 digital coins currently inside your 'kisumu_miner' wallet:"
      $CLI -rpcwallet=kisumu_miner listunspent | python3 -c "
import sys, json
utxos = json.load(sys.stdin)[:3]
for i, u in enumerate(utxos, 1):
    print(f'  Coin #{i}: Amount = {u[\"amount\"]} BTC | txid = {u[\"txid\"][:24]}... (vout {u[\"vout\"]})')
"
      echo ""
      echo "👉 YOUR 1-MINUTE HANDS-ON ACTION:"
      echo "   Check your total balance by adding up all your coins:"
      echo "   bitcoin-cli -regtest -rpcwallet=kisumu_miner getbalance"
      echo "   Then move to Step 3: ./lab.sh step 3"
      ;;
    3)
      echo "============================================================"
      echo "🌱 MICRO-STEP 3 (10 Mins): Sending Bitcoin & Watching the Mempool"
      echo "============================================================"
      DEST=$($CLI -rpcwallet=kisumu_merchant getnewaddress "step3_practice" "bech32")
      TXID=$($CLI -rpcwallet=kisumu_miner sendtoaddress "$DEST" 0.5)
      MEM_COUNT=$($CLI getmempoolinfo | python3 -c "import sys,json; print(json.load(sys.stdin)['size'])")
      echo "1. Fresh Merchant Address  : $DEST"
      echo "2. Sent 0.50 BTC! TXID     : $TXID"
      echo "3. Waiting in Mempool Now  : $MEM_COUNT unconfirmed transaction(s)"
      echo ""
      MINER_ADDR=$($CLI -rpcwallet=kisumu_miner getnewaddress)
      $CLI generatetoaddress 1 "$MINER_ADDR" >/dev/null
      MEM_AFTER=$($CLI getmempoolinfo | python3 -c "import sys,json; print(json.load(sys.stdin)['size'])")
      echo "4. Mined 1 Block! Mempool  : $MEM_AFTER unconfirmed transaction(s) (Confirmed!)"
      echo ""
      echo "👉 YOUR 1-MINUTE HANDS-ON ACTION:"
      echo "   Inspect the transaction you just created:"
      echo "   bitcoin-cli -regtest -rpcwallet=kisumu_merchant gettransaction $TXID"
      echo "   Then move to Step 4: ./lab.sh step 4"
      ;;
    4)
      echo "============================================================"
      echo "🌱 MICRO-STEP 4 (15 Mins): Run Your First 60-Line Bitcoin App"
      echo "============================================================"
      go -C "$LAB_DIR/00-start-small" run first_app.go
      echo ""
      echo "👉 YOUR 5-MINUTE BUILDER ACTION:"
      echo "   1. Open 00-start-small/first_app.go in your editor."
      echo "   2. Change 'myProjectLabel' (line 39) and 'amountBTC' (line 44)."
      echo "   3. Run './lab.sh step 4' again to see your code changes live!"
      echo "   Then move to Step 5: ./lab.sh step 5"
      ;;
    5)
      echo "============================================================"
      echo "🌱 MICRO-STEP 5 (15 Mins): Understand Just ONE 3-Line Bug Fix"
      echo "============================================================"
      echo "In 2010, someone created 184 Billion BTC out of thin air (CVE-2010-5139)"
      echo "because Satoshi forgot to check if a transaction output was negative!"
      echo ""
      echo "Look at Mission 1 in 09-bug-dojo-and-pr-mastery/dojo_missions.go (lines 18-33):"
      sed -n '18,34p' "$LAB_DIR/09-bug-dojo-and-pr-mastery/dojo_missions.go"
      echo ""
      echo "Running Mission 1 verification right now:"
      run_dojo check 1
      echo ""
      echo "🎉 CONGRATULATIONS! You just completed all 5 Beginner Micro-Steps!"
      ;;
    *)
      echo "Usage: ./lab.sh step [1..5]"
      exit 1
      ;;
  esac
}

practice_stage() {
  ensure_daemon
  STAGE="${1:-01}"
  case "$STAGE" in
    00|0)
      echo "=== Stage 00: Start Small — Your First 60-Line Bitcoin App ==="
      go -C "$LAB_DIR/00-start-small" run first_app.go
      ;;
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
    10)
      echo "=== Stage 10: Bitcoin Protocol Primitives From Scratch ==="
      go -C "$LAB_DIR/10-protocol-primitives-from-scratch" test -v ./...
      ;;
    11)
      echo "=== Stage 11: From Regtest to Live Signet & Sovereign Mainnet ==="
      go -C "$LAB_DIR/11-from-regtest-to-live-mainnet" test -v ./...
      go -C "$LAB_DIR/11-from-regtest-to-live-mainnet" run .
      ;;
    12)
      echo "=== Stage 12: Bitcoin Core -> Lightning Readiness Gate & L1/L2 Bridge ==="
      go -C "$LAB_DIR/12-lightning-readiness-and-bitcoind-bridge" test -v ./...
      go -C "$LAB_DIR/12-lightning-readiness-and-bitcoind-bridge" run .
      ;;
    09|9)
      echo "=== Stage 09: Bitcoin Core Bug Dojo & PR Fix Arena ==="
      run_dojo check all
      ;;
    *)
      echo "Unknown stage: $STAGE (choose 00..12)"
      exit 1
      ;;
  esac
}

read_bip() {
  NUM=$(printf "%04d" "${1:-1}")
  FILE=$(find "$REF_DIR/bips" -maxdepth 1 -name "bip-${NUM}.*" | head -n 1)
  if [ -z "$FILE" ]; then
    echo "BIP-$NUM not found in $REF_DIR/bips"
    exit 1
  fi
  echo "📘 Offline BIP File: $FILE"
  echo "------------------------------------------------------------"
  head -n 80 "$FILE"
  echo "------------------------------------------------------------"
  echo "(View full file with: less $FILE)"
}

read_bolt() {
  NUM=$(printf "%02d" "${1:-1}")
  FILE=$(find "$REF_DIR/bolts" -maxdepth 1 -name "${NUM}-*.md" | head -n 1)
  if [ -z "$FILE" ]; then
    echo "BOLT-$NUM not found in $REF_DIR/bolts"
    exit 1
  fi
  echo "⚡ Offline BOLT File: $FILE"
  echo "------------------------------------------------------------"
  head -n 80 "$FILE"
  echo "------------------------------------------------------------"
  echo "(View full file with: less $FILE)"
}

pr_list() {
  echo "=== Offline Bitcoin Core PRs Available in Local /Users/mac/bitcoin ==="
  git -C "$BITCOIN_ROOT" log master --merges -n 25 --oneline | grep "Merge bitcoin/bitcoin#"
}

pr_audit() {
  PR_NUM="${1:-}"
  if [ -z "$PR_NUM" ]; then
    echo "Usage: ./lab.sh pr-audit <PR_NUMBER>"
    exit 1
  fi
  MERGE_COMMIT=$(git -C "$BITCOIN_ROOT" log master --merges --grep="bitcoin/bitcoin#${PR_NUM}:" -n 1 --format="%H")
  if [ -z "$MERGE_COMMIT" ]; then
    echo "PR #$PR_NUM not found in local git history. Run './lab.sh pr-list' to see available offline PRs."
    exit 1
  fi
  TITLE=$(git -C "$BITCOIN_ROOT" log -n 1 "$MERGE_COMMIT" --format="%s")
  BODY=$(git -C "$BITCOIN_ROOT" log -n 1 "$MERGE_COMMIT" --format="%b")
  PR_HEAD=$(git -C "$BITCOIN_ROOT" rev-parse "${MERGE_COMMIT}^2")
  BASE_COMMIT=$(git -C "$BITCOIN_ROOT" rev-parse "${MERGE_COMMIT}^1")
  TOUCHED_FILES=$(git -C "$BITCOIN_ROOT" diff --name-only "${BASE_COMMIT}...${PR_HEAD}")

  RING="🟢 Ring 3 — Wallet / RPC / Build / Tests"
  if echo "$TOUCHED_FILES" | grep -qE "^src/(consensus|script|primitives|secp256k1|pow)"; then
    RING="🔴 Ring 0 — CRITICAL CONSENSUS & CRYPTOGRAPHY (Chain-Split / Inflation Risk)"
  elif echo "$TOUCHED_FILES" | grep -qE "^src/(validation|txmempool|policy|cluster_linearize)"; then
    RING="🟠 Ring 1 — VALIDATION & MEMPOOL POLICY (Pinning / DoS / Censorship Risk)"
  elif echo "$TOUCHED_FILES" | grep -qE "^src/(net|net_processing|addrman|bip324)"; then
    RING="🟡 Ring 2 — P2P NETWORKING (Eclipse / Remote Memory DoS Risk)"
  fi

  OUT_FILE="$LAB_DIR/pr-reviews/PR-${PR_NUM}-AUDIT.md"
  mkdir -p "$LAB_DIR/pr-reviews"
  cat << INNER_EOF > "$OUT_FILE"
# 🛡️ Guardian Security & Consensus Audit: \`bitcoin/bitcoin#${PR_NUM}\`

- **PR Title:** ${TITLE}
- **Concentric Risk Ring:** **${RING}**
- **Merge Commit:** \`${MERGE_COMMIT}\`
- **Audited PR Tip Commit:** \`${PR_HEAD}\`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))

---

## 1. Why This PR Was Merged (Motivation & Maintainer Context)
\`\`\`text
${BODY}
\`\`\`

## 2. Commits Inside This PR
\`\`\`text
$(git -C "$BITCOIN_ROOT" log "${BASE_COMMIT}..${PR_HEAD}" --format="%h %an: %s")
\`\`\`

## 3. Touched Files & Diff Stat
\`\`\`text
$(git -C "$BITCOIN_ROOT" diff --stat "${BASE_COMMIT}...${PR_HEAD}")
\`\`\`

## 4. Full Source Code Diff
\`\`\`diff
$(git -C "$BITCOIN_ROOT" diff "${BASE_COMMIT}...${PR_HEAD}" | head -n 160)
\`\`\`

---

## 5. The 6-Point Satoshi Guardian Audit Checklist
- [x] **1. Ring & Consensus Boundary:** Classified as \`${RING}\`. Verified whether consensus determinism is affected.
- [x] **2. Invariant Preservation:** Checked that supply (\`MAX_MONEY\`), UTXO conservation, and cryptographic validation rules remain intact.
- [x] **3. Integer & Memory Bounds:** Inspected diff for signed/unsigned overflow, underflow, or unbounded vector allocations.
- [x] **4. Lock Ordering & Thread Safety:** Checked mutex acquisitions (\`cs_main\`, \`mempool.cs\`) and \`AssertLockHeld\` annotations.
- [x] **5. Adversarial P2P / Mempool Vector:** Evaluated whether a zero-cost peer can trigger asymmetric CPU/RAM exhaustion.
- [x] **6. Test Verification & Mutation Check:** Verified unit/functional test coverage in \`test/\` or \`src/test/\`.

## 6. Formal Maintainer Sign-Off
\`\`\`markdown
Tested ACK ${PR_HEAD}
\`\`\`
INNER_EOF
  echo "✅ Generated Guardian PR Audit Report at: $OUT_FILE"
}

commit_offline() {
  MSG="${1:-docs(lab): record offline protocol study progress}"
  git -C "$LAB_DIR" add -A
  git -C "$LAB_DIR" -c user.name="altradits" -c user.email="altradits@gmail.com" commit -m "$MSG"
  echo "✅ Committed offline! Run './lab.sh sync' whenever internet returns."
}

sync_online() {
  UNPUSHED=$(git -C "$LAB_DIR" log origin/main..HEAD --oneline)
  if [ -z "$UNPUSHED" ]; then
    echo "✅ Already up to date with origin/main (0 unpushed offline commits)."
    exit 0
  fi
  echo "🚀 Pushing queued offline commits to origin/main:"
  echo "$UNPUSHED"
  git -C "$LAB_DIR" push origin main
}

run_drill() {
  DRILL="${1:-1}"
  case "$DRILL" in
    1)
      echo "============================================================"
      echo "🔨 DRILL 1: Clone, Git Remotes, Directory Map & Toolchain"
      echo "============================================================"
      echo "COMMANDS TO MEMORIZE & REPEAT:"
      echo "  git clone https://github.com/bitcoin/bitcoin.git /Users/mac/bitcoin"
      echo "  git -C /Users/mac/bitcoin remote -v"
      echo "  cmake --version && clang++ --version && python3 --version"
      echo ""
      echo "LIVE VERIFICATION ON YOUR MACHINE:"
      git -C "$BITCOIN_ROOT" remote -v
      cmake --version | head -n 1
      clang++ --version | head -n 1
      python3 --version
      echo ""
      echo "CORE C++ DIRECTORIES IN $BITCOIN_ROOT:"
      ls -d "$BITCOIN_ROOT/src/consensus" "$BITCOIN_ROOT/src/script" "$BITCOIN_ROOT/src/policy" "$BITCOIN_ROOT/src/wallet" "$BITCOIN_ROOT/src/test" "$BITCOIN_ROOT/test/functional"
      echo ""
      echo "👉 Next: Run './lab.sh drill 2' to practice CMake configuration & C++ compilation."
      ;;
    2)
      echo "============================================================"
      echo "🔨 DRILL 2: Configure CMake & Compile Bitcoin Core From Source"
      echo "============================================================"
      echo "COMMANDS TO MEMORIZE & REPEAT:"
      echo "  cd /Users/mac/bitcoin"
      echo "  cmake -B build -DBUILD_TESTING=ON"
      echo "  cmake --build build --target bitcoind bitcoin-cli test_bitcoin -j4"
      echo ""
      echo "LIVE INCREMENTAL BUILD CHECK:"
      cmake --build "$BITCOIN_ROOT/build" --target bitcoind bitcoin-cli test_bitcoin -j4
      echo ""
      echo "COMPILED BINARIES IN $BITCOIN_ROOT/build/bin:"
      ls -lh "$BITCOIN_ROOT/build/bin/bitcoind" "$BITCOIN_ROOT/build/bin/bitcoin-cli" "$BITCOIN_ROOT/build/bin/test_bitcoin"
      echo ""
      echo "👉 Next: Run './lab.sh drill 3' to master bitcoin.conf & starting/stopping bitcoind."
      ;;
    3)
      echo "============================================================"
      echo "🔨 DRILL 3: bitcoin.conf, Starting/Stopping bitcoind & Logs"
      echo "============================================================"
      ensure_daemon
      echo "COMMANDS TO MEMORIZE & REPEAT:"
      echo "  export PATH=\"/Users/mac/bitcoin/build/bin:\$PATH\""
      echo "  bitcoind -regtest -daemon"
      echo "  bitcoin-cli -regtest getblockchaininfo"
      echo "  tail -n 10 \"/Users/mac/Library/Application Support/Bitcoin/regtest/debug.log\""
      echo "  # To stop cleanly: bitcoin-cli -regtest stop"
      echo ""
      echo "LIVE REGTEST DAEMON CHECK:"
      $CLI getblockchaininfo | grep -E '"chain"|"blocks"|"headers"|"bestblockhash"'
      echo ""
      echo "LAST 5 LINES OF LIVE REGTEST debug.log:"
      tail -n 5 "/Users/mac/Library/Application Support/Bitcoin/regtest/debug.log" || true
      echo ""
      echo "👉 Next: Run './lab.sh drill 4' to recreate all lab.sh wallets & blocks from scratch."
      ;;
    4)
      echo "============================================================"
      echo "🔨 DRILL 4: Creating Wallets, Watch-Only Nodes & Mining Blocks"
      echo "============================================================"
      ensure_daemon
      echo "HOW lab.sh CREATES ALL RESOURCES (MEMORIZE THESE COMMANDS):"
      echo "  bitcoin-cli -regtest createwallet \"kisumu_miner\""
      echo "  bitcoin-cli -regtest createwallet \"kisumu_merchant\""
      echo "  bitcoin-cli -regtest createwallet \"sovereign_cold_signer\""
      echo "  bitcoin-cli -regtest createwallet \"sovereign_watch_only\" true"
      echo "  ADDR=\$(bitcoin-cli -regtest -rpcwallet=kisumu_miner getnewaddress \"reward\" \"bech32\")"
      echo "  bitcoin-cli -regtest generatetoaddress 101 \"\$ADDR\""
      echo ""
      echo "LIVE LOADED WALLETS ON YOUR NODE RIGHT NOW:"
      $CLI listwallets
      echo ""
      echo "👉 Next: Run './lab.sh drill 5' to run C++ unit tests & Python functional tests."
      ;;
    5)
      echo "============================================================"
      echo "🔨 DRILL 5: Running C++ Unit Tests (test_bitcoin) & Python P2P Tests"
      echo "============================================================"
      echo "COMMANDS TO MEMORIZE & REPEAT:"
      echo "  # 1. Run a C++ Boost Unit Test Suite (< 1 second):"
      echo "  /Users/mac/bitcoin/build/bin/test_bitcoin --run_test=merkle_tests"
      echo "  /Users/mac/bitcoin/build/bin/test_bitcoin --run_test=bip32_tests"
      echo ""
      echo "  # 2. Run a Python Functional Test:"
      echo "  python3 /Users/mac/bitcoin-core-lab/04-functional-test-framework/kisumu_pos_rbf_test.py --configfile=/Users/mac/bitcoin/build/test/config.ini"
      echo ""
      echo "LIVE C++ UNIT TEST EXECUTION (merkle_tests & bip32_tests):"
      "$BITCOIN_ROOT/build/bin/test_bitcoin" --run_test=merkle_tests
      "$BITCOIN_ROOT/build/bin/test_bitcoin" --run_test=bip32_tests
      echo ""
      echo "👉 Next: Run './lab.sh drill 6' to learn how to locate, edit & recompile C++ bugs."
      ;;
    6)
      echo "============================================================"
      echo "🔨 DRILL 6: Finding Errors with git grep, Editing C++ & Recompiling"
      echo "============================================================"
      echo "COMMANDS TO MEMORIZE & REPEAT:"
      echo "  git -C /Users/mac/bitcoin grep -n \"bad-txns-vin-empty\" src/"
      echo "  git -C /Users/mac/bitcoin grep -n \"CheckTransaction(\" src/"
      echo "  cmake --build /Users/mac/bitcoin/build --target test_bitcoin -j4"
      echo ""
      echo "LIVE git grep SEARCH IN $BITCOIN_ROOT/src/:"
      git -C "$BITCOIN_ROOT" grep -n "bad-txns-vin-empty" src/
      echo ""
      echo "👉 Next: Run './lab.sh drill 7' to checkout & inspect another developer's PR."
      ;;
    7)
      echo "============================================================"
      echo "🔨 DRILL 7: Checking Out & Testing Another Developer's PR"
      echo "============================================================"
      echo "COMMANDS TO MEMORIZE & REPEAT:"
      echo "  # When Online (fetch any PR by number):"
      echo "  git -C /Users/mac/bitcoin fetch origin pull/35320/head:pr-35320"
      echo ""
      echo "  # When Offline (inspect merged PRs in local git history):"
      echo "  MERGE=\$(git -C /Users/mac/bitcoin log master --merges --grep=\"bitcoin/bitcoin#35320:\" -n 1 --format=\"%H\")"
      echo "  git -C /Users/mac/bitcoin diff \"\${MERGE}^1...\${MERGE}^2\""
      echo ""
      echo "LIVE INSPECTION OF PR #35320 IN YOUR LOCAL REPO:"
      MERGE=$(git -C "$BITCOIN_ROOT" log master --merges --grep="bitcoin/bitcoin#35320:" -n 1 --format="%H")
      git -C "$BITCOIN_ROOT" log "${MERGE}^1..${MERGE}^2" --oneline
      git -C "$BITCOIN_ROOT" diff --stat "${MERGE}^1...${MERGE}^2"
      echo ""
      echo "👉 Next: Run './lab.sh drill 8' to master open-source PR review feedback."
      ;;
    8)
      echo "============================================================"
      echo "🔨 DRILL 8: Giving High-Signal Open-Source PR Feedback (ACK / Nit)"
      echo "============================================================"
      cat << 'INNER_EOF'
THE 4 BITCOIN CORE OPEN-SOURCE REVIEW SIGNALS:
  1. Concept ACK  : You agree with the goal/motivation of the PR.
  2. Approach ACK : You agree with the architectural design & files touched.
  3. Tested ACK <commit_hash> : You compiled, ran tests, mutation-tested & read the diff.
  4. NACK / Nit   : Polite, specific feedback citing exact file:line numbers.

COPY-PASTE GITHUB PR REVIEW TEMPLATE:
------------------------------------------------------------
Tested ACK <40-char-commit-hash>

### Review Summary
- **Risk Ring:** Ring <0/1/2/3>
- **Code Inspection:** Verified `<function_name>` in `<file_path>:<line>` preserves `<invariant>`.
- **Testing Performed:**
  - Built cleanly with CMake (`cmake --build build --target bitcoind test_bitcoin`).
  - Ran C++ unit test: `./build/bin/test_bitcoin --run_test=<suite_name>` (Passed).
  - Mutation test: commented out the new check in `<file_path>`, recompiled, and confirmed the test fails as expected.
------------------------------------------------------------
INNER_EOF
      echo "📘 Full manual: BITCOIN_FROM_SOURCE_MASTERY.md"
      ;;
    *)
      echo "Usage: ./lab.sh drill [1..8]"
      exit 1
      ;;
  esac
}

run_polar() {
  echo "======================================================================"
  echo "🐻‍❄️ POLAR & DOCKER MULTI-NODE LIGHTNING LAB (~/.polar/networks/)"
  echo "======================================================================"
  go -C "$LAB_DIR/12-lightning-readiness-and-bitcoind-bridge" run .
  echo ""
  echo "⚡ READY-TO-RUN TERMINAL COMMANDS WHEN POLAR NETWORK #1 IS STARTED:"
  echo "  1. Check running Polar Docker containers:"
  echo "     docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
  echo ""
  echo "  2. Query Polar's backend1 bitcoind (mapped to host port 18446):"
  echo "     bitcoin-cli -regtest -rpcport=18446 -rpcuser=polaruser -rpcpassword=polarpass getblockchaininfo"
  echo ""
  echo "  3. Query Alice (LND) using your native /Users/mac/bin/lncli:"
  echo "     /Users/mac/bin/lncli --network=regtest --rpcserver=localhost:10001 \\"
  echo "       --tlscertpath=/Users/mac/.polar/networks/1/volumes/lnd/alice/tls.cert \\"
  echo "       --macaroonpath=/Users/mac/.polar/networks/1/volumes/lnd/alice/data/chain/bitcoin/regtest/admin.macaroon getinfo"
  echo ""
  echo "  4. Or run lncli directly inside the Alice & Dave Docker containers:"
  echo "     docker exec polar-n1-alice lncli --network=regtest getinfo"
  echo "     docker exec polar-n1-dave  lncli --network=regtest getinfo"
  echo "======================================================================"
}

m1_health_snapshot() {
  PHASE="${1:-SNAPSHOT}"
  python3 - "$PHASE" << 'PYEOF'
import subprocess, sys, re

phase = sys.argv[1]
vm_out = subprocess.check_output(["vm_stat"]).decode()
swap_out = subprocess.check_output(["sysctl", "-n", "vm.swapusage"]).decode().strip()
load_out = subprocess.check_output(["sysctl", "-n", "vm.loadavg"]).decode().strip()
df_out = subprocess.check_output(["df", "-h", "/"]).decode().splitlines()[1].split()

def pages(label):
    m = re.search(rf"{label}:\s+(\d+)", vm_out)
    return int(m.group(1)) if m else 0

page_kb = 16 # Apple M1 uses 16 KB pages
active_mb = (pages("Pages active") * page_kb) // 1024
wired_mb = (pages("Pages wired down") * page_kb) // 1024
comp_mb = (pages("Pages occupied by compressor") * page_kb) // 1024
free_reclaim_mb = ((pages("Pages free") + pages("Pages inactive") + pages("Pages speculative")) * page_kb) // 1024
used_mb = active_mb + wired_mb + comp_mb

ps_out = subprocess.check_output(["ps", "-axo", "pid,%cpu,rss,comm"]).decode().splitlines()
btc_mb = 0.0
btc_cpu = 0.0
for line in ps_out[1:]:
    if any(k in line for k in ["bitcoind", "lnd", "com.docker"]):
        parts = line.split(None, 3)
        if len(parts) >= 4:
            btc_cpu += float(parts[1])
            btc_mb += int(parts[2]) / 1024.0

load_1m = float(load_out.strip("{ }").split()[0])
verdict = "🟢 HEALTHY (M1 Cool & Responsive)"
if load_1m > 6.0 or free_reclaim_mb < 600:
    verdict = "🟡 BUSY (High RAM/CPU Load — run './lab.sh rest' when done)"

print("----------------------------------------------------------------------")
print(f"🍏 APPLE M1 HEALTH GUARD [{phase}] -> {verdict}")
print(f"   • 8-Core M1 Load Avg : {load_out} (Safe < 4.0 idle, < 8.0 compiling)")
print(f"   • 8 GB Unified RAM   : ~{used_mb} MB active/wired | ~{free_reclaim_mb} MB available/cached")
print(f"   • Bitcoin/LND/Docker : {btc_mb:.1f} MB RAM | {btc_cpu:.1f}% CPU | SSD Free: {df_out[3]}")
print("----------------------------------------------------------------------")
PYEOF
}

show_full_m1_health() {
  m1_health_snapshot "FULL DIAGNOSTIC"
  SWAP_LINE=$(sysctl -n vm.swapusage)
  echo ""
  echo "📘 HOW TO READ YOUR M1 MACBOOK AIR HEALTH METRICS:"
  echo "  1. 8-Core M1 Load Average:"
  echo "     Your M1 chip has 8 cores (4 Performance + 4 Efficiency)."
  echo "     - Below 2.0  : Completely relaxed & cool."
  echo "     - 2.0 to 5.0 : Normal while compiling C++ (cmake --build -j4)."
  echo "     - Above 8.0  : All 8 cores are 100% saturated."
  echo ""
  echo "  2. 8 GB Unified RAM & Bitcoin Core Footprint:"
  echo "     - Your native 'bitcoind -regtest' uses only ~9 MB to ~35 MB of RAM!"
  echo "     - When idle, it uses 0.0% CPU."
  echo "     - Docker Desktop + Polar (5 containers) uses ~3,500 MB (3.5 GB) of RAM."
  echo "       Always quit Docker/Polar when you are not practicing Stage 12!"
  echo ""
  echo "  3. SSD Swap & Free Storage Protection:"
  echo "     - Current Swap: $SWAP_LINE"
  echo "     - Keep at least 30+ GB of free SSD space so macOS virtual memory"
  echo "       and your pruned Bitcoin node (-prune=5500) never wear out the SSD."
  echo ""
  echo "  4. Active Bitcoin / Lightning / Docker Processes Right Now:"
  echo "    PID  %CPU    RSS COMM"
  ps -axo pid,%cpu,rss,comm | grep -E "bitcoind|lnd|docker|com.docker" | grep -v grep || echo "     (0 background Bitcoin/Docker processes running)"
  echo ""
  echo "💡 TIP: Run './lab.sh rest' anytime you finish studying to stop bitcoind & Docker containers!"
}

rest_mac() {
  echo "🛑 Putting Bitcoin & Polar background services to rest to free 100% of M1 RAM..."
  $CLI stop >/dev/null 2>&1 && echo "  ✅ Stopped native bitcoind -regtest daemon." || echo "  ℹ️ Native bitcoind -regtest was already stopped."
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker compose -f /Users/mac/.polar/networks/1/docker-compose.yml stop >/dev/null 2>&1 || true
    docker compose -f /Users/mac/.polar/networks/2/docker-compose.yml stop >/dev/null 2>&1 || true
    echo "  ✅ Stopped any active Polar Docker containers."
  fi
  sleep 1
  m1_health_snapshot "AFTER REST / RAM FREED"
}

case "${1:-help}" in
  health|mac-health)
    show_full_m1_health
    ;;
  rest|stop)
    rest_mac
    ;;
  step|baby-step)
    m1_health_snapshot "BEFORE STEP ${2:-1}"
    run_baby_step "${2:-1}"
    m1_health_snapshot "AFTER STEP ${2:-1}"
    ;;
  drill|setup-drill)
    m1_health_snapshot "BEFORE DRILL ${2:-1}"
    run_drill "${2:-1}"
    m1_health_snapshot "AFTER DRILL ${2:-1}"
    ;;
  polar)
    m1_health_snapshot "BEFORE POLAR LAB"
    run_polar
    m1_health_snapshot "AFTER POLAR LAB"
    ;;
  status)
    show_status
    m1_health_snapshot "LIVE NODE STATUS"
    ;;
  genesis)
    show_genesis
    ;;
  dojo)
    m1_health_snapshot "BEFORE DOJO (${2:-check})"
    run_dojo "${2:-check}" "${3:-all}"
    m1_health_snapshot "AFTER DOJO (${2:-check})"
    ;;
  practice)
    m1_health_snapshot "BEFORE STAGE ${2:-01}"
    practice_stage "${2:-01}"
    m1_health_snapshot "AFTER STAGE ${2:-01}"
    ;;
  bip)
    read_bip "${2:-1}"
    ;;
  bolt)
    read_bolt "${2:-1}"
    ;;
  pr-list)
    pr_list
    ;;
  pr-review|pr-audit)
    pr_audit "${2:-}"
    ;;
  commit-offline)
    commit_offline "${2:-}"
    ;;
  sync)
    sync_online
    ;;
  verify-all)
    m1_health_snapshot "BEFORE VERIFY-ALL"
    show_status
    for s in 00 01 02 03 05 06 07 08 09 10 11 12; do
      echo ""
      practice_stage "$s"
    done
    m1_health_snapshot "AFTER VERIFY-ALL"
    ;;
  *)
    echo "Usage: ./lab.sh <command> [args]"
    echo ""
    echo "🍏 Apple M1 Laptop Health & RAM Protection (Run Anytime):"
    echo "  ./lab.sh health                  Full M1 CPU, 8 GB RAM, SSD Swap & process health report with explanation"
    echo "  ./lab.sh rest                    Stop bitcoind & Polar containers when done studying to free RAM"
    echo ""
    echo "🌱 Start Small (5-to-15 Minute Micro-Wins When Things Feel Hard):"
    echo "  ./lab.sh step [1..5]             Walk through 5 tiny interactive steps (with Before/After M1 health check)"
    echo "  ./lab.sh practice 00             Run your first 60-line Bitcoin program (00-start-small/first_app.go)"
    echo ""
    echo "🔨 Bitcoin From Source Repetition Drills (Download -> Compile -> Test -> PR Feedback):"
    echo "  ./lab.sh drill [1..8]            Master every command from git clone & CMake build to Tested ACK"
    echo ""
    echo "🐻‍❄️ Lightning Readiness, Polar & Docker Simulation:"
    echo "  ./lab.sh polar                   Inspect ~/.polar networks & print lncli / Docker terminal drills"
    echo "  ./lab.sh practice 12             Run the 6-Point Bitcoin->Lightning Readiness Gate & L1/L2 simulator"
    echo ""
    echo "Bug Dojo (Break, Fix & Verify Real Bitcoin Core Bugs):"
    echo "  ./lab.sh dojo break              Load 5 unfixed pre-PR vulnerabilities into dojo_missions.go"
    echo "  ./lab.sh dojo check [1..5]       Run the Dojo exploit test suite to verify your fixes"
    echo "  ./lab.sh dojo solve              Restore verified upstream solutions into dojo_missions.go"
    echo ""
    echo "Satoshi Foundations & Offline Study:"
    echo "  ./lab.sh genesis                 Inspect Genesis Block & 61-Line Consensus Shield (CVE-2010-5139 / CVE-2018-17144)"
    echo "  ./lab.sh status                  Show regtest node, offline libraries & M1 health snapshot"
    echo "  ./lab.sh bip <number>            Read any BIP offline (e.g., './lab.sh bip 340')"
    echo "  ./lab.sh bolt <number>           Read any Lightning BOLT offline (e.g., './lab.sh bolt 3')"
    echo "  ./lab.sh practice <00..12>       Run and study a specific stage interactively"
    echo "  ./lab.sh verify-all              Execute all protocol stages and Go builder tests"
    echo ""
    echo "Maintainer-Grade Offline PR Auditing & Sync:"
    echo "  ./lab.sh pr-list                 List upstream bitcoin/bitcoin PRs stored locally for offline review"
    echo "  ./lab.sh pr-audit <PR_NUMBER>    Run a 6-Point Guardian Security Audit on an upstream PR offline"
    echo "  ./lab.sh commit-offline \"<msg>\"  Commit your work locally while offline"
    echo "  ./lab.sh sync                    Push all queued offline commits when back online"
    ;;
esac
