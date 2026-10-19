# Book 4: Transactions, Bitcoin Script, Mempool Policy & Consensus Engine (From Memory)

> **Purpose of This Offline Book:**
> Covers the exact wire format, stack-machine opcodes, timelock encodings, weight/vbytes math, and PoW consensus rules required for Stages `02`, `03`, `05`, `06`, `09`, `10`, `11` and the Bug Dojo (`CVE-2010-5139` & `CVE-2018-17144`).

---

## Chapter 1: Legacy vs SegWit (BIP141) Transaction Byte Layout

### 1.1 Legacy Serialization (Used to compute `txid` = `DoubleSHA256(legacy_bytes)`)
```text
[nVersion: 4B LE]
[tx_in_count: CompactSize]
  For each input:
    [prev_txid: 32B internal order]
    [prev_vout: 4B LE]
    [scriptSig_len: CompactSize]
    [scriptSig: scriptSig_len bytes]
    [nSequence: 4B LE]
[tx_out_count: CompactSize]
  For each output:
    [nValue: 8B LE (satoshis)]
    [scriptPubKey_len: CompactSize]
    [scriptPubKey: scriptPubKey_len bytes]
[nLockTime: 4B LE]
```

### 1.2 SegWit (BIP141) Serialization (Used to compute `wtxid` = `DoubleSHA256(segwit_bytes)`)
```text
[nVersion: 4B LE]
[marker: 0x00 (1B)]   <-- Impossible in legacy tx_in_count because valid transactions have >= 1 input!
[flag:   0x01 (1B)]
[tx_in_count ... inputs (with empty scriptSig 0x00 for native SegWit)]
[tx_out_count ... outputs]
[witness stacks: 1 stack per input]
[nLockTime: 4B LE]
```

> **Why SegWit Fixed Transaction Malleability (Required for Lightning):**
> Because `txid` hashes the **Legacy serialization** (which omits the `[witness]` field!), an attacker or miner who mutates a signature inside the `[witness]` changes the `wtxid` **without changing the `txid`**! Thus child transactions (like Lightning commitment transactions) spending `prev_txid` never break!

---

## Chapter 2: Transaction Weight, Virtual Bytes (`vB`) & Fee Rate Math (Stages 03 & 11)

$$\text{Weight (WU)} = 4 \times (\text{Non-Witness Bytes}) + 1 \times (\text{Witness Bytes})$$

$$\text{Virtual Size (vbytes)} = \left\lceil \frac{\text{Weight}}{4} \right\rceil = \frac{\text{Weight} + 3}{4} \quad \text{(integer division)}$$

$$\text{Fee (sats)} = \text{vbytes} \times \text{Fee Rate (sat/vB)}$$

### Common Input & Output Virtual Sizes (Memorize These!)
- **Base Transaction Overhead (version + marker/flag + counts + locktime):** `~10.5 vB`
- **P2WPKH Input (`bc1q`):** `68 vB` | **P2WPKH Output:** `31 vB`
- **P2TR Key-Path Input (`bc1p`):** `57.5 vB` | **P2TR Output:** `43 vB`

---

## Chapter 3: The 4 Bitcoin Timelocks (Stage 06 & Lightning Prerequisites)

| Timelock | Scope | Enforced By | Encoded Where |
| :--- | :--- | :--- | :--- |
| **`nLockTime`** | Transaction-level **Absolute** | Consensus (`IsFinalTx`) | Tx `nLockTime` (`< 500,000,000` = Block Height; `>= 500,000,000` = Unix Timestamp). Disabled if all inputs have `nSequence == 0xffffffff`! |
| **`nSequence` (BIP68)** | Input-level **Relative** | Consensus (`SequenceLocks`) | Tx input `nSequence` (when `nVersion >= 2` and bit 31 `1 << 31` is `0`). Bit 22 (`1 << 22`) selects 512-second time units vs blocks; lower 16 bits (`0xffff`) hold the value. |
| **`OP_CHECKLOCKTIMEVERIFY` (BIP65)** | Script-level **Absolute** | Script (`EvalScript`) | Compares top stack item against the spending tx's `nLockTime` (fails if `nSequence == 0xffffffff` or types don't match). Does **not** pop the stack (`OP_DROP` follows it). |
| **`OP_CHECKSEQUENCEVERIFY` (BIP112)** | Script-level **Relative** | Script (`EvalScript`) | Compares top stack item against the spending input's `nSequence` (requires `nVersion >= 2`). Used in **every Lightning commitment `to_local` output**! |

---

## Chapter 4: The 2 Historic Consensus CVEs (Stage 09 & Bug Dojo)

1. **`CVE-2010-5139` (184-Billion BTC Value Overflow):**
   - Pre-fix `CheckTransaction()` summed outputs without checking `MoneyRange(txout.nValue)` on each output or checking `MoneyRange(nValueOut)` after each addition.
2. **`CVE-2018-17144` (Duplicate-Input Inflation Bug):**
   - A single transaction referencing the **exact same `COutPoint(txid, vout)` twice** in `tx.vin` could spend the same coin twice if `CheckTransaction()` skipped the `std::set<COutPoint> vInOutPoints` duplicate check!

---

## 🧠 Blind Recall Challenges (Close This File & Write From Memory!)

1. **Drill 4.1 (Weight & vBytes):** A SegWit transaction has `100` non-witness bytes and `110` witness bytes. Compute its exact **Weight (WU)** and **Virtual Size (`vbytes`)** from memory using integer math `(weight + 3) / 4`.
2. **Drill 4.2 (BIP68 Bitmask):** Write a function `IsBIP68Active(txVersion int32, nSequence uint32) bool` from memory that checks `txVersion >= 2` and bit 31 (`nSequence & (1 << 31) == 0`).
3. **Drill 4.3 (SegWit Marker Trick):** Explain in one sentence why a SegWit parser seeing `0x00` immediately after `nVersion` knows with 100% certainty that it is reading a SegWit transaction and not a Legacy transaction.
4. **Drill 4.4 (Duplicate Input Check):** Write `HasDuplicateInputs(inputs []OutPoint) bool` in Go from memory using a `map[OutPoint]struct{}`.
