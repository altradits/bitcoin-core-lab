# Hour 03: BIP125 Replace-By-Fee (RBF), Relay DoS Rules & Child-Pays-For-Parent (CPFP) Package Accounting

## Objective
Verify the two fundamental mempool fee-bumping mechanisms used by Bitcoin wallets and Lightning Network nodes (e.g., force-close anchor outputs):
1. **Sender-side Fee Bumping (BIP125 Opt-in RBF):** Trigger Rule #4 (`PaysForRBF` incremental relay bandwidth check) in `src/policy/rbf.cpp`, then broadcast a valid replacement that evicts the original conflicting transaction.
2. **Receiver-side Fee Bumping (CPFP):** Spend an unconfirmed parent output with a high-feerate child transaction, verify `ancestor`/`descendant` package feerate accounting in `CTxMemPool`, and confirm topological block assembly in `src/node/miner.cpp`.

---

## 1. Upstream C++ Policy & Miner References

### BIP125 RBF Signaling (`src/policy/rbf.cpp` & `src/util/rbf.cpp`)
A transaction opts into BIP125 replacement if any input sets `nSequence < 0xfffffffe` (`MAX_BIP125_RBF_SEQUENCE = 0xfffffffd` = `4294967293`), or if it spends an unconfirmed parent that signals RBF (`IsRBFOptIn`).

### RBF DoS Protection — Rule #3 & Rule #4 (`src/policy/rbf.cpp`)
```cpp
std::optional<std::string> PaysForRBF(CAmount original_fees,
                                      CAmount replacement_fees,
                                      size_t replacement_vsize,
                                      CFeeRate relay_fee,
                                      const uint256& txid)
{
    // Rule #3: The replacement fees must be greater than or equal to fees of the
    // transactions it replaces, otherwise the bandwidth used by those conflicting transactions
    // would not be paid for.
    if (replacement_fees < original_fees) {
        return strprintf("rejecting replacement %s, less fees than conflicting txs; %s < %s",
                         txid.ToString(), FormatMoney(replacement_fees), FormatMoney(original_fees));
    }

    // Rule #4: The new transaction must pay for its own bandwidth. Otherwise, we have a DoS
    // vector where attackers can cause a transaction to be replaced (and relayed) repeatedly by
    // increasing the fee by tiny amounts.
    CAmount additional_fees = replacement_fees - original_fees;
    if (additional_fees < relay_fee.GetFee(replacement_vsize)) {
        return strprintf("rejecting replacement %s, not enough additional fees to relay; %s < %s",
                         txid.ToString(),
                         FormatMoney(additional_fees),
                         FormatMoney(relay_fee.GetFee(replacement_vsize)));
    }
    return std::nullopt;
}
```

### CPFP Ancestor Package Selection (`src/node/miner.cpp`)
In `BlockAssembler::addPackageTxs`, the miner sorts mempool candidates by **ancestor feerate** (`GetModFeesWithAncestors() / GetSizeWithAncestors()`), allowing a high-feerate child transaction to pull its low-feerate unconfirmed parent into the next block.

---

## 2. Empirical Execution on Regtest

### Part A: BIP125 Replace-By-Fee (RBF)

#### 1. Broadcast Original Low-Fee Transaction (`TX_V1`)
Spending `kisumu_miner` UTXO `4936ec7c5e2b1f87528e23fbc8724436a09cd8253d8ccd1459129b95434ca8b4:1` (`23.99990000 BTC`) with `nSequence = 4294967293` (`0xfffffffd`) and a `200 sat` (`0.00000200 BTC`) fee:
- **`TXID_V1`**: `64ad1c685d1a94774391f4e781798f7655da5e0c60db369654b4988eb11368f5`
- **`vsize`**: `141 vB` (`1.42 sat/vB`)
- **`bip125-replaceable`**: `true`

