# Stage 08: Sovereign Bitcoin Builder Starter Kit (Zero-Dependency Go HTTP + JSON-RPC Engine)

## Objective
Transition from protocol verification to **building real, non-custodial Bitcoin applications** directly on top of `bitcoind` JSON-RPC using pure Go standard library (`net/http`, `crypto/sha256`, `encoding/json`) with zero external dependencies and zero fiat rails.

---

## 1. Architecture & Endpoints

| Endpoint | Method | Protocol Feature | Bitcoin Core RPCs Used |
| :--- | :---: | :--- | :--- |
| `/api/node` | `GET` | Real-time chain tip, difficulty, height & mempool telemetry | `getblockchaininfo`, `getmempoolinfo` |
| `/api/invoice` | `POST` | Derives a fresh Bech32 address from the **Watch-Only BIP84 Descriptor Wallet** (`disable_private_keys: true`) and returns a BIP21 URI | `getnewaddress` (`sovereign_watch_only`) |
| `/api/notarize` | `POST` | Hashes any document with SHA-256 and anchors an unspendable `OP_RETURN` (`6a20<32-byte-hash>`) commitment on-chain via BIP174 PSBT | `walletcreatefundedpsbt`, `walletprocesspsbt`, `finalizepsbt`, `sendrawtransaction` |

---

## 2. Quickstart: Run Tests, Demo & Live HTTP Server

### Run Unit Tests
```bash
go test -v ./...
```

### Run CLI Demo Against `bitcoind -regtest`
```bash
go run . --demo
```

### Start the Live HTTP Server (`127.0.0.1:8080`)
```bash
go run .
```

In a second terminal, test the live endpoints:

```bash
# 1. Inspect node & mempool state
curl -s http://127.0.0.1:8080/api/node | python3 -m json.tool

# 2. Generate a watch-only 50,000-satoshi BIP21 invoice
curl -s -X POST http://127.0.0.1:8080/api/invoice \
  -d '{"amount_sats": 50000, "label": "BitDevs Kisumu Socratic Seminar"}' | python3 -m json.tool

# 3. Anchor a SHA-256 document timestamp on-chain via OP_RETURN
curl -s -X POST http://127.0.0.1:8080/api/notarize \
  -d '{"document_text": "BitDevs Kisumu Consensus Proof #001"}' | python3 -m json.tool
```

---

## 3. Hands-On Builder Challenges (Extend This Code!)

Use `main.go` and `main_test.go` as your launchpad to build three new protocol features:

1. **Challenge A — Taproot (`P2TR` / BIP86) Invoice Support:**
   - Update `POST /api/invoice` to accept an optional `"address_type": "bech32m"` parameter so `getnewaddress` derives a Witness v1 Taproot (`bcrt1p...`) output (`OP_1 <32-byte x-only pubkey>`).
   - Lower `DustLimitSats` from `546` to `330` sats for `bech32m` outputs (`GetDustThreshold` in `src/policy/policy.cpp`).
2. **Challenge B — Mempool Fee-Bump Endpoint (`POST /api/bumpfee`):**
   - Add an endpoint that calls `bumpfee <txid> '{"fee_rate": 25}'` on an unconfirmed BIP125-replaceable transaction and returns both the evicted `origtxid` and the new replacement `txid`.
3. **Challenge C — `OP_RETURN` Proof Verifier (`GET /api/verify?txid=<txid>&text=<text>`):**
   - Fetch the raw transaction via `getrawtransaction <txid> true`, locate the `vout` where `scriptPubKey.type == "nulldata"`, and verify that `scriptPubKey.hex == "6a20" + sha256(text)`.
