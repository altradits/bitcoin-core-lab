# 🥋 Stage 09: The Bitcoin Core Bug Dojo & PR Fix Arena (Zero-Outside-Research Training)

## Purpose: Learn by Breaking, Fixing & Auditing Real Upstream Bugs
You do not become a reliable Bitcoin Core developer by only running scripts that already pass. You become one by:
1. **Breaking the code** into its exact state *before* an upstream `bitcoin/bitcoin` PR or CVE patch (`./lab.sh dojo break`),
2. **Watching the exploit succeed** and the unit test fail (`./lab.sh dojo check`),
3. **Writing the consensus/policy fix yourself** in [`dojo_missions.go`](./dojo_missions.go) using the self-contained briefing below (zero outside research required),
4. **Reviewing the exact upstream PR** (`./lab.sh pr-audit <PR_NUMBER>`) that fixed that bug in `bitcoin/bitcoin`!

---

## ⚡ Quick Commands (`./lab.sh dojo`)

```bash
# 1. Load the 5 broken pre-PR vulnerabilities into dojo_missions.go
./lab.sh dojo break

# 2. Run the test suite (or a single Mission 1..5) to see what fails
./lab.sh dojo check       # Runs all 5 missions
./lab.sh dojo check 1     # Runs Mission 1 only

# 3. Edit 09-bug-dojo-and-pr-mastery/dojo_missions.go to fix the bugs, then re-test!
./lab.sh dojo check

# 4. Restore the verified upstream reference solutions at any time
./lab.sh dojo solve
```

---

## 📖 Self-Contained Mission Briefings (Everything You Need to Fix & Review Each PR)