#### 2. Triggering `PaysForRBF` Rule #4 (Insufficient Incremental Relay Fee)
Attempting to replace `TX_V1` with `TX_V2_BAD` paying `250 sats` (`+50 sats` additional fee) for a `141 vB` transaction (where `incrementalrelayfee = 1 sat/vB` requires at least `+141 sats`):
```text
error code: -26
error message:
insufficient fee, rejecting replacement 41561bba65e22dae0661317c25ab955ad11ce51db8dea8bd025b10d59ca157eb, not enough additional fees to relay; 0.0000005 < 0.00000141
```

#### 3. Broadcasting Valid Replacement (`TX_V2_GOOD`)
Increasing total fee to `5,000 sats` (`0.00005000 BTC`, `+4,800 sats >= 141 sats` relay threshold) by reducing the miner's change output from `21.99989800 BTC` to `21.99985000 BTC`:
- **`TXID_V2_GOOD`**: `4305a8869acb989d19caff389d888a95dfbc44b41506da9600a6b3f4cf8fa215`
- Querying `getmempoolentry` on `TXID_V1` now returns:
  ```text
  error code: -5
  error message: Transaction not in mempool
  ```

---

### Part B: Child-Pays-For-Parent (CPFP) Package Accounting

While `TX_V2_GOOD` (`141 vB`, `5,000 sats` = `35.46 sat/vB`) is still unconfirmed in the mempool, `kisumu_merchant` spends its unconfirmed `2.00000000 BTC` output (`4305a886...:0`) to a cold storage address with a `20,000 sat` (`0.00020000 BTC`) fee:
- **`TXID_CHILD`**: `473530ec54566550bbf2da78749b780f546c37fd2a9105943ec904e8a528f481` (`110 vB`, `181.82 sat/vB`)

#### Mempool Package State (`getmempoolentry`)

**Parent (`4305a886...`):**
```json
{
  "vsize": 141,
  "weight": 561,
  "descendantcount": 2,
  "descendantsize": 251,
  "ancestorcount": 1,
  "ancestorsize": 141,
  "fees": {
    "base": 0.00005000,
    "modified": 0.00005000,
    "ancestor": 0.00005000,
    "descendant": 0.00025000
  },
  "spentby": [
    "473530ec54566550bbf2da78749b780f546c37fd2a9105943ec904e8a528f481"
  ]
}
```

**Child (`473530ec...`):**
```json
{
  "vsize": 110,
  "weight": 437,
  "descendantcount": 1,
  "descendantsize": 110,
  "ancestorcount": 2,
  "ancestorsize": 251,
  "fees": {
    "base": 0.00020000,
    "modified": 0.00020000,
    "ancestor": 0.00025000,
    "descendant": 0.00020000
  },
  "depends": [
    "4305a8869acb989d19caff389d888a95dfbc44b41506da9600a6b3f4cf8fa215"
  ]
}
```

#### Package Feerate Math
- **Parent standalone feerate:** $5,000\text{ sats} / 141\text{ vB} = 35.46\text{ sat/vB}$
- **Child standalone feerate:** $20,000\text{ sats} / 110\text{ vB} = 181.82\text{ sat/vB}$
- **Combined Ancestor Package feerate:**
  $$\frac{\text{fees.ancestor}}{\text{ancestorsize}} = \frac{5,000 + 20,000}{141 + 110} = \frac{25,000\text{ sats}}{251\text{ vB}} = 99.60\text{ sat/vB}$$

#### Topological Block Confirmation (Block 305)
Mining block `05b9edcf10804aa30f61a0737c7a773064748ba36d91dc2a6682f890d6d2b175` confirms the package in strict topological dependency order:
```json
{
  "height": 305,
  "tx": [
    "50f287491c200f3c0b665686e48f1a516befd3e6846f592c3ffc1dba69808f46",
    "4305a8869acb989d19caff389d888a95dfbc44b41506da9600a6b3f4cf8fa215",
    "473530ec54566550bbf2da78749b780f546c37fd2a9105943ec904e8a528f481"
  ]
}
```
