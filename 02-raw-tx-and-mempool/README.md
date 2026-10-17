# Hour 02: Raw Transaction Construction, Implicit Fee Guardrails & Mempool Weight Accounting

## Objective
Spend the matured `25.00000000 BTC` coinbase UTXO (`93328febe1e73e7d3bbb8dc9256fc57ae704d883b5538919a44c821ef957a29a:0`) using low-level raw transaction RPCs (`createrawtransaction`, `signrawtransactionwithwallet`, `sendrawtransaction`), verify why omitting a change output triggers the `-maxtxfee` guardrail, inspect SegWit weight/vsize accounting in `getmempoolentry`, and verify miner fee collection + BIP141 witness commitment in the confirmation block.

---

## 1. Upstream C++ Consensus & Mempool References

### Implicit Fee Calculation (`src/consensus/tx_verify.cpp`)
A serialized Bitcoin transaction (`CTransaction` in `src/primitives/transaction.h`) contains **no explicit `fee` field**. Instead, consensus computes the fee strictly as the residual difference between total inputs and total outputs inside `Consensus::CheckTxInputs`:
```cpp
const CAmount value_out = tx.GetValueOut();
if (nValueIn < value_out) {
    return state.Invalid(TxValidationResult::TX_CONSENSUS, "bad-txns-in-belowout",
        strprintf("value in (%s) < value out (%s)", FormatMoney(nValueIn), FormatMoney(value_out)));
}
const CAmount txfee_aux = nValueIn - value_out;
```

### SegWit Transaction Weight & Virtual Size (`src/consensus/validation.h`)
Under BIP141, non-witness bytes are weighted by `WITNESS_SCALE_FACTOR = 4`, while witness bytes (`txinwitness`) count as 1 weight unit (WU) per byte:
$$\text{weight} = (\text{base\_size} \times 3) + \text{total\_size}$$
$$\text{vsize} = \lceil \text{weight} / 4 \rceil$$

---

## 2. Empirical Execution on Regtest

### Step 1: The Implicit Fee Trap (Omitting the Change Output)
Spending the `25.00000000 BTC` UTXO to pay `1.00000000 BTC` to `kisumu_merchant` (`bcrt1qtxwmxk3hyfvaph8z4eacuh0df56kvd8fuz57xy`) without specifying a change output:
```bash
RAW_TX_DANGEROUS=$(bitcoin-cli -regtest createrawtransaction \
  '[{"txid":"93328febe1e73e7d3bbb8dc9256fc57ae704d883b5538919a44c821ef957a29a","vout":0}]' \
  '[{"bcrt1qtxwmxk3hyfvaph8z4eacuh0df56kvd8fuz57xy":1.0}]')
```
Attempting to broadcast after signing:
```text
error code: -25
error message:
Fee exceeds maximum configured by user (e.g. -maxtxfee, maxfeerate)
```
**Why:** Without a change output, `25.00000000 - 1.00000000 = 24.00000000 BTC` is implicitly offered as a miner fee. Bitcoin Core's node policy guardrail (`maxtxfee`, defaulting to `0.10 BTC`) intercepts the broadcast before the transaction reaches the P2P network.

---

### Step 2: Proper Raw Transaction with Internal Bech32 Change Output
Generating an internal BIP84 change address (`m/84h/1h/0h/1/*`) and allocating `23.99990000 BTC` change (leaving an explicit `0.00010000 BTC` / `10,000 sat` fee):
```bash
CHANGE_ADDR=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" getrawchangeaddress "bech32")
# Output: bcrt1qlyq6n7x2jusfcsly2azc7yjmhqmd6v53n8plev

RAW_TX_SAFE=$(bitcoin-cli -regtest createrawtransaction \
  '[{"txid":"93328febe1e73e7d3bbb8dc9256fc57ae704d883b5538919a44c821ef957a29a","vout":0}]' \
  "[{\"bcrt1qtxwmxk3hyfvaph8z4eacuh0df56kvd8fuz57xy\":1.0},{\"$CHANGE_ADDR\":23.99990000}]")
```

