#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BITCOIN_ROOT="${BITCOIN_ROOT:-$HOME/bitcoin}"
REF_DIR="${BITCOIN_REFERENCES:-$HOME/bitcoin-references}"
export PATH="$BITCOIN_ROOT/build/bin:$PATH"
CLI="bitcoin-cli -regtest"

ensure_daemon() {
  if ! $CLI getblockchaininfo >/dev/null 2>&1; then
    echo "⚡ Starting bitcoind -regtest daemon..."
    # fallbackfee lets wallet sends work on a fresh regtest chain with no fee history.
    bitcoind -regtest -daemon -fallbackfee=0.00001
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
      echo "Usage: ./lab.sh dojo [break | check [1..6] | solve]"
      exit 1
      ;;
  esac
}

run_baby_step() {
  STEP="${1:-1}"
  local ws="$LAB_DIR/00-start-small/exercises/01-micro-steps.md"
  echo "🌱 Micro-step $STEP lives in your Stage 00 worksheet — you type every command yourself:"
  echo "   $ws"
  echo ""
  awk -v n="$STEP" 'BEGIN{p=0} /^## /{p=($0 ~ ("Step " n "[^0-9]") || $0 ~ ("Step " n "$"))} p' "$ws" 2>/dev/null | head -40
  echo ""
  echo "When you have done it: ./00-start-small/check_micro_steps.sh"
}

# ---------------------------------------------------------------------------
# Stage helpers (no shortcuts: they show worksheets, run checkers, and swap Go skeletons;
# they never perform an exercise for you)
# ---------------------------------------------------------------------------
stage_dir() {
  local n; n=$(printf "%02d" "$((10#${1:-0}))" 2>/dev/null) || { echo ""; return; }
  ls -d "$LAB_DIR/${n}-"* 2>/dev/null | head -1
}

stage_checkers() {  # prints the checker commands for a stage, one per line (relative to the stage dir)
  case "$(printf "%02d" "$((10#$1))")" in
    00) printf '%s\n' ./check_micro_steps.sh ./check_first_app.sh ;;
    01) printf '%s\n' ./check_conf.sh ./check_node_procedure.sh ./check_coinbase.sh ;;
    02) printf '%s\n' ./check_setup.sh ./check_decode.sh ./check_raw_tx.sh ./check_policy.sh ;;
    03) printf '%s\n' ./check_rbf.sh ./check_cpfp.sh ./check_code_reading.sh ;;
    04) printf '%s\n' ./check_anatomy.sh ./check_functional_test.sh "./check_functional_test.sh --mutation" ;;
    05) printf '%s\n' ./check_truc.sh ./check_review_notes.sh ;;
    06) printf '%s\n' ./check_htlc_script.sh ./check_htlc_spends.sh ./check_bolt3.sh ;;
    07) printf '%s\n' GO ./check_psbt_flow.sh ;;
    08) printf '%s\n' GO ;;
    09) printf '%s\n' GO ./check_mission6.sh ;;
    10) printf '%s\n' GO ;;
    11) printf '%s\n' GO ./check_confs.sh ./check_wallet_drill.sh ;;
    12) printf '%s\n' GO ./check_lnd_conf.sh ./check_polar_journal.sh ;;
    13) printf '%s\n' ./check_13.sh ;;
    14) printf '%s\n' ./check_14.sh ;;
    15) printf '%s\n' ./check_15.sh ;;
    16) printf '%s\n' "python3 test_tagged_hash.py" ;;
    17) printf '%s\n' "python3 check_fuzz_target.py" "python3 check_bisect.py" ;;
    18) printf '%s\n' "python3 test_linearize.py" ./check_18.sh ;;
    19) printf '%s\n' ./check_gauntlet.sh ./check_commit_hygiene.sh ;;
  esac
}

stage_info() {
  local d; d="$(stage_dir "$1")"
  [ -n "$d" ] || { echo "Unknown stage: $1 (00..19)"; exit 1; }
  echo "=== $(basename "$d") ==="
  echo "README   : $d/README.md"
  [ -d "$d/exercises" ] && { echo "Worksheets:"; ls "$d/exercises" | sed 's/^/  exercises\//'; }
  echo "Checkers (./lab.sh check $1):"
  stage_checkers "$1" | sed 's/^GO$/go vet + go test (your code at the stage root)/; s/^/  /'
  echo "Journal  : my-work/$(basename "$d")/journal.md"
  echo ""
  echo "Open solutions/ only after a checker passes or after 3 honest attempts."
}

