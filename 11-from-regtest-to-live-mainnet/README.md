# Stage 11: Apple M1 Sovereign Node, Wallet of Satoshi Migration, Fee/Speed Mastery & PR Fix Proposals

> *"Your Apple M1 MacBook Air is your sovereign Bitcoin command center. On this single machine, you compile Bitcoin Core from C++ source, run your own pruned Mainnet node inside 16.5 GB of disk space, graduate from custodial apps like Wallet of Satoshi to your own verifiable `bc1q...` / `bc1p...` cold/watch-only vault, minimize miner fees with SegWit/Taproot/RBF/CPFP, and review upstream `bitcoin/bitcoin` PRs using Satoshi's original consensus principles."*

---

## Part 1: Hardware Audit of Your MacBook Air (`MacBookAir10,1`)

We inspected the exact hardware specifications of this Mac so your Bitcoin node never slows down your laptop or fills up your SSD:

| Component | Detected Spec on Your Mac | What It Means for Bitcoin Core (`bitcoind`) | Optimal `bitcoin.conf` Setting |
| :--- | :--- | :--- | :--- |
| **Chip / CPU** | **Apple M1 (`arm64`, 8 Cores: 4 Perf + 4 Eff)** | Hardware ARMv8 SHA-256 extensions validate blocks & `secp256k1` signatures at workstation speed. | `par=4` (uses the 4 Performance cores) |
| **Memory (RAM)** | **8 GB Unified Memory** | Must balance UTXO cache (`dbcache`) so macOS and your compiler never swap to disk. | `dbcache=1024` (1 GB RAM for UTXO set) |
| **SSD Storage** | **228 GiB Total / ~68 GiB Available Free** | An unpruned 700 GB node **will not fit**. You **must** run in **Pruned Mode** (`prune=5500`). | `prune=5500` (~5.5 GB blocks + ~11 GB UTXO set = **~16.5 GB total**, leaving **>50 GB free!**) |
| **Network** | **Local + Wi-Fi** | Cap inbound/outbound peers so background P2P traffic stays light. | `maxconnections=40` |

### Your Tailored `bitcoin.conf` for This M1 MacBook Air
When you are ready to run Signet and Pruned Mainnet alongside Regtest, place these settings in `/Users/mac/Library/Application Support/Bitcoin/bitcoin.conf`:

```ini
daemon=1
server=1
prune=5500
dbcache=1024
par=4
maxconnections=40
walletrbf=1
rpcallowip=127.0.0.1
```

---

## Part 2: Moving Sats From "Wallet of Satoshi" to Your Sovereign Mac Wallet

Right now, you hold sats in **Wallet of Satoshi (WoS)**. Here is the critical difference:
- **Wallet of Satoshi is Custodial:** WoS holds the private keys. Your balance in the app is a database promise until you withdraw those sats on-chain to an address whose keys **you** control.
- **Your Bitcoin Core Wallet on This Mac is Sovereign:** When you generate a `bc1q...` (Native SegWit) or `bc1p...` (Taproot) address on your own `bitcoind` node, **you** hold the cryptographic keys and **your own compiled C++ code** verifies every block.

### Step-by-Step: How to Create Your Secure Mac Wallet & Withdraw From Wallet of Satoshi

Follow this exact sequence when your Mainnet node is synced (`verificationprogress` = `0.9999+` in `bitcoin-cli getblockchaininfo`):

```bash
# STEP 1: Create your encrypted Mainnet Descriptor Wallet on your Mac
# (Replace YOUR_STRONG_PASSPHRASE with a passphrase written on physical paper!)
bitcoin-cli createwallet "stanley_mainnet_vault" false false "YOUR_STRONG_PASSPHRASE"

# STEP 2: Back up your wallet file AND your public descriptors to a USB drive / offline paper
bitcoin-cli -rpcwallet=stanley_mainnet_vault backupwallet "/Users/mac/stanley_mainnet_vault_backup.dat"
bitcoin-cli -rpcwallet=stanley_mainnet_vault listdescriptors false > "/Users/mac/stanley_public_descriptors.json"

# STEP 3: Generate a fresh Native SegWit (bc1q...) or Taproot (bc1p...) receiving address
MY_MAINNET_ADDR=$(bitcoin-cli -rpcwallet=stanley_mainnet_vault getnewaddress "from_wallet_of_satoshi" "bech32")
echo "Send sats to this Mainnet address: $MY_MAINNET_ADDR"

# STEP 4: ALWAYS verify your node recognizes & can solve this address BEFORE sending real money!
bitcoin-cli -rpcwallet=stanley_mainnet_vault getaddressinfo "$MY_MAINNET_ADDR"
# Confirm output shows: "ismine": true, "solvable": true
```