### Step 3: SegWit Signing, `txid` vs `wtxid`, and Witness Discount
Decoded signed transaction:
```json
{
  "txid": "4936ec7c5e2b1f87528e23fbc8724436a09cd8253d8ccd1459129b95434ca8b4",
  "hash": "408cd807e7a07e8dc8c6eb0f17bc681aa6dbb4e835704737f0f49ce5bc80b1e7",
  "version": 2,
  "size": 222,
  "vsize": 141,
  "weight": 561,
  "locktime": 0,
  "vin": [
    {
      "txid": "93328febe1e73e7d3bbb8dc9256fc57ae704d883b5538919a44c821ef957a29a",
      "vout": 0,
      "scriptSig": { "asm": "", "hex": "" },
      "txinwitness": [
        "3044022004f1cb8d08bc52f0609882d6e7d2f77ceca3e657b2351738e79b2e249c59f29302206685cd2b5c1c4b3eacdfb27ed0971bd6f73c5feb589b3bc1e9d96e5ed8e5127301",
        "03e5e984e15d364d2dba11671dbdb9c24a2ff1f23cc15b2de3af3344221e764bcf"
      ],
      "sequence": 4294967293
    }
  ]
}
```
Key protocol observations:
1. **Malleability Fix (`txid` != `wtxid`):** `scriptSig` is completely empty (`""`). The ECDSA signature (DER-encoded + `0x01` `SIGHASH_ALL`) and 33-byte compressed public key live in `txinwitness`. Because `txid` hashes only the non-witness data (`113` base bytes), third-party signature malleation cannot alter `txid` (`4936ec7c...`), making unconfirmed Lightning funding transactions safe to chain off of.
2. **Weight Math Verification:**
   - Base size (without witness): `113 bytes`
   - Total size (with `109 bytes` of witness data): `222 bytes`
   - $\text{weight} = (113 \times 3) + 222 = 339 + 222 = 561\text{ WU}$
   - $\text{vsize} = \lceil 561 / 4 \rceil = 141\text{ vB}$

---

### Step 4: Mempool Inspection (`getmempoolentry`)
```json
{
  "vsize": 141,
  "weight": 561,
  "height": 303,
  "wtxid": "408cd807e7a07e8dc8c6eb0f17bc681aa6dbb4e835704737f0f49ce5bc80b1e7",
  "fees": {
    "base": 0.00010000,
    "modified": 0.00010000,
    "ancestor": 0.00010000,
    "descendant": 0.00010000
  },
  "bip125-replaceable": true
}
```
Because `createrawtransaction` sets `nSequence = 0xfffffffd` (`4294967293 < 0xfffffffe`), the transaction signals **BIP125 Opt-in Replace-By-Fee (`bip125-replaceable: true`)**.

---

### Step 5: Block 304 Confirmation & BIP141 Witness Commitment
Mining block 304 (`14121b7288b16f3bb80261111654115c9aad5baaf42395f05758bbd92a0cc588`) confirms the transaction and produces two outputs in the block's coinbase transaction:
```json
[
  {
    "value": 12.5001,
    "n": 0,
    "scriptPubKey": {
      "asm": "0 c68297ba384af46c1d711793ba3fb05fd5b9e67d",
      "address": "bcrt1qc6pf0w3cft6xc8t3z7fm50astl2mnenaxhuxn3",
      "type": "witness_v0_keyhash"
    }
  },
  {
    "value": 0.0,
    "n": 1,
    "scriptPubKey": {
      "asm": "OP_RETURN aa21a9ed5b6bd325f2453e5172165d992839c405f0c87c13675c24f123d6b496395ac60f",
      "hex": "6a24aa21a9ed5b6bd325f2453e5172165d992839c405f0c87c13675c24f123d6b496395ac60f",
      "type": "nulldata"
    }
  }
]
```
- **`vout[0]` (`12.50010000 BTC`):** Combines the 3rd-epoch block subsidy (`12.50000000 BTC`) + our exact transaction fee (`0.00010000 BTC`).
- **`vout[1]` (`OP_RETURN aa21a9ed...`):** The mandatory **BIP141 Witness Commitment** (`0xaa21a9ed` header followed by the 32-byte SHA256d hash of the witness Merkle root and witness reserved value), anchoring all SegWit signatures in the block.
