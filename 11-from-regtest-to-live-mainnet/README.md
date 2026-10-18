# Stage 11: From `-regtest` to Live Mainnet & Writing Bitcoin Code From Memory

> *"You start on `-regtest` so you can make mistakes for free. You graduate to `-signet` to talk to live global peers around the world. And when you understand the 4 Guiding Building Blocks of Bitcoin, you launch your own Sovereign Mainnet Node (`bc1q...` / `bc1p...`), build your own cold/watch-only wallet from scratch, and hold real satoshis under rules your own compiled C++ binary verifies."*

---

## Part 1: Will You Work on Live Bitcoin Beyond `-regtest`? YES!

The exact same `/Users/mac/bitcoin/build/bin/bitcoind` and `bitcoin-cli` binaries you compiled on your laptop power the **$1+ Trillion live Bitcoin network**.

The **only** difference between `-regtest` and live Bitcoin is a single flag. Here is your **4-Stage Network Graduation Ladder**:

| Stage | Network | Command Flag | Address Prefix | Disk Space | What You Do Here |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Level 1** | **Regtest** | `-regtest` | `bcrt1q...` / `bcrt1p...` | `< 50 MB` | Instant 1-ms local blocks. Practice breaking & fixing code offline. |
| **Level 2** | **Signet (BIP325)** | `-signet` | `tb1q...` / `tb1p...` | `~ 1 GB` | **Live global P2P network!** Syncs in minutes, connects to real nodes worldwide, uses free Signet sats. |
| **Level 3** | **Testnet4 (BIP94)** | `-testnet4` | `tb1q...` / `tb1p...` | `~ 5 GB` | Global Proof-of-Work test network with real ASIC miners. |
| **Level 4** | **Live Mainnet** | *(no flag!)* | `bc1q...` / `bc1p...` | `~ 6–10 GB` *(with `-prune=5500`)* | **Satoshi's real Bitcoin network (since Jan 3, 2009).** Real satoshis (`sats`), real sovereign savings. |

---

## Part 2: Step-by-Step — Moving to Live Global `Signet` & Sovereign `Mainnet`

### Step A: Graduate to Live Global `Signet` First (Zero Financial Risk, Real Global Peers)
Before touching real money on Mainnet, run your compiled node on **Signet** (`-signet`). Every command you learned on `-regtest` works identically on `-signet`, except now you are connected to live nodes across the planet and blocks arrive every ~10 minutes:

```bash
# 1. Start your compiled Bitcoin Core binary on the global Signet network
/Users/mac/bitcoin/build/bin/bitcoind -signet -daemon

# 2. Watch your node connect to real peers around the world and sync headers!
/Users/mac/bitcoin/build/bin/bitcoin-cli -signet getblockchaininfo
/Users/mac/bitcoin/build/bin/bitcoin-cli -signet getpeerinfo | grep '"subver"'

# 3. Create your live Signet wallet and generate a tb1q... address
/Users/mac/bitcoin/build/bin/bitcoin-cli -signet createwallet "stanley_signet_wallet"
/Users/mac/bitcoin/build/bin/bitcoin-cli -signet -rpcwallet=stanley_signet_wallet getnewaddress "first_live_test" "bech32"

# (When done testing Signet, stop it cleanly with: bitcoin-cli -signet stop)
```

### Step B: Launch Your Own Live `Mainnet` Node on Your Laptop (`-prune=5500`)
Many beginners think you need a 1,000 GB hard drive to run a real Mainnet Bitcoin node. **You do not!**
By passing `-prune=5500` (`5.5 GB`), your `bitcoind` downloads and **cryptographically verifies 100% of every block, signature, and UTXO since Satoshi's 2009 Genesis Block**, keeps the full live UTXO database (`chainstate/`), and deletes old historical block files so the entire Mainnet node takes **less than 12 GB** on your laptop:

```bash
# 1. Launch your own sovereign Mainnet full node in pruned mode (5.5 GB max block storage)
/Users/mac/bitcoin/build/bin/bitcoind -prune=5500 -dbcache=1024 -daemon

# 2. Check your live Mainnet verification progress (verificationprogress -> 1.0000)
/Users/mac/bitcoin/build/bin/bitcoin-cli getblockchaininfo
```

### Step C: Create & Fund Your Real Sovereign `Mainnet` Wallet (`bc1q...` / `bc1p...`)
When you are ready to hold real satoshis (`sats`) on Mainnet, **never keep unencrypted private keys on a hot server**. Use the exact Cold-to-Watch-Only architecture you practiced in Stage 07 and Stage 11:

```bash
# 1. Create a Mainnet wallet with an encrypted passphrase
bitcoin-cli createwallet "stanley_sovereign_mainnet" false false "YOUR_STRONG_PASSPHRASE_HERE"

# 2. Export ONLY the public descriptor (false = NO private keys!)
bitcoin-cli -rpcwallet=stanley_sovereign_mainnet listdescriptors false

# 3. Generate a real Mainnet Native SegWit (bc1q...) or Taproot (bc1p...) address
bitcoin-cli -rpcwallet=stanley_sovereign_mainnet getnewaddress "first_real_sats" "bech32"
bitcoin-cli -rpcwallet=stanley_sovereign_mainnet getnewaddress "taproot_vault" "bech32m"

# 4. Verify your own node recognizes the address as solvable & controlled by you BEFORE sending even 1000 sats:
bitcoin-cli -rpcwallet=stanley_sovereign_mainnet getaddressinfo <your_bc1_address>
```

