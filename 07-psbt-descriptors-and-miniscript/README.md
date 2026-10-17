# Hour 07: Sovereign Custody Architecture — BIP380 Output Script Descriptors & BIP174 Airgapped PSBT Signing

## Objective
Implement and verify a pure-Bitcoin, zero-fiat sovereign custody and settlement workflow in Go (`07-psbt-descriptors-and-miniscript`) against `bitcoind -regtest`:
1. **BIP380 / BIP84 Output Script Descriptors (`src/script/descriptor.cpp`):** Separate public key derivation (`sovereign_watch_only`, `disable_private_keys: true`) from private key custody (`sovereign_cold_signer`).
2. **BIP174 Partially Signed Bitcoin Transactions (`src/psbt.cpp`):** Construct an unsigned PSBT (`walletcreatefundedpsbt`) on a watch-only coordinator, verify the 5-byte magic header (`0x70736274ff` -> `"psbt\xff"` -> base64 `cHNidP8`), sign across the airgap (`walletprocesspsbt`), finalize the witness stack (`finalizepsbt`), and broadcast (`sendrawtransaction`).
3. **Consensus Monetary Bounds (`src/consensus/amount.h` & `src/policy/policy.cpp`):** Enforce `MAX_MONEY` (`21,000,000 * COIN`) and `GetDustThreshold` (`546 sats`).

---

## 1. Upstream C++ Descriptor & PSBT References

### Descriptor Checksum & Parsing (`src/script/descriptor.cpp`)
Every Bitcoin Core output descriptor appends an 8-character BCH polymod checksum (`#80pkmwlk`) engineered to detect up to 4 character transposition or substitution errors in extended public keys (`tpub`/`xpub`) and derivation paths.

### BIP174 PSBT Binary Format (`src/psbt.h`)
```cpp
// Magic bytes: "psbt" + 0xff separator
static constexpr uint8_t PSBT_MAGIC_BYTES[5] = {'p', 's', 'b', 't', 0xff};
```
A PSBT consists of:
- **Global Map:** Unsigned `CTransaction` (`PSBT_GLOBAL_UNSIGNED_TX = 0x00`, where all `scriptSig` and `scriptWitness` fields must be empty).
- **Per-Input Maps:** `PSBT_IN_WITNESS_UTXO` (`0x01`, holding the spent `CTxOut` amount + `scriptPubKey` so hardware signers can verify the exact input fee without trusting the host), `PSBT_IN_BIP32_DERIVATION` (`0x06`), and `PSBT_IN_PARTIAL_SIG` (`0x02`).
- **Per-Output Maps:** `PSBT_OUT_BIP32_DERIVATION` (`0x02`, allowing the cold signer to verify change outputs belong to its own internal descriptor).

---

## 2. Go Unit Tests & Live Regtest Execution

### Run Unit Tests
```bash
go test -v ./...
```
```text
=== RUN   TestValidateBIP174Header
--- PASS: TestValidateBIP174Header (0.00s)
=== RUN   TestValidateSatsOutputConsensusBounds
--- PASS: TestValidateSatsOutputConsensusBounds (0.00s)
PASS
ok  	github.com/altradits/bitcoin-core-lab/07-psbt-descriptors-and-miniscript	0.802s
```

### Run Live Airgapped PSBT Workflow on Regtest
```bash
go run .
```
```text
1. Exported & Imported Public BIP84 Descriptor:
   wpkh([64cbfe93/84h/1h/0h]tpubDDSX2vqfBaaLsemGJz5545sqk2jGoUJevXitzGiBDupKA82wwVioDSmPCtzLYUQYGW8cQGQvbr5wg7RJWbGZzFizMZ2R58ZCE6TqCGUoK7X/0/*)#80pkmwlk
2. Watch-Only Derived Vault Address: bcrt1q9k8m86ek5azkjcnds3snf6jnxutqld420yk5pa
3. Funded Vault UTXO (0.50000000 BTC) in TXID: f954e8875f74516467438c6d7c3863a1a4b733f842bbf06357c9dd3f272d09c2
4. Watch-Only Created Unsigned BIP174 PSBT (395 bytes, Fee=0.00000141 BTC):
   Prefix: cHNidP8BAHECAAAAAcIJLSc/3clXY/C7Qvgzt6ShYzh8bYxD...
5. Cold Signer Processed PSBT (Complete=true)
6. Finalized & Broadcasted Sovereign Settlement TXID: f17f2f61095da25e9081a073f08c072e1395203091449fd64e355c03ef11fb73
```
