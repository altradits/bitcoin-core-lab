# ⚡ Mastering What Satoshi Intended: First-Principles Workbook & Btrust Fellowship Guide

> *"A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution."*  
> — **Satoshi Nakamoto**, *Bitcoin: A Peer-to-Peer Electronic Cash System* (October 31, 2008)

This workbook is designed so you can **practice, repeat, and master every concept from scratch** in your terminal using `/Users/mac/bitcoin` (`bitcoind` v29.0) and `/Users/mac/bitcoin-core-lab`. No fiat APIs, no custodial intermediaries—100% pure Bitcoin protocol engineering.

---

## 🧭 Part 1: Satoshi's 5 Core Invariants in Bitcoin Core C++

Whenever you read or review code in `/Users/mac/bitcoin/src/`, map it back to these five invariants from Satoshi's design:

| # | Consensus Invariant | Whitepaper Section | Exact C++ Source Location in `/Users/mac/bitcoin` |
| :---: | :--- | :--- | :--- |
| **1** | **Hard-Capped Supply (`21,000,000 BTC`) & Halving** | Section 6 (*Incentive*) | [`src/consensus/amount.h`](file:///Users/mac/bitcoin/src/consensus/amount.h) (`MAX_MONEY`) & `GetBlockSubsidy` in [`src/validation.cpp`](file:///Users/mac/bitcoin/src/validation.cpp) |
| **2** | **Coinbase Maturity (`COINBASE_MATURITY = 100`)** | Section 6 & 11 | [`src/consensus/consensus.h`](file:///Users/mac/bitcoin/src/consensus/consensus.h) & `Consensus::CheckTxInputs` in [`src/consensus/tx_verify.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_verify.cpp) |
| **3** | **UTXO Conservation & Implicit Miner Fees** | Section 2 (*Transactions*) & Section 6 | `Consensus::CheckTxInputs` in [`src/consensus/tx_verify.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_verify.cpp) (`txfee_aux = nValueIn - value_out`) |
| **4** | **Stack-Based Programmable Verification (Script)** | Section 2 (*Digital Signatures*) | `EvalScript` & `VerifyScript` in [`src/script/interpreter.cpp`](file:///Users/mac/bitcoin/src/script/interpreter.cpp) |
| **5** | **Topological Ordering & Mempool Incentives** | Section 3 (*Timestamp Server*) & Section 5 (*Network*) | `AcceptToMemoryPool` in [`src/validation.cpp`](file:///Users/mac/bitcoin/src/validation.cpp), [`src/policy/rbf.cpp`](file:///Users/mac/bitcoin/src/policy/rbf.cpp), [`src/policy/truc_policy.cpp`](file:///Users/mac/bitcoin/src/policy/truc_policy.cpp) |

---

## 🛠️ Part 2: Step-by-Step Terminal Hands-On Drills (Hours 01–07)

Before starting any drill, open your terminal in `/Users/mac/bitcoin` and add your compiled binaries to `PATH`:

```bash
export PATH="/Users/mac/bitcoin/build/bin:$PATH"
bitcoind -regtest -daemon 2>/dev/null || true
```

---

### Drill 01: Coinbase Maturity & Halving Epochs (`01-node-foundations`)

**Concept to Master:** Why can't a miner spend newly minted satoshis for 100 blocks? Because if a chain reorganization orphans that block, the coinbase UTXO vanishes completely (unlike normal transactions which can be re-mined in the winning chain).

**Run it yourself:**
```bash
# 1. Inspect the C++ consensus constant
grep -n "COINBASE_MATURITY" /Users/mac/bitcoin/src/consensus/consensus.h

# 2. Run the automated verification script
/Users/mac/bitcoin-core-lab/01-node-foundations/verify_coinbase_maturity.sh
```

**Self-Check Question:** What validation error string does `Consensus::CheckTxInputs` return in `src/consensus/tx_verify.cpp` if you attempt to spend a coinbase output at depth 99?  
*(Answer: `"bad-txns-premature-spend-of-coinbase"`)*

---

### Drill 02: Raw Transaction Hex, Implicit Fees & SegWit Weight (`02-raw-tx-and-mempool`)

**Concept to Master:** Why is there no `"fee"` field in a serialized Bitcoin transaction? Because every input consumes an existing UTXO in full, and $\text{Fee} = \sum \text{Inputs} - \sum \text{Outputs}$. Also understand why SegWit separates witness signatures (`txinwitness`) from the base transaction to eliminate third-party `txid` malleability and discounts witness bytes by `4x` (`WITNESS_SCALE_FACTOR = 4`).

**Run it yourself:**
```bash
# 1. Inspect the C++ fee conservation check
grep -n -C 5 "bad-txns-in-belowout" /Users/mac/bitcoin/src/consensus/tx_verify.cpp

# 2. Execute the raw transaction & mempool inspection script
/Users/mac/bitcoin-core-lab/02-raw-tx-and-mempool/raw_tx_mempool.sh
```

**Self-Check Formula:** Given `base_size = 113 bytes` and `total_size = 222 bytes`, calculate `weight` and `vsize` by hand:
$$\text{weight} = (113 \times 3) + 222 = 561\text{ WU}, \quad \text{vsize} = \lceil 561 / 4 \rceil = 141\text{ vB}$$

---

### Drill 03: Mempool Fee Bumping — BIP125 RBF & CPFP (`03-rbf-and-cpfp`)

**Concept to Master:**
1. **RBF (Sender-side):** Requires `nSequence <= 0xfffffffd` (`4294967293`). To prevent P2P bandwidth DoS where an attacker replaces a transaction thousands of times for `1 sat` more each time, `PaysForRBF` Rule #4 (`src/policy/rbf.cpp`) requires `replacement_fees - original_fees >= incrementalRelayFee * replacement_vsize`.
2. **CPFP (Receiver-side):** A recipient spends an unconfirmed output with a high fee so `BlockAssembler` (`src/node/miner.cpp`) evaluates the combined `[Parent + Child]` ancestor package feerate.

**Run it yourself:**
```bash
# 1. Read PaysForRBF in C++
sed -n '160,185p' /Users/mac/bitcoin/src/policy/rbf.cpp

# 2. Run the RBF replacement + CPFP child script
/Users/mac/bitcoin-core-lab/03-rbf-and-cpfp/rbf_and_cpfp.sh
```

---

### Drill 04: Writing & Running Bitcoin Core Functional Tests (`04-functional-test-framework`)

**Concept to Master:** Every PR merged into `bitcoin/bitcoin` must include or pass Python functional tests in `test/functional/` using `BitcoinTestFramework` and `MiniWallet`.

**Run it yourself:**
```bash
# 1. Run upstream RBF and mempool package tests
python3 /Users/mac/bitcoin/build/test/functional/test_runner.py feature_rbf.py mempool_packages.py

# 2. Run your custom 2-node P2P functional test
python3 /Users/mac/bitcoin-core-lab/04-functional-test-framework/kisumu_pos_rbf_test.py \
  --configfile=/Users/mac/bitcoin/build/test/config.ini
```

---

### Drill 05: BIP431 TRUC (`v3`) Transactions & `submitpackage` (`05-truc-package-relay-review`)

**Concept to Master:** Why did Bitcoin Core v28/v29 introduce `version=3` (TRUC) transactions? So time-sensitive smart contracts (like Lightning commitment transactions) can be signed with **zero fee (`0 sat/vB`)** in advance and fee-bumped at broadcast time via an atomic **1-Parent-1-Child (`1P1C`) package (`submitpackage`)**, while bounding the child to `1,000 vB` (`TRUC_CHILD_MAX_VSIZE`) to eliminate mempool pinning.

**Run it yourself:**
```bash
# 1. Run the upstream TRUC test suite
python3 /Users/mac/bitcoin/build/test/functional/test_runner.py mempool_truc.py

# 2. Run the live 0-fee v3 Parent + v3 Child submitpackage script
/Users/mac/bitcoin-core-lab/05-truc-package-relay-review/truc_1p1c_package.sh
```

---

### Drill 06: Programmable Money — P2WSH HTLC Script & Timelocks (`06-lightning-htlc-state-machine`)

**Concept to Master:** Satoshi built a stack-based Forth-like language (`CScript`) directly into every Bitcoin transaction so money could be programmed without trusted third parties. A Hash Time-Locked Contract (HTLC) combines a cryptographic hashlock (`OP_SHA256 <H> OP_EQUALVERIFY`) in `OP_IF` with a relative block timelock (`<10> OP_CHECKSEQUENCEVERIFY OP_DROP`) in `OP_ELSE`.

**Run it yourself:**
```bash
python3 /Users/mac/bitcoin-core-lab/06-lightning-htlc-state-machine/verify_htlc.py
```

---

### Drill 07: Sovereign Custody — BIP380 Descriptors & BIP174 Airgapped PSBT (`07-psbt-descriptors-and-miniscript`)

**Concept to Master:** Never store private keys on an internet-connected server. Use **Output Script Descriptors (`wpkh(...)`)** on a watch-only node (`disable_private_keys: true`) to monitor UTXOs and construct unsigned **BIP174 PSBTs**, sign them on an airgapped cold signer (`walletprocesspsbt`), and finalize (`finalizepsbt`).

**Run it yourself:**
```bash
go -C /Users/mac/bitcoin-core-lab/07-psbt-descriptors-and-miniscript test -v ./...
go -C /Users/mac/bitcoin-core-lab/07-psbt-descriptors-and-miniscript run .
```

---

## 🏆 Part 3: Btrust Builders Fellowship — Upstream PR Review Playbook

Grant committees at **Btrust Builders**, **Brink**, and **OpenSats** evaluate candidates primarily on **consistent, high-signal upstream PR reviews on `bitcoin/bitcoin`**. Use this 5-step workflow every week:

### Step 1: Fetch and Checkout an Open PR from `bitcoin/bitcoin`
```bash
# Inside /Users/mac/bitcoin, fetch PR #<PR_NUMBER> into a local branch
git fetch origin pull/<PR_NUMBER>/head:pr-<PR_NUMBER>
git checkout pr-<PR_NUMBER>
```

### Step 2: Inspect the Commits & C++ Diff
```bash
git log master..HEAD --oneline
git diff master...HEAD
```

### Step 3: Recompile & Run Unit + Functional Tests
```bash
cmake --build build -j4
ctest --test-dir build --output-on-failure
python3 build/test/functional/test_runner.py <touched_functional_test.py>
```

### Step 4: Try to Break It (Mutation Testing)
Comment out an assertion or boundary check in the PR's C++ code, recompile (`cmake --build build -j4`), and verify that the PR's functional test **fails**. Then restore the line.

### Step 5: Publish a Structured Review on GitHub
Format your GitHub PR comment using the standard Bitcoin Core review convention:
```markdown
Tested ACK <full_40_char_commit_hash>

### Review Summary
- **Approach:** Verified that ...
- **Code Inspection:** Checked boundaries in `src/...`
- **Testing:**
  - Built on macOS ARM64 (`cmake -B build && cmake --build build`)
  - Ran unit tests (`ctest --test-dir build`) and `test/functional/<test_name>.py`
  - Manually verified edge case where ...
```
