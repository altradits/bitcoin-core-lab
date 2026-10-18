# 🔨 Bitcoin Core From Source: The Complete Repetition & Open-Source Mastery Manual

> *"Do not treat `./lab.sh` as a magic black box. Every command inside `./lab.sh` is a standard Bitcoin Core developer command. By repeating the 8 drills in this manual (`./lab.sh drill 1` through `./lab.sh drill 8`), you will be able to walk up to any blank computer, download and compile Bitcoin Core from C++ source, create every wallet and regtest resource from scratch, find and fix C++ bugs, and write respected PR reviews for other developers on GitHub."*

---

## 🎯 How to Master By Repetition (`./lab.sh drill <1..8>`)

Run each drill interactively from `/Users/mac/bitcoin-core-lab`:
```bash
./lab.sh drill 1   # Drill 1: Clone, Git Remotes, Directory Map & Build Dependencies
./lab.sh drill 2   # Drill 2: CMake Configure & C++ Compilation (bitcoind, bitcoin-cli, test_bitcoin)
./lab.sh drill 3   # Drill 3: bitcoin.conf, Starting/Stopping bitcoind -regtest & RPC Auth
./lab.sh drill 4   # Drill 4: Creating Wallets, Descriptors & Mining the First 101 Blocks by Hand
./lab.sh drill 5   # Drill 5: Running C++ Unit Tests (test_bitcoin) & Python Functional Tests
./lab.sh drill 6   # Drill 6: Finding Code with git grep, Editing C++, Rebuilding & Verifying
./lab.sh drill 7   # Drill 7: Checking Out & Testing Another Developer's PR Branch
./lab.sh drill 8   # Drill 8: Writing Open-Source Feedback (Concept ACK, Tested ACK & Inline Nits)
```

---

## Drill 1: From Download (`git clone`) to Toolchain Verification

When you set up a fresh machine to work on Bitcoin Core, you need the source repository and the C++20 build toolchain.

### 1.1 The Exact Commands to Download & Set Up Git Remotes
```bash
# 1. Clone the official upstream Bitcoin Core repository
git clone https://github.com/bitcoin/bitcoin.git /Users/mac/bitcoin
cd /Users/mac/bitcoin

# 2. Verify your git remotes (origin points to bitcoin/bitcoin, or your fork)
git remote -v

# 3. Inspect the latest commits on master
git log -n 5 --oneline
```

### 1.2 Installing & Verifying the Build Dependencies (macOS / Linux)
Bitcoin Core v29+ requires a **C++20 compiler** (`clang++` or `g++`), **CMake** (`>= 3.22`), **pkg-config**, **libevent**, **boost**, and **sqlite** (for descriptor wallets).
```bash
# On macOS (Homebrew):
brew install cmake pkgconf automake libtool boost libevent sqlite python3

# Verify every required tool is installed and on your PATH:
cmake --version
clang++ --version
pkg-config --version
python3 --version
```