stage_check() {
  local d; d="$(stage_dir "$1")"
  [ -n "$d" ] || { echo "Unknown stage: $1 (00..19)"; exit 1; }
  local fails=0
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    echo ""
    if [ "$c" = GO ]; then
      echo ">>> go vet + go test in $(basename "$d")"
      (cd "$d" && go vet . && go test .) || fails=$((fails+1))
    else
      echo ">>> $c"
      (cd "$d" && eval "$c") || fails=$((fails+1))
    fi
  done < <(stage_checkers "$1")
  echo ""
  [ "$fails" -eq 0 ] && echo "✅ Stage $1: every checker passed." || echo "❌ Stage $1: $fails checker(s) failed. Read the FAIL lines above."
  [ "$fails" -eq 0 ]
}

stage_swap() {  # $1 = blank|solve, $2 = stage; Go stages with exercises/*.go only
  local mode="$1" d; d="$(stage_dir "$2")"
  [ -n "$d" ] && ls "$d"/exercises/*.go >/dev/null 2>&1 || { echo "Stage $2 has no Go skeleton (stages 07, 08, 10, 11, 12)."; exit 1; }
  local bak="$LAB_DIR/my-work/$(basename "$d")/backups/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$bak"
  for f in "$d"/exercises/*.go; do
    local name; name="$(basename "$f")"
    [ -f "$d/$name" ] && cp "$d/$name" "$bak/$name"
    if [ "$mode" = blank ]; then cp "$f" "$d/$name"; else cp "$d/solutions/$name" "$d/$name"; fi
  done
  echo "Your previous files were saved in $bak"
  if [ "$mode" = blank ]; then echo "✏️  Fresh skeleton in $(basename "$d"). Write every TODO, then ./lab.sh check $2"
  else echo "📖 Reference solution copied into $(basename "$d") (spoiler). Restore your own work from the backup when done reading."; fi
}

lab_selftest() {  # for maintainers: checks the lab itself, never touches your work
  local fails=0 tmp; tmp="$(mktemp -d)"
  echo ">>> shell syntax"; for f in "$LAB_DIR"/lab.sh "$LAB_DIR"/*/check_*.sh "$LAB_DIR"/*/solutions/*.sh; do bash -n "$f" || { echo "syntax: $f"; fails=$((fails+1)); }; done
  echo ">>> python compile"; for f in "$LAB_DIR"/*/*.py "$LAB_DIR"/*/exercises/*.py "$LAB_DIR"/*/solutions/*.py; do [ -f "$f" ] && { python3 -m py_compile "$f" 2>/dev/null || { echo "py_compile: $f"; fails=$((fails+1)); }; }; done
  echo ">>> Go stages: skeleton must FAIL, solution must PASS"
  for n in 07 08 10 11 12; do
    local d; d="$(stage_dir $n)"; rm -rf "$tmp/s"; cp -R "$d" "$tmp/s"
    for f in "$d"/exercises/*.go; do cp "$f" "$tmp/s/"; done
    (cd "$tmp/s" && go vet . >/dev/null 2>&1 && ! go test . >/dev/null 2>&1) && echo "  $n skeleton fails: ok" || { echo "  $n skeleton: UNEXPECTED"; fails=$((fails+1)); }
    for f in "$d"/exercises/*.go; do cp "$d/solutions/$(basename "$f")" "$tmp/s/"; done
    (cd "$tmp/s" && go test . >/dev/null 2>&1) && echo "  $n solution passes: ok" || { echo "  $n solution: FAILS"; fails=$((fails+1)); }
  done
  local d9; d9="$(stage_dir 09)"; rm -rf "$tmp/s"; cp -R "$d9" "$tmp/s"; cp "$d9/solutions/dojo_missions_solved.go" "$tmp/s/dojo_missions.go"; rm -f "$tmp/s/mission6_test.go"
  (cd "$tmp/s" && go test . >/dev/null 2>&1) && echo "  09 solution passes: ok" || { echo "  09 solution: FAILS"; fails=$((fails+1)); }
  cp "$d9/broken/dojo_missions_broken.go" "$tmp/s/dojo_missions.go"
  (cd "$tmp/s" && ! go test . >/dev/null 2>&1) && echo "  09 broken fails: ok" || { echo "  09 broken: UNEXPECTED"; fails=$((fails+1)); }
  echo ">>> Stage 18 linearize reference"; python3 "$LAB_DIR/18-cluster-mempool-wallet-and-policy/test_linearize.py" "$LAB_DIR/18-cluster-mempool-wallet-and-policy/solutions/linearize.py" | tail -1
  rm -rf "$tmp"
  echo ""; [ "$fails" -eq 0 ] && echo "✅ Lab self-test passed." || echo "❌ Lab self-test: $fails problem(s)."
  [ "$fails" -eq 0 ]
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
  echo "=== Offline Bitcoin Core PRs Available in $BITCOIN_ROOT ==="
  git -C "$BITCOIN_ROOT" log master --merges -n 25 --oneline | grep "Merge bitcoin/bitcoin#"
}

pr_audit() {
  PR_NUM="${1:-}"
  if [ -z "$PR_NUM" ]; then
    echo "Usage: ./lab.sh pr-audit <PR_NUMBER>"
    exit 1
  fi
  MERGE_COMMIT=$(git -C "$BITCOIN_ROOT" log master --merges --grep="bitcoin/bitcoin#${PR_NUM}:" -n 1 --format="%H")
  if [ -n "$MERGE_COMMIT" ]; then
    TITLE=$(git -C "$BITCOIN_ROOT" log -n 1 "$MERGE_COMMIT" --format="%s")
    BODY=$(git -C "$BITCOIN_ROOT" log -n 1 "$MERGE_COMMIT" --format="%b")
    PR_HEAD=$(git -C "$BITCOIN_ROOT" rev-parse "${MERGE_COMMIT}^2")
    BASE_COMMIT=$(git -C "$BITCOIN_ROOT" rev-parse "${MERGE_COMMIT}^1")
  else
    if ! git -C "$BITCOIN_ROOT" rev-parse --verify "pr-${PR_NUM}" >/dev/null 2>&1; then
      echo "🌐 Fetching live unmerged PR #${PR_NUM} from GitHub into branch pr-${PR_NUM}..."
      git -C "$BITCOIN_ROOT" fetch origin "pull/${PR_NUM}/head:pr-${PR_NUM}" || {
        echo "PR #$PR_NUM not found locally and could not be fetched."
        exit 1
      }
    fi
    MERGE_COMMIT="UNMERGED (local branch pr-${PR_NUM}; confirm open vs closed on GitHub)"
    PR_HEAD=$(git -C "$BITCOIN_ROOT" rev-parse "pr-${PR_NUM}")
    BASE_COMMIT=$(git -C "$BITCOIN_ROOT" merge-base master "$PR_HEAD")
    TITLE=$(git -C "$BITCOIN_ROOT" log -n 1 "$PR_HEAD" --format="%s")
    BODY=$(git -C "$BITCOIN_ROOT" log -n 1 "$PR_HEAD" --format="%b")
  fi
  TOUCHED_FILES=$(git -C "$BITCOIN_ROOT" diff --name-only "${BASE_COMMIT}...${PR_HEAD}")

  RING="🟢 Ring 3 — Wallet / RPC / Build / Tests"
  if echo "$TOUCHED_FILES" | grep -qE "^src/(consensus|script|primitives|secp256k1|pow|crypto)"; then
    RING="🔴 Ring 0 — CRITICAL CONSENSUS & CRYPTOGRAPHY (Chain-Split / Inflation Risk)"
  elif echo "$TOUCHED_FILES" | grep -qE "^src/(validation|txmempool|policy|cluster_linearize)"; then
    RING="🟠 Ring 1 — VALIDATION & MEMPOOL POLICY (Pinning / DoS / Censorship Risk)"
  elif echo "$TOUCHED_FILES" | grep -qE "^src/(net|net_processing|addrman|bip324)"; then
    RING="🟡 Ring 2 — P2P NETWORKING (Eclipse / Remote Memory DoS Risk)"
  fi

  OUT_FILE="$LAB_DIR/pr-reviews/PR-${PR_NUM}-AUDIT.md"
  mkdir -p "$LAB_DIR/pr-reviews"
  SECTION1="Why This PR Exists (Motivation & Maintainer Context)"
  case "$MERGE_COMMIT" in
    UNMERGED*) ;;
    *) SECTION1="Why This PR Was Merged (Motivation & Maintainer Context)" ;;
  esac
  cat << INNER_EOF > "$OUT_FILE"
# Audit: \`bitcoin/bitcoin#${PR_NUM}\` \`${TITLE}\`

- **PR Title:** ${TITLE}
- **Concentric Risk Ring:** **${RING}**
- **Merge Commit:** \`${MERGE_COMMIT}\`
- **Audited PR Tip Commit:** \`${PR_HEAD}\`
- **Auditor:** Stanley Chege Thuita ([@altradits](https://github.com/altradits))
- **Checked:** $(date +%F)

---

## 1. ${SECTION1}
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

## 5. Review checklist (YOURS to tick — nothing below was checked for you)
- [ ] **1. Risk area:** Which subsystem and invariant does this PR touch? Is consensus affected? (The ring \`${RING}\` was assigned by a script.)
- [ ] **2. Invariants:** Which invariants must hold, and how did you check them?
- [ ] **3. Bounds:** Overflow/underflow, unbounded containers or loops reachable by a peer or RPC caller?
- [ ] **4. Locking:** Which mutexes are taken; do the annotations still hold?
- [ ] **5. Adversarial input:** Can an untrusted peer or caller make the node do expensive work?
- [ ] **6. Tests:** Do the PR's tests fail without the change (mutation)? What did you run, on which commit?

## 6. Your conclusion (from YOUR OWN testing; never post text you did not write)
- Commit I reviewed: \`________\`
- What I built and ran: ________
- Manual testing beyond the PR's tests: ________
- Questions for the author: ________
- My conclusion: ________
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
      echo "  git clone https://github.com/bitcoin/bitcoin.git \"\$HOME/bitcoin\""
      echo "  git -C \"$BITCOIN_ROOT\" remote -v"
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
      echo "  cd \"$BITCOIN_ROOT\""
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
      echo "  export PATH=\"$BITCOIN_ROOT/build/bin:\$PATH\""
      echo "  bitcoind -regtest -daemon"
      echo "  bitcoin-cli -regtest getblockchaininfo"
      echo "  tail -n 10 \"$HOME/Library/Application Support/Bitcoin/regtest/debug.log\""
      echo "  # To stop cleanly: bitcoin-cli -regtest stop"
      echo ""
      echo "LIVE REGTEST DAEMON CHECK:"
      $CLI getblockchaininfo | grep -E '"chain"|"blocks"|"headers"|"bestblockhash"'
      echo ""
      echo "LAST 5 LINES OF LIVE REGTEST debug.log:"
      tail -n 5 "$HOME/Library/Application Support/Bitcoin/regtest/debug.log" 2>/dev/null || tail -n 5 "$HOME/.bitcoin/regtest/debug.log" 2>/dev/null || true
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
      echo "  $BITCOIN_ROOT/build/bin/test_bitcoin --run_test=merkle_tests"
      echo "  $BITCOIN_ROOT/build/bin/test_bitcoin --run_test=bip32_tests"
      echo ""
      echo "  # 2. Run a Python Functional Test:"
      echo "  python3 $LAB_DIR/my-work/04-functional-test-framework/kisumu_pos_rbf_test.py --configfile=$BITCOIN_ROOT/build/test/config.ini"
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
      echo "  git -C \"$BITCOIN_ROOT\" grep -n \"bad-txns-vin-empty\" src/"
      echo "  git -C \"$BITCOIN_ROOT\" grep -n \"CheckTransaction(\" src/"
      echo "  cmake --build $BITCOIN_ROOT/build --target test_bitcoin -j4"
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
      echo "  git -C \"$BITCOIN_ROOT\" fetch origin pull/35320/head:pr-35320"
      echo ""
      echo "  # When Offline (inspect merged PRs in local git history):"
      echo "  MERGE=\$(git -C \"$BITCOIN_ROOT\" log master --merges --grep=\"bitcoin/bitcoin#35320:\" -n 1 --format=\"%H\")"
      echo "  git -C \"$BITCOIN_ROOT\" diff \"\${MERGE}^1...\${MERGE}^2\""
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
REVIEW SIGNALS (read CONTRIBUTING.md "Peer Review" on master for the exact wording):
  1. Concept (N)ACK  : you do (not) agree with the goal of the PR.
  2. Approach (N)ACK : Concept ACK, and you do (not) agree with the approach.
  3. ACK <commit>    : you reviewed the code at that commit; say what you tested
                       (change-specific manual testing) or that you did not test.
  4. NACK            : must include a rationale.

There is deliberately NO copy-paste template here. Write each review from your own notes:
use 19-review-and-contribution-practicum/exercises/templates/review-notes.md to organise them.
INNER_EOF
      echo "📘 Full manual: BUILDING_BITCOIN_CORE_FROM_SOURCE.md"
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
  LNCLI="$(command -v lncli || echo "$HOME/bin/lncli")"
  echo "  3. Query Alice (LND) using your native lncli ($LNCLI):"
  echo "     $LNCLI --network=regtest --rpcserver=localhost:10001 \\"
  echo "       --tlscertpath=$HOME/.polar/networks/1/volumes/lnd/alice/tls.cert \\"
  echo "       --macaroonpath=$HOME/.polar/networks/1/volumes/lnd/alice/data/chain/bitcoin/regtest/admin.macaroon getinfo"
  echo ""
  echo "  4. Or run lncli directly inside the Alice & Dave Docker containers:"
  echo "     docker exec polar-n1-alice lncli --network=regtest getinfo"
  echo "     docker exec polar-n1-dave  lncli --network=regtest getinfo"
  echo "======================================================================"
}

# ver_at_least NEED HAVE: true when HAVE >= NEED (dotted major.minor).
ver_at_least() {
  NEED_MAJOR=$(echo "$1" | cut -d. -f1); NEED_MINOR=$(echo "$1" | cut -d. -f2)
  HAVE_MAJOR=$(echo "$2" | cut -d. -f1); HAVE_MINOR=$(echo "$2" | cut -d. -f2 | sed 's/[^0-9].*//')
  [ "$HAVE_MAJOR" -gt "$NEED_MAJOR" ] && return 0
  [ "$HAVE_MAJOR" -lt "$NEED_MAJOR" ] && return 1
  [ "${HAVE_MINOR:-0}" -ge "${NEED_MINOR:-0}" ]
}