---

## Part 3: How to Write Bitcoin Code From Pure Memory (The 4 Guiding Building Blocks)

You asked: *"How do I reach the point where I can write this code from my memory after understanding all the guiding blocks that Satoshi would appreciate?"*

Senior Bitcoin Core engineers do **not** memorize 300,000 lines of code. Instead, they know that **every piece of Bitcoin software is built from just 4 Universal Building Blocks**. Once you see these 4 blocks in your head, you can write any Bitcoin tool, test, or PR from a blank file:

```
+-----------------------------------------------------------------------+
| BLOCK 4: CONSENSUS INVARIANT GUARD (The Satoshi Shield)               |
|   Preconditions -> Bounds/Overflow Check -> Cryptographic Proof       |
+-----------------------------------------------------------------------+
                                  ^
+-----------------------------------------------------------------------+
| BLOCK 3: NODE RPC / P2P BRIDGE (Talking to bitcoind)                  |
|   getblockchaininfo | listunspent | createrawtransaction | sendrawtx  |
+-----------------------------------------------------------------------+
                                  ^
+-----------------------------------------------------------------------+
| BLOCK 2: UTXO & TRANSACTION STATE MACHINE                             |
|   Inputs (PrevOut txid:vout) ---> Outputs (nValue + scriptPubKey)     |
|   Rule: Sum(Inputs) - Sum(Outputs) == Miner Fee (>= 0)                |
+-----------------------------------------------------------------------+
                                  ^
+-----------------------------------------------------------------------+
| BLOCK 1: WIRE BYTES & HASH PRIMITIVES                                 |
|   CompactSize (VarInt) | Little-Endian Integers | SHA256(SHA256(b))   |
+-----------------------------------------------------------------------+
```

### Mental Checklist When Facing Any Blank File:
Whenever you sit down to write code from memory, ask yourself 4 questions in order:
1. **What are my inputs & outputs?** (Am I reading a `UTXO`? Am I serializing bytes? Am I calling an RPC?)
2. **What is the invariant that must NEVER break?**
   - *Supply Invariant:* `0 <= value <= MAX_MONEY` (no negative numbers, no overflow!).
   - *Conservation Invariant:* `Inputs >= Outputs` (no free money!).
   - *Uniqueness Invariant:* No duplicate inputs in the same transaction (`CVE-2018-17144`)!
   - *Memory/CPU Invariant:* Could a malicious peer send 1,000,000 items to crash my RAM?
3. **Check failures FIRST (Guard Clauses):**
   Notice how Satoshi and modern Bitcoin Core maintainers write functions in [`src/consensus/tx_check.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_check.cpp):
   ```cpp
   // ALWAYS reject bad states at the very top of the function:
   if (tx.vin.empty()) return state.Invalid(..., "bad-txns-vin-empty");
   if (tx.vout.empty()) return state.Invalid(..., "bad-txns-vout-empty");
   ```
   When you write code this way—checking every failure condition at the top before doing the work—your code becomes simple, flat, readable, and impossible to exploit.
4. **Write the test BEFORE or WITH the code:**
   Every function gets 2 tests:
   - **Test 1 (Happy Path):** Valid input succeeds.
   - **Test 2 (Adversarial Path):** Malicious/overflow/empty input is rejected with the exact expected error.

---

## Part 4: The 5 "Write From Memory" Blank-Page Katas

To train yourself to write code from memory, do **one Kata per week** without looking at the solution until you finish:

1. **Kata 1 (The RPC Bridge From Memory):**
   Open a blank `kata1.go` or `kata1.py`. Without looking at `00-start-small/first_app.go`, write a 25-line program from memory that calls `bitcoin-cli -regtest getblockcount` and prints the block hash of the tip (`getblockhash`).
2. **Kata 2 (The 61-Line Consensus Shield From Memory):**
   Open a blank function `CheckTxBasic(inputs []string, outputs []int64) error`. From memory, write the 4 checks from [`src/consensus/tx_check.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_check.cpp):
   - Non-empty inputs and outputs,
   - Each output `>= 0` and `<= 21_000_000 * 100_000_000`,
   - Running sum does not overflow `MAX_MONEY`,
   - No duplicate input `txid:vout` strings (using a `map[string]bool`).
3. **Kata 3 (Raw UTXO Spend From Memory):**
   Using only terminal commands (`listunspent`, `createrawtransaction`, `signrawtransactionwithwallet`, `sendrawtransaction`), spend a UTXO by hand without using `sendtoaddress`, calculating the exact miner fee yourself (`Input - Output = Fee`).
4. **Kata 4 (Double-SHA256 & Merkle Root From Memory):**
   Open a blank file and write `Hash256(data []byte) [32]byte` (`sha256.Sum256` twice) and `ReverseBytes32` from memory. Verify it on Satoshi's Genesis Block header!
5. **Kata 5 (Full PR Review & Mutation Test From Memory):**
   Pick any PR from `./lab.sh pr-list`, inspect its diff using `git diff`, run its C++ unit test in `test_bitcoin`, break the check to watch the test fail, restore it, and write a full `Tested ACK` review from memory.