### 1.3 Navigating the `/Users/mac/bitcoin` Directory Map
Memorize these 6 folders—they are where 99% of your open-source work happens:
- [`src/consensus/`](file:///Users/mac/bitcoin/src/consensus): Pure consensus rules (`tx_check.cpp`, `tx_verify.cpp`, `merkle.cpp`, `amount.h`).
- [`src/script/`](file:///Users/mac/bitcoin/src/script): The Bitcoin Script Virtual Machine (`interpreter.cpp`), Descriptors (`descriptor.cpp`), and Miniscript (`miniscript.cpp`).
- [`src/policy/`](file:///Users/mac/bitcoin/src/policy): Mempool admission rules (`rbf.cpp`, `truc_policy.cpp`, `packages.cpp`, `policy.cpp`).
- [`src/validation.cpp`](file:///Users/mac/bitcoin/src/validation.cpp) & [`src/txmempool.cpp`](file:///Users/mac/bitcoin/src/txmempool.cpp): Block/transaction validation (`AcceptToMemoryPool`, `ConnectBlock`).
- [`src/wallet/`](file:///Users/mac/bitcoin/src/wallet): SQLite descriptor wallet, coin selection (`coinselection.cpp`), and fee estimation.
- [`src/test/`](file:///Users/mac/bitcoin/src/test) & [`test/functional/`](file:///Users/mac/bitcoin/test/functional): C++ Boost unit tests and Python P2P functional tests.

---

## Drill 2: Configuring CMake & Compiling Bitcoin Core From Source

Starting in Bitcoin Core v29.0, the project switched from legacy Autotools (`./autogen.sh && ./configure`) to **CMake**.

### 2.1 Step-by-Step Build Commands (Memorize These!)
```bash
cd /Users/mac/bitcoin

# Step 1: Configure the build directory ('build/') with C++ unit tests enabled
cmake -B build -DBUILD_TESTING=ON

# Step 2: Compile using all CPU cores (e.g., -j8)
cmake --build build -j$(sysctl -n hw.ncpu)

# Pro-Tip: When you only changed 1 C++ file and want to recompile JUST bitcoind or test_bitcoin fast:
cmake --build build --target bitcoind bitcoin-cli test_bitcoin -j4
```

### 2.2 The Compiled Binaries Inside `/Users/mac/bitcoin/build/bin/`
After compiling, inspect `/Users/mac/bitcoin/build/bin/`:
1. **`bitcoind`**: The full Bitcoin node daemon (validates blocks, runs P2P, serves RPC).
2. **`bitcoin-cli`**: The command-line RPC client that sends JSON commands to `bitcoind`.
3. **`test_bitcoin`**: The compiled C++ Boost unit test runner.
4. **`bitcoin-tx`**: Standalone tool for creating/modifying raw hex transactions without a node.
5. **`bitcoin-wallet`**: Offline tool for inspecting wallet databases.

To use these binaries from any terminal without typing `/Users/mac/bitcoin/build/bin/` every time, add them to your `PATH` (this is line 7 of `lab.sh`!):
```bash
export PATH="/Users/mac/bitcoin/build/bin:$PATH"
which bitcoind bitcoin-cli
```

---

## Drill 3: Configuring `bitcoin.conf` & Operating `bitcoind -regtest`

Why does Bitcoin Core have **3 testing networks**?
- **`mainnet`**: Real money, real PoW difficulty. Never test experimental code here.
- **`signet` / `testnet4`**: Public test networks shared with other developers.
- **`regtest` (Regression Test Mode)**: Your private local blockchain on your laptop where you can mine blocks in **1 millisecond** (`generatetoaddress`) with zero difficulty.

### 3.1 How `bitcoin.conf` & RPC Authentication Work
On macOS, `bitcoind` reads `/Users/mac/Library/Application Support/Bitcoin/bitcoin.conf` (on Linux: `~/.bitcoin/bitcoin.conf`).
When `bitcoind -regtest -daemon` starts:
- It creates a data folder at `/Users/mac/Library/Application Support/Bitcoin/regtest/`.
- If `rpcuser` and `rpcpassword` are set in `bitcoin.conf`, `bitcoin-cli` authenticates using those credentials. Otherwise, `bitcoind` generates a temporary session file called `.cookie` inside `regtest/.cookie`.

### 3.2 The 5 Essential Daemon Lifecycle Commands
Practice typing these 5 commands until they are muscle memory:
```bash
# 1. Start the regtest daemon in the background
bitcoind -regtest -daemon

# 2. Verify the node is alive and check the chain state
bitcoin-cli -regtest getblockchaininfo

# 3. Check P2P network status and protocol version
bitcoin-cli -regtest getnetworkinfo

# 4. View the live node debug log (crucial when debugging errors!)
tail -n 25 "/Users/mac/Library/Application Support/Bitcoin/regtest/debug.log"

# 5. Gracefully stop the node (if you ever want to restart cleanly)
# bitcoin-cli -regtest stop
```

---

## Drill 4: Creating All `lab.sh` Resources From Scratch (Wallets & Mining)

How did `./lab.sh` create the wallets (`kisumu_miner`, `kisumu_merchant`, `sovereign_cold_signer`, `sovereign_watch_only`) and fund them with Bitcoin? Here are the **exact commands** so you can recreate the entire environment from an empty node anytime:

```bash
# 1. Create standard descriptor wallets (holds private keys for signing)
bitcoin-cli -regtest createwallet "kisumu_miner"
bitcoin-cli -regtest createwallet "kisumu_merchant"
bitcoin-cli -regtest createwallet "sovereign_cold_signer"

# 2. Create a WATCH-ONLY wallet (disable_private_keys = true) for safe server invoicing
bitcoin-cli -regtest createwallet "sovereign_watch_only" true

# 3. If a wallet already exists on disk after a restart, load it with:
bitcoin-cli -regtest loadwallet "kisumu_miner"

# 4. List all currently loaded wallets in bitcoind
bitcoin-cli -regtest listwallets

# 5. Generate a fresh Bech32 (SegWit v0, bcrt1q...) address from the miner wallet
MINER_ADDR=$(bitcoin-cli -regtest -rpcwallet=kisumu_miner getnewaddress "miner_reward" "bech32")
echo "Miner Address: $MINER_ADDR"

# 6. Mine 101 blocks so Block #1's 50 BTC coinbase reward matures (COINBASE_MATURITY = 100)
bitcoin-cli -regtest generatetoaddress 101 "$MINER_ADDR"

# 7. Verify your spendable balance is now >= 50 BTC!
bitcoin-cli -regtest -rpcwallet=kisumu_miner getbalance
```

---

## Drill 5: Running the Two Bitcoin Core Test Suites (C++ & Python)

Whenever you build a feature, fix a bug, or review someone else's PR in `bitcoin/bitcoin`, you must prove it works using Bitcoin Core's **two automated test frameworks**:

### 5.1 Engine 1: Fast C++ Boost Unit Tests (`test_bitcoin`)
Unit tests live in `/Users/mac/bitcoin/src/test/*_tests.cpp`. Each file starts with `BOOST_FIXTURE_TEST_SUITE(suite_name, ...)`.
```bash
# Run a single C++ unit test file by its suite name (runs in < 1 second!):
/Users/mac/bitcoin/build/bin/test_bitcoin --run_test=merkle_tests
/Users/mac/bitcoin/build/bin/test_bitcoin --run_test=bip32_tests
/Users/mac/bitcoin/build/bin/test_bitcoin --run_test=txvalidation_tests
```

### 5.2 Engine 2: Python P2P Functional Tests (`test_runner.py`)
Functional tests live in `/Users/mac/bitcoin/test/functional/*.py`. They spin up multiple real `bitcoind -regtest` nodes and test P2P relay, mempool policy, RPCs, and wallet behavior.
```bash
# Run a specific upstream functional test:
python3 /Users/mac/bitcoin/build/test/functional/test_runner.py feature_rbf.py

# Or run your own custom functional test in Stage 04 directly:
python3 /Users/mac/bitcoin-core-lab/04-functional-test-framework/kisumu_pos_rbf_test.py \
  --configfile=/Users/mac/bitcoin/build/test/config.ini
```

---

## Drill 6: How to Find, Break, Recompile & Fix Errors in C++ Source

When a user reports a bug or test failure in Bitcoin Core, how do you find the exact file and line out of 300,000 lines of C++?

### 6.1 The 4-Step Bug-Hunting Workflow
```bash
cd /Users/mac/bitcoin

# Step 1: Search for the exact RPC error string or function name using 'git grep -n'
git grep -n "bad-txns-vin-empty" src/
git grep -n "CheckTransaction(" src/

# Step 2: View the exact function and git blame (who wrote it and why?)
git log -S "bad-txns-vin-empty" -n 3 --oneline

# Step 3: Edit the C++ file (or test file in src/test/), then recompile ONLY test_bitcoin:
cmake --build build --target test_bitcoin -j4

# Step 4: Run the specific unit test to verify your fix immediately:
./build/bin/test_bitcoin --run_test=txvalidation_tests
```

---

## Drill 7: How to Checkout, Build & Test Another Developer's Open-Source PR

To become a known contributor in `bitcoin/bitcoin`, **reviewing and testing other people's Pull Requests** is the #1 entry point (maintained at a 3:1 or 5:1 review-to-PR ratio).

### 7.1 Checking Out Any PR (Online or Offline)
```bash
cd /Users/mac/bitcoin

# A. WHEN ONLINE: Fetch any open PR directly from GitHub by its number (e.g., PR #35320):
# git fetch origin pull/35320/head:pr-35320
# git checkout pr-35320

# B. WHEN OFFLINE: Inspect any merged PR already inside your local git history:
./lab.sh pr-list

# Find the merge commit for PR #35320:
MERGE_COMMIT=$(git log master --merges --grep="bitcoin/bitcoin#35320:" -n 1 --format="%H")

# See the exact commits the author wrote in that PR:
git log "${MERGE_COMMIT}^1..${MERGE_COMMIT}^2" --oneline

# See the exact files and C++ diff changed by that PR:
git diff "${MERGE_COMMIT}^1...${MERGE_COMMIT}^2"
```

### 7.2 Mutation Testing a PR (The Secret of Great Reviewers)
Never just run the tests and say "it passed." Do a **Mutation Test**:
1. Look at the `if (...)` check the PR author added in `src/`.
2. Temporarily comment out that `if (...)` check, recompile (`cmake --build build --target test_bitcoin`), and run the test the author added.
3. **Does the test fail when the fix is commented out?** If yes, you have proved the test actually catches the bug! Restore the `if (...)` check and recompile.

---

## Drill 8: How to Give High-Signal Open-Source Feedback on GitHub

In `bitcoin/bitcoin`, maintainers do not merge code based on "thumbs up" emojis. They merge based on structured peer review comments using four specific terms:

### 8.1 The 4 Types of Bitcoin Core Review Feedback

| Review Signal | When to Use It | Example Comment |
| :--- | :--- | :--- |
| **`Concept ACK`** | You read the motivation/problem and agree Bitcoin Core *should* make this change, even before reviewing every line of code. | *"Concept ACK — rejecting BIP32 seeds outside 128–512 bits prevents silent entropy truncation."* |
| **`Approach ACK`** | You agree with the architectural design (which files/classes were modified and how). | *"Approach ACK — enforcing the length check inside `CExtKey::SetSeed` covers all callers."* |
| **`Tested ACK <commit>`** | The gold standard. You checked out `<commit>`, compiled, ran unit/functional tests, did a mutation check, and read every line of the diff. | *"Tested ACK `fa381be378...` — compiled on macOS arm64, verified `bip32_tests` fails without the bounds check."* |
| **`NACK` / Constructive Feedback** | You found a consensus bug, DoS vector, edge case, or style improvement (`nit`). Always be polite, specific, and cite exact line numbers. | *"Question on `src/policy/rbf.cpp:142`: could a peer pass `nFee < 0` here if `PACKAGE_FEERATE` bypasses `PaysForRBF`?"* |

### 8.2 Your Ready-to-Post GitHub PR Review Template
Whenever you finish testing a PR with `./lab.sh pr-audit <PR_NUM>` and `./lab.sh drill 7`, structure your public GitHub review comment like this:

```markdown
Tested ACK <full-40-char-commit-hash>

### What I Reviewed & Verified
1. **Code Inspection (`<file_path>`):** Verified that `<function_name>` enforces `<invariant>` and handles edge cases (`<edge_case_1>`, `<edge_case_2>`).
2. **Risk Classification:** Ring `<0/1/2/3>` — verified no unintended consensus or mempool DoS regression.
3. **Build & Automated Tests:**
   - Compiled cleanly with CMake on macOS (`clang++`).
   - Ran unit test suite: `./build/bin/test_bitcoin --run_test=<suite_name>` (passed).
   - Ran functional test: `python3 build/test/functional/test_runner.py <test_name>.py` (passed).
4. **Mutation Verification:** Reverted the check in `<file_path>:<line>` locally and confirmed the new test fails as expected.
```