doctor_check() {
  FAIL=0
  if command -v git >/dev/null 2>&1; then
    echo "OK: git $(git --version | awk '{print $3}')"
  else
    echo "MISSING: git (install Xcode tools on Mac, git on Linux)"; FAIL=1
  fi
  if command -v go >/dev/null 2>&1; then
    GO_V=$(go version | sed -E 's/.*go([0-9]+\.[0-9]+).*/\1/')
    if ver_at_least "1.22" "$GO_V"; then
      echo "OK: go $GO_V (need 1.22+)"
    else
      echo "MISSING: go $GO_V is older than 1.22"; FAIL=1
    fi
  else
    echo "MISSING: go 1.22+ (https://go.dev/dl/)"; FAIL=1
  fi
  if command -v python3 >/dev/null 2>&1; then
    PY_V=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
    if ver_at_least "3.10" "$PY_V"; then
      echo "OK: python3 $PY_V (need 3.10+)"
    else
      echo "MISSING: python3 $PY_V is older than 3.10"; FAIL=1
    fi
  else
    echo "MISSING: python3 3.10+"; FAIL=1
  fi
  if command -v bitcoind >/dev/null 2>&1 && command -v bitcoin-cli >/dev/null 2>&1; then
    CORE_V=$(bitcoind --version 2>/dev/null | head -n 1 | sed -E 's/.*version v?([0-9]+\.[0-9]+).*/\1/')
    echo "OK: bitcoind/bitcoin-cli ${CORE_V:-present} (lab tested with v29.0)"
    case "${CORE_V:-}" in
      29.*) ;;
      *) echo "WARN: lab steps match v29.0 output; other versions may differ" ;;
    esac
  else
    echo "MISSING: bitcoind and bitcoin-cli on PATH (add your build/bin)"; FAIL=1
  fi
  if $CLI getblockchaininfo >/dev/null 2>&1; then
    echo "OK: regtest node reachable ($CLI)"
  else
    echo "MISSING: no regtest node at default port (run: bitcoind -regtest -daemon -fallbackfee=0.00001)"; FAIL=1
  fi
  if [ -x "$BITCOIN_ROOT/build/bin/test_bitcoin" ] && [ -f "$BITCOIN_ROOT/build/test/functional/test_runner.py" ]; then
    echo "OK: Bitcoin Core build at $BITCOIN_ROOT (stage 04 needs it)"
  else
    echo "WARN: no built tree at $BITCOIN_ROOT (set BITCOIN_ROOT; stage 04 needs it)"
  fi
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo "OK: docker running (stage 12 Polar needs it)"
  else
    echo "INFO: docker not running (only stage 12 Polar needs it)"
  fi
  [ -d "$HOME/.polar/networks" ] && echo "OK: Polar networks in ~/.polar" || echo "INFO: no ~/.polar networks (only stage 12 needs them)"
  if [ "$FAIL" = "1" ]; then
    echo "doctor: REQUIRED pieces missing (see MISSING lines above)"
    return 1
  fi
  echo "doctor: all required tools present"
}

