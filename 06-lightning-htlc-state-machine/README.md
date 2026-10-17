# Hour 06: Lightning Layer 2 — P2WSH HTLC State Machine, `OP_SHA256` Preimage Claim & BIP68 `OP_CHECKSEQUENCEVERIFY` Timeout

## Objective
Construct, fund, and spend a native SegWit v0 (`P2WSH`) **Hash Time-Locked Contract (HTLC)** on `bitcoind -regtest`, verifying both execution branches in the C++ Script interpreter (`src/script/interpreter.cpp`) and BIP68 sequence lock enforcement (`src/consensus/tx_verify.cpp`):
1. **`OP_IF` (Preimage Claim Path):** Immediate settlement by the merchant upon revealing the 32-byte preimage $R$ such that $\text{SHA256}(R) = H$.
2. **`OP_ELSE` (Relative Timelock Timeout Path):** Trustless sender refund after `10` blocks enforced via `OP_CHECKSEQUENCEVERIFY` (BIP68 / BIP112).

---

## 1. Upstream C++ Script & Consensus References

### `OP_CHECKSEQUENCEVERIFY` Enforcement (`src/script/interpreter.cpp`)
```cpp
case OP_CHECKSEQUENCEVERIFY:
{
    if (stack.size() < 1)
        return set_error(serror, SCRIPT_ERR_INVALID_STACK_OPERATION);

    const CScriptNum nSequence(stacktop(-1), fRequireMinimal, 5);
    if (nSequence < 0)
        return set_error(serror, SCRIPT_ERR_NEGATIVE_LOCKTIME);

    if ((nSequence.getint() & CTxIn::SEQUENCE_LOCKTIME_DISABLE_FLAG) != 0)
        break;

    if (!checker.CheckSequence(nSequence))
        return set_error(serror, SCRIPT_ERR_UNSATISFIED_LOCKTIME);

    break;
}
```

### BIP68 Mempool & Block Finality (`src/consensus/tx_verify.cpp`)
In `SequenceLocks` / `CalculateSequenceLocks`:
- If a transaction input sets `nSequence = 10` (relative block locktime of 10 confirmations) and the spent UTXO has fewer than 10 confirmations, mempool acceptance rejects the transaction with **`non-BIP68-final`**.

---

## 2. HTLC Witness Script & Cryptographic Parameters

- **Secret Preimage ($R$):** `"kisumu_lightning_htlc_secret_001"`
  - Hex: `6b6973756d755f6c696768746e696e675f68746c635f7365637265745f303031`
- **Payment Hash ($H = \text{SHA256}(R)$):**
  - Hex: `742af20ce270fb0e8ae2c5be398a44554cbddcb1bd005ea7bbadef3c522e7afa`
- **HTLC Witness Script ASM:**
  ```text
  OP_IF
      OP_SHA256 742af20ce270fb0e8ae2c5be398a44554cbddcb1bd005ea7bbadef3c522e7afa OP_EQUALVERIFY
      020d48049735e22172d677161edb6b5ef3ddf39d82949f011f22260250165fe507 OP_CHECKSIG
  OP_ELSE
      10 OP_CHECKSEQUENCEVERIFY OP_DROP
      022d7d6adbdca821933ac3b0a6baedeb9492a1f822dcfde032c580831c185b637d OP_CHECKSIG
  OP_ENDIF
  ```
- **HTLC Witness Script (Hex):**
  `63a820742af20ce270fb0e8ae2c5be398a44554cbddcb1bd005ea7bbadef3c522e7afa8821020d48049735e22172d677161edb6b5ef3ddf39d82949f011f22260250165fe507ac675ab27521022d7d6adbdca821933ac3b0a6baedeb9492a1f822dcfde032c580831c185b637dac68`
- **P2WSH Address (`bcrt1q...`):**
  `bcrt1q00umt9mrdel5ufvwnnh7my5y4pmkgufnzdm4vvdupetrk0pna8jql56sqa`
- **Funding Transaction (`FUND_TXID`):**
  `3841d4d9048bbf8820e42644382786cae1bfc8dc829538536c57c1ab584e6f7a` (funds two `1.00000000 BTC` HTLC outputs at `vout: 0` and `vout: 1`)

---

## 3. Empirical Branch Verification on Regtest

### Branch A: Merchant Preimage Claim (`vout: 0`, `OP_IF`)
Witness stack structure:
```text
[ <merchant_ecdsa_sig>, <32_byte_preimage_R>, 0x01, <htlc_witness_script> ]
```
1. **Test A1 — Invalid Preimage Rejection:**
   Supplying a wrong 32-byte preimage (`"wrong_secret_preimage_0000000000"`) to `testmempoolaccept`:
   ```text
   allowed=False
   reject-reason='mandatory-script-verify-flag-failed (Script failed an OP_EQUALVERIFY operation)'
   ```
2. **Test A2 — Valid Preimage Settlement:**
   Supplying $R = \text{6b697375...}$ passes `OP_SHA256 ... OP_EQUALVERIFY` and `OP_CHECKSIG` immediately:
   - **Claim TXID:** `9daf1db7d7edb2265cd05e04da88bda59aee92311fe4991d5bb3415b2794909d`

---

### Branch B: Sender CSV Timeout Refund (`vout: 1`, `OP_ELSE`)
Witness stack structure (note empty byte `""` required by SegWit `MINIMALIF` consensus rule to enter `OP_ELSE`):
```text
[ <sender_ecdsa_sig>, "", <htlc_witness_script> ]
```
1. **Test B1 — Premature Refund Attempt (1 Confirmation < 10 Blocks):**
   Attempting to spend `vout: 1` with `nSequence = 10` when `FUND_TXID` has only 1 confirmation:
   ```text
   allowed=False
   reject-reason='non-BIP68-final'
   ```
2. **Test B2 — Matured Refund After Mining 9 Additional Blocks (10 Confirmations):**
   After mining 9 blocks (`generatetoaddress 9`), the exact same signed refund transaction satisfies `nSpendHeight - coin.nHeight >= 10` and confirms on-chain:
   - **Refund TXID:** `b4172605b5136118168a46673ee8fcde3a8068f92e663acfb987d4c94988b1c8`