### 🔴 Mission 1: The Consensus Shield (`CVE-2010-5139` & `CVE-2018-17144`)
- **Upstream C++ File:** [`/Users/mac/bitcoin/src/consensus/tx_check.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_check.cpp#L11-L60) (`CheckTransaction`)
- **What Is Broken in `broken/dojo_missions_broken.go`:**
  1. It sums `nValueOut += txout.Value` *before* checking if each individual `txout.Value` is negative or `> MAX_MONEY`. When an attacker passes `math.MaxInt64 - 100` and `200`, signed 64-bit integer addition overflows into a negative number (`-9223372036854775709`), bypassing `nValueOut > MAX_MONEY`!
  2. It never checks if `tx.Vin` contains the same `OutPoint{Txid, Vout}` twice (`CVE-2018-17144`), allowing a single transaction to spend the same UTXO twice!
- **Exact Fix to Write in `CheckTransactionConsensus`:**
  1. Inside the `for _, txout := range tx.Vout` loop, check `if txout.Value < 0` (`"bad-txns-vout-negative"`) and `if txout.Value > MAX_MONEY` (`"bad-txns-vout-toolarge"`) **before** `nValueOut += txout.Value`, and then check `if nValueOut < 0 || nValueOut > MAX_MONEY` (`"bad-txns-txouttotal-toolarge"`).
  2. Create `seen := make(map[OutPoint]bool)` and loop over `tx.Vin`; if `seen[txin]` is true, return `errors.New("bad-txns-inputs-duplicate")`.

---

### 🟢 Mission 2: BIP32 HD Seed Length Validation (Upstream PR `#35320`)
- **Upstream C++ File:** [`/Users/mac/bitcoin/src/key.cpp`](file:///Users/mac/bitcoin/src/key.cpp#L369-L375) (`CExtKey::SetSeed`)
- **Local PR Audit Report:** [`pr-reviews/PR-35320-AUDIT.md`](../pr-reviews/PR-35320-AUDIT.md) (`./lab.sh pr-audit 35320`)
- **Self-Contained Theory:**
  - In **BIP32** (Hierarchical Deterministic Wallets), a master extended key (`xprv`) is derived by computing $\text{HMAC-SHA512}(\text{key}=\text{"Bitcoin seed"}, \text{data}=\text{seed})$.
  - BIP32 mandates that `seed` must be between **128 bits (`16 bytes`) and 512 bits (`64 bytes`)** inclusive.
  - Prior to `bitcoin/bitcoin#35320`, `CExtKey::SetSeed` did not assert `16 <= seed.size() && seed.size() <= 64`, meaning a caller bug passing an empty or 4-byte seed would silently generate a trivially brute-forceable master key!
- **Exact Fix to Write in `DeriveBIP32MasterKey`:**
  - Reject any `seed` where `len(seed) < 16 || len(seed) > 64` before running `HMAC-SHA512`.

---

### 🟠 Mission 3: Sigop-Adjusted Mempool Virtual Size (Upstream PR `#32800`)
- **Upstream C++ File:** [`/Users/mac/bitcoin/src/rpc/mempool.cpp`](file:///Users/mac/bitcoin/src/rpc/mempool.cpp) & [`/Users/mac/bitcoin/src/policy/policy.cpp`](file:///Users/mac/bitcoin/src/policy/policy.cpp) (`GetVirtualTransactionSize`)
- **Local PR Audit Report:** [`pr-reviews/PR-32800-AUDIT.md`](../pr-reviews/PR-32800-AUDIT.md) (`./lab.sh pr-audit 32800`)
- **Self-Contained Theory:**
  - Under **BIP141**, a transaction's raw virtual size is:
    $$\text{vsize\_bip141} = \lceil \text{txWeight} / 4 \rceil = \lfloor (\text{txWeight} + 3) / 4 \rfloor$$
  - However, verifying elliptic curve signatures (`OP_CHECKSIG`, `OP_CHECKMULTISIG`) is CPU-intensive. If a transaction is tiny in bytes (`400 WU` = `100 vB`) but contains `80` signature operations (`sigOpCost = 80`), charging fees only for `100 vB` would let an attacker pack a block with CPU-exhausting signature checks for pennies!
  - Therefore, Bitcoin Core's mempool policy scales each sigop by `DEFAULT_BYTES_PER_SIGOP = 20`:
    $$\text{effectiveWeight} = \max(\text{txWeight}, \text{sigOpCost} \times 20)$$
    $$\text{vsize\_adjusted} = \lfloor (\text{effectiveWeight} + 3) / 4 \rfloor$$
  - Upstream PR `#32800` updated Bitcoin Core's RPCs to expose both `vsize_bip141` and `vsize_adjusted` clearly.
- **Exact Fix to Write in `ComputeMempoolVsizes`:**
  - Compute `sigOpWeight := sigOpCost * BYTES_PER_SIGOP`, take `effectiveWeight = max(txWeight, sigOpWeight)`, and return `vsizeAdjusted = (effectiveWeight + 3) / 4`.

---

### 🟠 Mission 4: BIP125 Replace-By-Fee Anti-DoS Rules (`PaysMoreThanConflicts` & `PaysForRBF`)
- **Upstream C++ File:** [`/Users/mac/bitcoin/src/policy/rbf.cpp`](file:///Users/mac/bitcoin/src/policy/rbf.cpp#L134-L185)
- **Self-Contained Theory:**
  - If a node accepted any replacement transaction that simply paid `replacementFee > originalFee`, two attacks would happen immediately:
    1. **Feerate Downgrade Attack:** An attacker replaces a `100 vB` transaction paying `1,000 sats` (`10 sat/vB`) with a huge `200 vB` transaction paying `1,200 sats` (`6 sat/vB`), **lowering** the feerate of the next block!
       - **Fix (`PaysMoreThanConflicts`):** Require `replacementFee / replacementVsize > originalFee / originalVsize`. To avoid floating-point imprecision, cross-multiply using pure integers: `replacementFee * originalVsize > originalFee * replacementVsize`.
    2. **Free Relay Bandwidth DoS (Rule #4 in `PaysForRBF`):** An attacker broadcasts a transaction and replaces it 10,000 times, adding only `+1 sat` each time, forcing thousands of nodes globally to relay megabytes of traffic for almost zero fee.
       - **Fix (`PaysForRBF` Rule #4):** Require `(replacementFee - originalFee) >= replacementVsize * incrementalRelayFeePerVB`.

---

### 🟢 Mission 5: PSBT Partial Signature Validation (Upstream PR `#33014`)
- **Upstream C++ File:** [`/Users/mac/bitcoin/src/wallet/rpc/spend.cpp`](file:///Users/mac/bitcoin/src/wallet/rpc/spend.cpp) (`descriptorprocesspsbt`)
- **Local PR Audit Report:** [`pr-reviews/PR-33014-AUDIT.md`](../pr-reviews/PR-33014-AUDIT.md) (`./lab.sh pr-audit 33014`)
- **Self-Contained Theory:**
  - In a multi-party or hardware-wallet **BIP174 PSBT** signing flow, an untrusted coordinator may hand your node a PSBT that already contains partial signatures in `PSBT_IN_PARTIAL_SIG`.
  - If an existing or newly supplied signature is corrupted (e.g., fails BIP66 DER length bounds `9..73 bytes` or fails signature verification), the PSBT processor must deterministically reject the invalid signature rather than crashing or silently accepting corrupted witness data.