m1_health_snapshot() {
  PHASE="${1:-SNAPSHOT}"
  # Health snapshot needs macOS tools (vm_stat, sysctl vm.*). Skip quietly elsewhere.
  if [ "$(uname -s)" != "Darwin" ]; then
    return 0
  fi
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
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "The full health report needs macOS (vm_stat, sysctl vm.*). Nothing to show on $(uname -s)."
    return 0
  fi
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
    STOPPED=0
    for compose in "$HOME"/.polar/networks/*/docker-compose.yml; do
      [ -f "$compose" ] || continue
      docker compose -f "$compose" stop >/dev/null 2>&1 || true
      STOPPED=1
    done
    if [ "$STOPPED" = "1" ]; then
      echo "  ✅ Stopped any active Polar Docker containers."
    else
      echo "  ℹ️ No Polar networks found under ~/.polar/networks."
    fi
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
    run_baby_step "${2:-1}"
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
  practice|stage)
    stage_info "${2:-00}"
    ;;
  check)
    stage_check "${2:?usage: ./lab.sh check <00..19>}"
    ;;
  blank|solve)
    stage_swap "$1" "${2:?usage: ./lab.sh $1 <07|08|10|11|12>}"
    ;;
  selftest)
    lab_selftest
    ;;
  doctor)
    doctor_check
    ;;
  bip)
    read_bip "${2:-1}"
    ;;
  bolt)
    read_bolt "${2:-1}"
    ;;
  book|library)
    BOOK_ID="${2:-index}"
    CHAPTER="${3:-}"
    case "$BOOK_ID" in
      mb|pb|cli|ln|mastering-bitcoin|programming-bitcoin|learning-bitcoin-cli|mastering-lightning)
        if [ ! -d "$REF_DIR/books" ]; then
          echo "No local book library at $REF_DIR/books."
          echo "Clone the books into \$HOME/bitcoin-references/books, or set BITCOIN_REFERENCES."
          echo "See LICENSES.md for the book list and licences."
          exit 1
        fi
        ;;
    esac
    case "$BOOK_ID" in
      index|list|"")
        cat "$LAB_DIR/offline-library/OFFLINE_INDEX.md"
        ;;
      1|go)
        cat "$LAB_DIR/offline-library/books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md"
        ;;
      2|cpp|python)
        cat "$LAB_DIR/offline-library/books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md"
        ;;
      3|crypto)
        cat "$LAB_DIR/offline-library/books/BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md"
        ;;
      4|tx|script|consensus)
        cat "$LAB_DIR/offline-library/books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md"
        ;;
      5|lightning|lnd)
        cat "$LAB_DIR/offline-library/books/BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md"
        ;;
      mb|mastering-bitcoin)
        if [ -z "$CHAPTER" ]; then
          echo "📘 Mastering Bitcoin (Offline at $REF_DIR/books/mastering-bitcoin/):"
          ls "$REF_DIR/books/mastering-bitcoin/"ch*.adoc
          echo "👉 Run: ./lab.sh book mb ch04  (or any ch01..ch12)"
        else
          FILE=$(ls "$REF_DIR/books/mastering-bitcoin/${CHAPTER}"*.adoc 2>/dev/null | head -n 1)
          if [ -z "$FILE" ]; then
            echo "Chapter '$CHAPTER' not found. Try: ./lab.sh book mb"
            exit 1
          fi
          head -n 120 "$FILE"
          echo "--- (Read full chapter: less $FILE) ---"
        fi
        ;;
      pb|programming-bitcoin)
        if [ -z "$CHAPTER" ]; then
          echo "📘 Programming Bitcoin by Jimmy Song (Offline at $REF_DIR/books/programming-bitcoin/):"
          ls "$REF_DIR/books/programming-bitcoin/"ch*.asciidoc
          echo "👉 Run: ./lab.sh book pb ch05  (or any ch01..ch13)"
        else
          head -n 120 "$REF_DIR/books/programming-bitcoin/${CHAPTER}.asciidoc"
          echo "--- (Read full chapter: less $REF_DIR/books/programming-bitcoin/${CHAPTER}.asciidoc) ---"
        fi
        ;;
      cli|learning-bitcoin-cli)
        if [ -z "$CHAPTER" ]; then
          echo "📘 Learning Bitcoin from the Command Line (Offline at $REF_DIR/books/learning-bitcoin-cli/):"
          ls "$REF_DIR/books/learning-bitcoin-cli/"[0-9][0-9]_*.md
          echo "👉 Run: ./lab.sh book cli 04   (or any 01..20 prefix)"
        else
          FILE=$(find "$REF_DIR/books/learning-bitcoin-cli" -maxdepth 1 -name "${CHAPTER}_*.md" | head -n 1)
          head -n 120 "$FILE"
          echo "--- (Read full chapter: less $FILE) ---"
        fi
        ;;
      ln|mastering-lightning)
        if [ -z "$CHAPTER" ]; then
          echo "⚡ Mastering the Lightning Network (Offline at $REF_DIR/books/mastering-lightning/):"
          ls "$REF_DIR/books/mastering-lightning/"[0-9][0-9]_*.asciidoc
          echo "👉 Run: ./lab.sh book ln 07    (or any 01..16 prefix)"
        else
          FILE=$(find "$REF_DIR/books/mastering-lightning" -maxdepth 1 -name "${CHAPTER}_*.asciidoc" | head -n 1)
          head -n 120 "$FILE"
          echo "--- (Read full chapter: less $FILE) ---"
        fi
        ;;
      *)
        echo "Unknown book '$BOOK_ID'. Use: 1..5, mb, pb, cli, ln, or index"
        ;;
    esac
    ;;
  recall)
    ACTION="${2:-check}"
    m1_health_snapshot "BEFORE BLIND RECALL ($ACTION)"
    case "$ACTION" in
      blank)
        cp "$LAB_DIR/offline-library/books/.blank_memory_drills.go" "$LAB_DIR/offline-library/books/memory_drills.go"
        echo "🧠 Blanked out all 8 building-block functions in offline-library/books/memory_drills.go!"
        echo "👉 Open offline-library/books/memory_drills.go and implement them 100% from memory."
        echo "👉 Run './lab.sh recall check' to test your recall, or './lab.sh book 1..5' if you need to review."
        ;;
      solve)
        cp "$LAB_DIR/offline-library/books/.solved_memory_drills.go" "$LAB_DIR/offline-library/books/memory_drills.go"
        echo "✅ Restored verified reference implementations into offline-library/books/memory_drills.go!"
        go -C "$LAB_DIR/offline-library/books" test -v ./...
        ;;
      check|*)
        echo "🧠 Running 8 Blind-Recall Building Block Tests (offline-library/books/memory_drills.go)..."
        go -C "$LAB_DIR/offline-library/books" test -v ./...
        ;;
    esac
    m1_health_snapshot "AFTER BLIND RECALL ($ACTION)"
    ;;
  pr-list)
    pr_list
    ;;
  pr-review|pr-audit)
    pr_audit "${2:-}"
    ;;
  journeys|pr-journeys)
    if [ -z "${2:-}" ]; then
      cat "$LAB_DIR/pr-reviews/merged-journeys/README.md"
    else
      JOURNEY_FILE="$LAB_DIR/pr-reviews/merged-journeys/PR-${2}-JOURNEY.md"
      if [ ! -f "$JOURNEY_FILE" ]; then
        echo "🌐 Downloading PR #${2} review journey from bitcoin/bitcoin..."
        git -C "$BITCOIN_ROOT" fetch origin "pull/${2}/head:pr-${2}" || true
        python3 - "${2}" "$LAB_DIR" "$BITCOIN_ROOT" << 'PYEOF'
import sys, subprocess, json, os
pr = int(sys.argv[1])
lab_dir = sys.argv[2]
btc_root = sys.argv[3]
out_dir = f"{lab_dir}/pr-reviews/merged-journeys"
os.makedirs(f"{out_dir}/raw", exist_ok=True)
cmd1 = ["gh", "pr", "view", str(pr), "--repo", "bitcoin/bitcoin", "--json", "number,title,author,body,state,mergedAt,mergeCommit,headRefOid,comments,reviews,files"]
data = json.loads(subprocess.run(cmd1, capture_output=True, text=True, check=True).stdout)
cmd2 = ["gh", "api", f"repos/bitcoin/bitcoin/pulls/{pr}/comments", "--paginate"]
data["inline_review_comments"] = json.loads(subprocess.run(cmd2, capture_output=True, text=True, check=True).stdout)
with open(f"{out_dir}/raw/pr-{pr}.json", "w") as f:
    json.dump(data, f, indent=2)
stat_res = subprocess.run(["git", "-C", btc_root, "show", "--stat", f"pr-{pr}"], capture_output=True, text=True)
md = [
    f"# PR #{pr} Review Journey: `{data['title']}`\n",
    f"- **Author:** `@{data['author']['login']}`",
    f"- **State / Merged At:** `{data['state']}` / `{data.get('mergedAt')}`",
    f"- **Head Commit:** `{data['headRefOid']}`\n---\n",
    "## 1. Original PR Description\n```text\n" + (data.get("body") or "").strip() + "\n```\n",
    "## 2. Commit & Diff Stat\n```text\n" + stat_res.stdout.strip() + "\n```\n",
    "## 3. Inline Code Review Comments\n"
]
for ic in data.get("inline_review_comments", []):
    md.append(f"### `@{ic['user']['login']}` on `{ic.get('path')}:{ic.get('line') or ic.get('original_line')}`\n> " + ic.get("body", "").strip().replace("\n", "\n> ") + "\n")
md.append("## 4. General Discussion & Maintainer Feedback\n")
for c in data.get("comments", []):
    if c["author"]["login"] == "DrahtBot": continue
    md.append(f"### `@{c['author']['login']}`\n{c['body'].strip()}\n\n---\n")
md.append("## 5. Formal Reviews & Final `ACK`s\n")
for r in data.get("reviews", []):
    if not (r.get("body") or "").strip(): continue
    md.append(f"### `@{r['author']['login']}` (`{r['state']}`)\n{r['body'].strip()}\n\n---\n")
with open(f"{out_dir}/PR-{pr}-JOURNEY.md", "w") as f:
    f.write("\n".join(md))
print(f"Saved {out_dir}/PR-{pr}-JOURNEY.md")
PYEOF
      fi
      cat "$JOURNEY_FILE"
    fi
    ;;
  commit-offline)
    commit_offline "${2:-}"
    ;;
  sync)
    sync_online
    ;;
  verify-all)
    lab_selftest
    ;;
  *)
    echo "Usage: ./lab.sh <command> [args]"
    echo ""
    echo "🍏 Apple M1 Laptop Health & RAM Protection (Run Anytime):"
    echo "  ./lab.sh health                  Full M1 CPU, 8 GB RAM, SSD Swap & process health report with explanation"
    echo "  ./lab.sh rest                    Stop bitcoind & Polar containers when done studying to free RAM"
    echo ""
    echo "📚 Offline Knowledge Bank & Blind-Recall Drills (Zero Internet / Zero AI / Zero Google):"
    echo "  ./lab.sh book                    Show the Stage-to-Book Learner Journey Map & all offline books"
    echo "  ./lab.sh book [1..5]             Read From-Memory Workbooks (1:Go, 2:C++/Py, 3:Crypto, 4:Tx/Script, 5:LN)"
    echo "  ./lab.sh book [mb|pb|cli|ln]     Read Mastering Bitcoin, Programming Bitcoin, Learning CLI, or Mastering LN"
    echo "  ./lab.sh recall [blank|check|solve] Practice coding 8 core Bitcoin building blocks 100% from memory"
    echo ""
    echo "🩺 Setup:"
    echo "  ./lab.sh doctor                  Check installed tools and versions (git, go, python, bitcoind)"
    echo ""
    echo "🌱 Start Small (5-to-15 Minute Micro-Wins When Things Feel Hard):"
    echo "  ./lab.sh step [1..5]             Show one micro-step of the Stage 00 worksheet (you type every command)"
    echo ""
    echo "🔨 Bitcoin From Source Repetition Drills (Download -> Compile -> Test -> PR Feedback):"
    echo "  ./lab.sh drill [1..8]            Repeat the from-source drills: git clone, CMake build, tests, review signals"
    echo ""
    echo "🐻‍❄️ Lightning Readiness, Polar & Docker Simulation:"
    echo "  ./lab.sh polar                   Inspect ~/.polar networks & print lncli / Docker terminal drills"
    echo "  ./lab.sh stage 12                Show the Lightning readiness worksheets and checkers"
    echo ""
    echo "Bug Dojo (Break, Fix & Verify Real Bitcoin Core Bugs):"
    echo "  ./lab.sh dojo break              Load the broken pre-fix code into dojo_missions.go"
    echo "  ./lab.sh dojo check [1..6]       Run the Dojo tests (Mission 6: you write the test)"
    echo "  ./lab.sh dojo solve              Restore verified upstream solutions into dojo_missions.go"
    echo ""
    echo "Satoshi Foundations & Offline Study:"
    echo "  ./lab.sh genesis                 Inspect Genesis Block & 61-Line Consensus Shield (CVE-2010-5139 / CVE-2018-17144)"
    echo "  ./lab.sh status                  Show regtest node, offline libraries & M1 health snapshot"
    echo "  ./lab.sh bip <number>            Read any BIP offline (e.g., './lab.sh bip 340')"
    echo "  ./lab.sh bolt <number>           Read any Lightning BOLT offline (e.g., './lab.sh bolt 3')"
    echo ""
    echo "📒 Curriculum stages 00..19 (CURRICULUM.md) — no shortcuts:"
    echo "  ./lab.sh stage <00..19>          Show a stage's README, worksheets and checkers"
    echo "  ./lab.sh check <00..19>          Run every checker for that stage (PASS/FAIL, never the answer)"
    echo "  ./lab.sh blank <07|08|10|11|12>  Put a fresh Go skeleton in place (your file is backed up first)"
    echo "  ./lab.sh solve <07|08|10|11|12>  Copy the reference solution in (spoiler; backup first)"
    echo "  ./lab.sh selftest                Check the lab itself (syntax, skeletons fail, solutions pass)"
    echo ""
    echo "Maintainer-Grade Offline PR Auditing, Review Journeys & Sync:"
    echo "  ./lab.sh journeys [PR_NUMBER]    Study 8 real merged PR review journeys (or download any PR's journey)"
    echo "  ./lab.sh pr-list                 List upstream bitcoin/bitcoin PRs stored locally for offline review"
    echo "  ./lab.sh pr-audit <PR_NUMBER>    Collect a PR's metadata and diff into a study file with a BLANK review checklist"
    echo "  ./lab.sh commit-offline \"<msg>\"  Commit your work locally while offline"
    echo "  ./lab.sh sync                    Push all queued offline commits when back online"
    ;;
esac
