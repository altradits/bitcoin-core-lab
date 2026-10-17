# Hour 07: Kisumu Circular Economy — Go Point-of-Sale & Idempotent M-Pesa Daraja -> Bitcoin Core Settlement Bridge

## Objective
Implement and verify a Go service (`07-kisumu-pos-bridge`) that bridges Safaricom M-Pesa Express (STK Push) callbacks with a local Bitcoin Core v29.0 `regtest` node over JSON-RPC:
1. **KES -> Satoshi Precision & P2WPKH Dust Guardrail (`>= 546 sats`):** Converts Kenyan Shilling invoices to integer satoshis and rejects outputs below Bitcoin Core's `GetDustThreshold` (`546 sats` for `P2WPKH` at `3,000 sat/kvB` `dustRelayFee`).
2. **BIP21 Unified Payment URI Generation:** Produces standards-compliant `bitcoin:<bech32>?amount=...&label=...&message=...` URIs.
3. **Cryptographic Webhook Idempotency:** Computes a deterministic SHA-256 idempotency digest over `CheckoutRequestID:MpesaReceiptNumber:AmountKES` and serializes settlement under a mutex so duplicate Safaricom Daraja webhook retries never double-spend or double-pay satoshis.

---

## 1. Upstream Bitcoin Core Dust Threshold Reference (`src/policy/policy.cpp`)

In `GetDustThreshold` (`src/policy/policy.cpp`), an output is considered non-standard dust if the fee required to spend it exceeds its value at `DUST_RELAY_TX_FEE` (`3,000 sat/kvB`):
- A SegWit v0 `P2WPKH` output (`31 bytes`) + spending input (`67.75 vB`, rounded to `68 vB`) totals **`98 vB`** (`98 * 3 = 294 sats` for SegWit or `546 sats` conservative legacy threshold). Our bridge enforces `sats >= 546` before constructing or broadcasting any on-chain payout.

---

## 2. Unit Tests & Live Regtest Execution

### Run Go Unit Tests
```bash
go test -v ./...
```
```text
=== RUN   TestKESToSatsAndDustGuardrail
--- PASS: TestKESToSatsAndDustGuardrail (0.00s)
=== RUN   TestDarajaWebhookIdempotency
--- PASS: TestDarajaWebhookIdempotency (0.00s)
PASS
ok  	github.com/altradits/bitcoin-core-lab/07-kisumu-pos-bridge	0.740s
```

### Live Settlement Against `bitcoind -regtest`
```bash
go run .
```
```text
=== First Daraja Webhook Delivery (Replayed=false) ===
{
  "checkout_request_id": "ws_CO_17102026210500_KSM001",
  "mpesa_receipt": "QJH8KSM901",
  "amount_kes": 1150,
  "amount_sats": 10000,
  "amount_btc": "0.00010000",
  "recipient_address": "bcrt1qdc7ytjym9gynaa9pcwgwe7afwdftmy7kt96x4w",
  "bip21_uri": "bitcoin:bcrt1qdc7ytjym9gynaa9pcwgwe7afwdftmy7kt96x4w?amount=0.00010000&label=Kisumu+POS&message=M-Pesa+QJH8KSM901",
  "txid": "99574d176c859c6b6b4a0984d36301f0111a06db695e2c0810034fd9a44b650f",
  "idempotency_hash": "ac612b3ee1230b7c00644fcbf3c153f5621c31cf69fd2b1351daabe2c1c98e1a"
}
=== Duplicate Daraja Webhook Retry (Replayed=true, Same TxID=true) ===
```