### STEP 5: Sending Sats From Wallet of Satoshi (The Golden Fee Rules!)
1. **Do NOT withdraw tiny amounts (`5,000 sats`) on-chain!**
   - Wallet of Satoshi charges an on-chain withdrawal fee, **and** every time you receive an on-chain payment, it creates one separate digital coin (`UTXO`) in your wallet.
   - If you withdraw `10,000 sats` ten separate times, you end up with **10 tiny UTXOs**. Later, when you want to spend `100,000 sats`, your transaction must include all 10 inputs (`10 x 68 vBytes = 680 vBytes`), multiplying your future miner fees by **7x**!
   - **Best Practice:** Keep accumulating small daily Lightning payments inside Wallet of Satoshi until you reach a healthy chunk (e.g., **`100,000` to `500,000+ sats`**), then withdraw in **ONE single on-chain transaction** to `$MY_MAINNET_ADDR` during a quiet mempool period (usually weekends when feerates drop to **`1–3 sat/vB`**).
2. **Test With One Small Withdrawal First, Then Send the Rest:**
   - The very first time you use your Mainnet wallet, practice the full lifecycle (receive, unlock wallet with `walletpassphrase`, sign, verify backup) before moving large savings.

---

## Part 3: How to Minimize Transaction Fees & Maximize Speed When Spending

Because Bitcoin miners charge fees per **virtual byte (`sat/vB`)**—*not* per dollar or per BTC sent—you control your fee and your confirmation speed using the exact protocol mechanics you built in **Stages 02, 03, and 05**:

