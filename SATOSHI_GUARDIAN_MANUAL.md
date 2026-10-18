# 🛡️ The Guardian's Manual: If Satoshi Taught His Son How to Protect Bitcoin

> *"The root problem with conventional currency is all the trust that's required to make it work. The central bank must be trusted not to debase the currency, but the history of fiat currencies is full of breaches of that trust."*  
> — **Satoshi Nakamoto** (February 11, 2009)

If Satoshi Nakamoto sat beside his son to pass down the guardianship of `bitcoin/bitcoin`, he would not start with syntax. He would teach him **why Bitcoin exists**, **which sacred lines of C++ stand between sound money and total network collapse**, **the historical bugs that almost killed Bitcoin**, and **how to audit every single Pull Request before it can ever be merged**.

---

## Chapter I: Why Bitcoin Exists (The Genesis Message)

Open [`/Users/mac/bitcoin/src/kernel/chainparams.cpp`](file:///Users/mac/bitcoin/src/kernel/chainparams.cpp#L67-L78) at line 75:

```cpp
static CBlock CreateGenesisBlock(uint32_t nTime, uint32_t nNonce, uint32_t nBits, int32_t nVersion, const CAmount& genesisReward)
{
    const char* pszTimestamp = "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks";
    const CScript genesisOutputScript = CScript() << "04678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5f"_hex << OP_CHECKSIG;
    return CreateGenesisBlock(pszTimestamp, genesisOutputScript, nTime, nNonce, nBits, nVersion, genesisReward);
}
```

Satoshi embedded that headline into Block `0` (`000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f`) for two reasons:
1. **Cryptographic Proof of No Pre-Mine:** It proved mathematically that no blocks could have been mined before January 3, 2009.
2. **The Moral & Monetary Anchor:** In fiat systems, when banks fail, central banks print money out of thin air and bail them out at the expense of every saver. In Bitcoin, **rules replace rulers**. Nobody—not miners, not billionaires, not core developers—can print a single satoshi beyond `21,000,000 BTC` (`2,100,000,000,000,000` satoshis).

Run `./lab.sh genesis` at any time to inspect the Genesis Block and the 61-line Consensus Shield on your machine.

---

## Chapter II: The 61-Line Consensus Shield (`src/consensus/tx_check.cpp`)

If you want to understand why Bitcoin Core reviewers are the most conservative engineers on Earth, read all 61 lines of [`/Users/mac/bitcoin/src/consensus/tx_check.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_check.cpp#L11-L60). Inside this single function (`CheckTransaction`) live the scars of **two catastrophic inflation bugs** that could have destroyed Bitcoin:

### 1. The 2010 Value Overflow Bug (`CVE-2010-5139` — Block 74,638)
- **What Happened:** On August 15, 2010, someone broadcasted a transaction containing two outputs of `92,233,720,368.54 BTC` each (`184.46 billion BTC` total). In Satoshi's original code, `nValueOut` was summed in a signed 64-bit integer (`int64_t`), which overflowed past `INT64_MAX` (`9,223,372,036,854,775,807` satoshis) and wrapped around to a **negative number**! Because the total output sum appeared negative, the fee check (`nValueIn >= nValueOut`) passed!
- **How Satoshi Fixed It (`src/consensus/tx_check.cpp`, lines 23–34):**
  ```cpp
  // Check for negative or overflow output values (see CVE-2010-5139)
  CAmount nValueOut = 0;
  for (const auto& txout : tx.vout)
  {
      if (txout.nValue < 0)
          return state.Invalid(TxValidationResult::TX_CONSENSUS, "bad-txns-vout-negative");
      if (txout.nValue > MAX_MONEY)
          return state.Invalid(TxValidationResult::TX_CONSENSUS, "bad-txns-vout-toolarge");
      nValueOut += txout.nValue;
      if (!MoneyRange(nValueOut))
          return state.Invalid(TxValidationResult::TX_CONSENSUS, "bad-txns-txouttotal-toolarge");
  }
  ```
- **The Lesson for Every PR You Review:** Never check `sum(A + B) <= MAX` without first checking that `A` and `B` individually lie within `[0, MAX_MONEY]` before addition!

### 2. The 2018 Duplicate-Input Inflation Bug (`CVE-2018-17144`)
- **What Happened:** To speed up block validation in Bitcoin Core 0.15, a PR removed a "redundant" duplicate-input check during UTXO spending, assuming it had already been checked earlier. An attacker mining a block could include a transaction whose `vin` array listed the **same `COutPoint(txid, vout)` twice** (`vin[0] == vin[1]`), spending a 10 BTC UTXO twice to create 20 BTC!
- **How It Was Fixed (`src/consensus/tx_check.cpp`, lines 36–45):**
  ```cpp
  // Check for duplicate inputs (see CVE-2018-17144)
  std::set<COutPoint> vInOutPoints;
  for (const auto& txin : tx.vin) {
      if (!vInOutPoints.insert(txin.prevout).second)
          return state.Invalid(TxValidationResult::TX_CONSENSUS, "bad-txns-inputs-duplicate");
  }
  ```
- **The Lesson for Every PR You Review:** **Performance optimizations must never weaken an invariant check.** Whenever a PR claims "this check is redundant and can be skipped for speed," treat it as guilty until proven innocent.

---

## Chapter III: Why Major Architectural PRs Were Merged Since 2009

To understand the entire history of `bitcoin/bitcoin`, map every major upgrade to the exact vulnerability or limitation in Satoshi's v0.1 code that it solved:

| Era / BIP | Protocol Upgrade | What Problem in Satoshi's v0.1 Did It Solve? | Where It Lives in `/Users/mac/bitcoin` |
| :--- | :--- | :--- | :--- |
| **BIP16 (2012)** | **Pay-to-Script-Hash (`P2SH`)** | Moved complex multisig scripts from the sender's `CTxOut` to the spender's input so senders only pay for a 20-byte hash. | [`src/script/interpreter.cpp`](file:///Users/mac/bitcoin/src/script/interpreter.cpp) |
| **BIP66 (2015)** | **Strict DER Signatures** | OpenSSL allowed platform-dependent lax ECDSA parsing (different OS architectures could disagree on signature validity -> chain split risk). Now Bitcoin Core uses `libsecp256k1`. | [`src/secp256k1/`](file:///Users/mac/bitcoin/src/secp256k1) |
| **BIP65 / BIP68 / BIP112 (2015–16)** | **CLTV & CSV Timelocks** | Satoshi's original `nLockTime` could not lock a specific UTXO in Script; `OP_CLTV` and `OP_CSV` enabled trustless Lightning payment channels & HTLCs. | [`src/script/interpreter.cpp`](file:///Users/mac/bitcoin/src/script/interpreter.cpp), [`src/consensus/tx_verify.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_verify.cpp) |
| **BIP141 / BIP143 (2017)** | **Segregated Witness (SegWit)** | Fixed **1) Third-party `txid` malleability** (which broke unconfirmed Lightning funding txs) and **2) $O(N^2)$ quadratic signature hashing** DoS. | [`src/validation.cpp`](file:///Users/mac/bitcoin/src/validation.cpp), [`src/script/interpreter.cpp`](file:///Users/mac/bitcoin/src/script/interpreter.cpp) |
| **BIP174 / BIP380 (2018–21)** | **PSBT & Output Descriptors** | Replaced fragile "bag-of-keys" legacy wallets with deterministic, checksummed `wpkh()`/`tr()` descriptors and airgapped hardware signing. | [`src/script/descriptor.cpp`](file:///Users/mac/bitcoin/src/script/descriptor.cpp), [`src/psbt.h`](file:///Users/mac/bitcoin/src/psbt.h) |
| **BIP340 / 341 / 342 (2021)** | **Schnorr, Taproot & Tapscript** | Replaced ECDSA with provably non-malleable, linear 64-byte Schnorr signatures and hid complex smart contracts inside a single 32-byte tweaked public key (`P2TR`). | [`src/script/interpreter.cpp`](file:///Users/mac/bitcoin/src/script/interpreter.cpp) |
| **BIP324 (2023–24)** | **v2 Encrypted P2P Transport** | Satoshi's v1 P2P messages were sent in plaintext TCP, allowing ISP/state eavesdropping and MitM tampering. | [`src/bip324.cpp`](file:///Users/mac/bitcoin/src/bip324.cpp) |
| **BIP431 (2024–25)** | **TRUC (`v3`) & 1P1C Package Relay** | Prevented mempool descendant pinning against Lightning commitment transactions and enabled `0-fee` parent + child atomic fee bumping. | [`src/policy/truc_policy.cpp`](file:///Users/mac/bitcoin/src/policy/truc_policy.cpp) |

---

## Chapter IV: The 6-Point Maintainer Audit Checklist (`./lab.sh pr-audit <PR>`)

Never review a Bitcoin Core PR by just skimming it and writing "LGTM". Before any PR can be merged into `bitcoin/bitcoin`, audit it against these 6 questions:

### 1. Which Concentric Ring Does This PR Touch?
Bitcoin Core is structured in concentric rings of risk:
- 🔴 **Ring 0 — Consensus (`src/consensus/`, `src/script/`, `src/primitives/`, `src/pow.cpp`, `src/secp256k1/`):** A bug here causes a **chain split** or **supply inflation**. Requires formal mathematical proof, exhaustive fuzzing, and 100% deterministic behavior across 32-bit/64-bit, little/big-endian, ARM/x86/RISC-V.
- 🟠 **Ring 1 — Validation & Mempool Policy (`src/validation.cpp`, `src/txmempool.cpp`, `src/policy/`):** A bug here causes **mempool pinning, CPU/RAM exhaustion DoS, or censorship of honest transactions** (like Lightning force-closes).
- 🟡 **Ring 2 — P2P Networking (`src/net.cpp`, `src/net_processing.cpp`, `src/addrman.cpp`):** A bug here enables **Eclipse attacks** (isolating a victim node onto an attacker's fake chain) or **remote crash / OOM via unauthenticated P2P packets**.
- 🟢 **Ring 3 — Wallet, RPC & Build (`src/wallet/`, `src/rpc/`, `test/`):** A bug here risks user fund loss, privacy leaks, or broken downstream integrations.

### 2. Why Was This PR Written? (The Problem & Invariant)
Before reading a single line of C++, state in one sentence:
- *What bug, DoS vector, tech debt, or protocol feature does this PR address?*
- *What invariant must remain true before and after this PR runs?*

### 3. Integer Arithmetic, Serialization & Memory Bounds
Inspect every `+`, `-`, `*`, `/`, and cast in the diff:
- Could `a + b` overflow `int64_t` or `CAmount`? Could `a - b` underflow an unsigned `size_t`?
- If a vector is resized based on network input (`v.resize(n)`), is `n` bounded by `MAX_SIZE` or `MAX_PROTOCOL_MESSAGE_LENGTH`?

### 4. Concurrency & Lock Ordering (`cs_main`, `pool.cs`)
Bitcoin Core is heavily multithreaded (`b-msghand`, `b-loadblk`, `b-http`).
- Check every `LOCK(...)` and `AssertLockHeld(...)` annotation in the touched functions.
- Does this PR acquire `cs_main` and `mempool.cs` in the exact documented order (`LOCK2(cs_main, mempool.cs)`), preventing deadlocks?

### 5. Adversarial P2P & Mempool Simulation
Ask yourself: *"If I have 0 BTC and 100 Tor IP addresses, how can I abuse this new code to crash, stall, or bloat an honest node?"*
- Does a peer get penalized or rate-limited before expensive disk I/O or signature verification occurs?

### 6. Mutation Testing (Breaking the Code to Prove the Test Works)
A test that passes when the code is broken is useless.
1. Checkout the PR.
2. Delete or invert the core `if (...)` condition introduced by the PR.
3. Recompile (`cmake --build build -j4`) and run the test (`test_runner.py` or `ctest`).
4. Verify that the test **fails**, then restore the code and verify it **passes**.

---

## 🛠️ Practice Auditing Real PRs Offline Right Now

Run our automated PR Security Auditor on any PR stored in `/Users/mac/bitcoin`:

```bash
# 1. Inspect Satoshi's Genesis Block & the 61-Line Consensus Shield (CVE-2010-5139 & CVE-2018-17144)
./lab.sh genesis

# 2. Run a full 6-Point Guardian Security Audit on any upstream PR offline:
./lab.sh pr-audit 35320   # Ring 3/Crypto: BIP32 seed length validation in CExtKey::SetSeed
./lab.sh pr-audit 34628   # Ring 2/P2P: Replace per-peer tx rate-limiting with global rate limits
./lab.sh pr-audit 35664   # Ring 0/Consensus Script: CLTV & CHECKSIGVERIFY failure-path vectors
./lab.sh pr-audit 33014   # Ring 3/PSBT: Fix bug in descriptorprocesspsbt on invalid signatures
```