### Technique 1: Use `bc1q...` (Native SegWit) & `bc1p...` (Taproot)
As proven in [`EstimateTxVBytes`](file:///Users/mac/bitcoin-core-lab/11-from-regtest-to-live-mainnet/sovereign_wallet_builder.go#L97-L120):
- **Legacy (`1...`):** `148 vB` per input, `34 vB` per output (`226 vB` for a 1-in, 2-out tx).
- **Native SegWit (`bc1q...`):** `68 vB` per input, `31 vB` per output (`141 vB` for a 1-in, 2-out tx — **38% cheaper fees!**).
- **Taproot (`bc1p...`):** `57.5 vB` per input, `43 vB` per output (cheapest input size when consolidating multiple UTXOs!).

### Technique 2: Start With a Low Fee + Accelerate Instantly With `bumpfee` (BIP125 RBF)
Never overpay out of fear! Because we set `walletrbf=1` in your `bitcoin.conf`:
1. **When you are not in a rush (Minimize Fees):**
   Send with a low target (e.g., 6 to 24 blocks) or explicit low feerate (`fee_rate=2` sat/vB):
   ```bash
   bitcoin-cli -rpcwallet=stanley_mainnet_vault sendtoaddress "bc1q..." 0.005 "" "" false true null "unset" null 2.0
   ```
2. **If you suddenly need Instant Next-Block Speed (Maximize Speed):**
   Instead of waiting hours, run `bumpfee` (Stage 03) to replace the unconfirmed transaction in the mempool with a higher fee in 1 second:
   ```bash
   bitcoin-cli -rpcwallet=stanley_mainnet_vault bumpfee "<stuck_txid>" '{"fee_rate": 15.0}'
   ```

### Technique 3: Unstick Incoming Payments With `CPFP` (Child-Pays-For-Parent)
What if Wallet of Satoshi (or someone paying you) broadcasts your incoming payment with a `1 sat/vB` fee and the mempool spikes to `20 sat/vB`?
- You don't have to wait! Even while the incoming UTXO has `0 confirmations`, your Bitcoin Core wallet sees it in the mempool (`listunspent 0 0`).
- Spend that unconfirmed UTXO back to a fresh address in your own wallet with a higher fee. Miners evaluate the **Parent + Child Package Feerate together** (Stage 03 & Stage 05) and mine both transactions in the very next block!

### Technique 4: Batch Multiple Payments Into One (`sendmany`)
If you need to pay 4 people, **never** send 4 separate transactions (`4 x 141 vB = 564 vB`). Use `sendmany` so all 4 outputs share a single input (`10.5 + 68 + 5*31 = 233.5 vB`), cutting your miner fee by **nearly 60%**:
```bash
bitcoin-cli -rpcwallet=stanley_mainnet_vault sendmany "" '{"bc1q_person1...":0.001, "bc1q_person2...":0.002}'
```

---

## Part 4: How to Propose Exact Fixes in Open-Source PR Reviews (Based on Satoshi's Principles)

When you review another developer's Pull Request on `bitcoin/bitcoin`, you don't just say *"Looks good"* or *"This is broken."* Respected open-source reviewers **diagnose the exact flaw using Bitcoin Core's historical principles and propose the exact code fix**.

Here is your **Satoshi Guardian PR Fix Proposal Matrix**—use this whenever you inspect a PR diff with `./lab.sh pr-audit <PR_NUM>`:

| What You Spot in the Author's Diff | Which Satoshi Principle / Historical Bug It Violates | How to Propose the Exact Fix to the Author on GitHub |
| :--- | :--- | :--- |
| **1. Adding two `CAmount` (`int64_t`) values without checking `MoneyRange` before & after** | **Supply Invariant (`CVE-2010-5139` — 184B BTC Overflow Bug):** Adding signed/unsigned integers can wrap around or exceed `MAX_MONEY` (`21,000,000 BTC`). | *"In `<file>:<line>`, accumulating `nValueOut += out.nValue` without checking `MoneyRange(out.nValue)` and `MoneyRange(nValueOut)` risks integer overflow (similar to `CVE-2010-5139` in `src/consensus/tx_check.cpp`). Suggest adding `if (!MoneyRange(val)) return ...` before adding."* |
| **2. Iterating over transaction inputs or UTXOs without checking for duplicates** | **Uniqueness Invariant (`CVE-2018-17144` — Duplicate Input Inflation Bug):** Spending the same `COutPoint` twice inflates supply. | *"Could `vout` / `vin` contain duplicate outpoints here if called before `CheckTransaction`? To preserve the `CVE-2018-17144` uniqueness invariant, we should either `Assume` deduplicated inputs or track seen `COutPoint`s in a `std::set`."* |
| **3. Using raw byte size (`GetTotalSize()`) instead of virtual size (`GetVirtualTransactionSize()`) for fee calculations** | **BIP141 SegWit Weight & `PR #32800` SigOp Vsize Rule:** Fees must divide by `max(weight/4, sigop_weight/4)` so high-sigop or witness-heavy txs cannot underpay miners. | *"In `<file>:<line>`, dividing `nFee` by raw serialized size undercharges high-sigop transactions (see `PR #32800`). Please use `GetVirtualTransactionSize(tx, nSigOpCost, ::nBytesPerSigOp)` so sigop-heavy transactions pay for the block weight they consume."* |
| **4. Allowing a mempool replacement without checking BOTH feerate AND absolute fee increase** | **BIP125 Rule #3 & #4 (`src/policy/rbf.cpp` — Free Relay Bandwidth DoS):** A higher feerate alone on a tiny tx allows free bandwidth relay attacks. | *"Checking only `new_feerate > old_feerate` violates BIP125 Rule #4 (`PaysForRBF` in `src/policy/rbf.cpp`). A smaller replacement tx could have a higher sat/vB while paying fewer total satoshis, enabling free P2P relay exhaustion. Suggest calling `PaysForRBF(...)`."* |
| **5. Accepting a cryptographic key, seed, or PSBT signature without validating bounds/pubkey match** | **BIP32 Seed Bounds (`PR #35320`) & PSBT Signer Check (`PR #33014`):** Silent truncation or unverified external signatures corrupt wallets. | *"Per `PR #35320` / `PR #33014`, we should not trust external bytes without explicit bounds/signature verification. Suggest returning `false` if `seed.size() < 16 || seed.size() > 64` (or verifying the signature against the target pubkey before inserting into `partial_sigs`)."* |
| **6. The PR fixes a bug in `src/`, but only adds a 'happy path' test** | **Maintainer Mutation-Test Standard:** Every bug-fix PR must include a negative test that fails on `master` and passes on the PR branch. | *"Approach ACK! To prevent future regressions, could you add a negative test case in `<test_file>` that passes the invalid `<input>` and asserts `BOOST_CHECK_EQUAL(..., expected_error)`? I tested locally that reverting your check causes that test to fail."* |

### Copy-Paste Template When Proposing a Fix on someone's GitHub PR:

When you find an issue while running `./lab.sh pr-audit <PR_NUM>` or `./lab.sh drill 7`, post this constructive comment on GitHub:

````markdown
Concept ACK — solving `<problem>` is a great improvement.

While reviewing `<file_path>` and testing locally on macOS M1 (`arm64`), I noticed an edge case at line `<line_number>` regarding `<invariant_name>`:

### Issue & Historical Context
Currently, `<current_code>` does not guard against `<edge_case>` (similar to the invariant enforced in `<src/consensus/tx_check.cpp or PR #XXXXX>`). If a caller/peer passes `<malicious_input>`, `<consequence>` can occur.

### Proposed Fix
We can guard this upfront with:
```suggestion
if (<guard_condition>) {
    return <error_return>;
}
```

### Verification
I applied this guard locally, recompiled `test_bitcoin` (`cmake --build build --target test_bitcoin`), and verified that adding a negative test case in `src/test/<test_file>.cpp` catches the unguarded case and passes with the fix. Happy to re-test and post a `Tested ACK` once updated!
````
