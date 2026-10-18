# 🗓️ 30-Day Offline Bitcoin Core & Lightning Mastery Curriculum

Every challenge below uses **100% local files on this laptop** (`/Users/mac/bitcoin`, `/Users/mac/bitcoin-references/bips`, `/Users/mac/bitcoin-references/bolts`, and `/Users/mac/bitcoin-core-lab`).

### Offline Daily Workflow
1. Pick the next uncompleted day below.
2. Read the local BIP/BOLT (`./lab.sh bip <num>` or `./lab.sh bolt <num>`) and C++ source files in `/Users/mac/bitcoin/src/`.
3. Execute the test or generate an offline PR review (`./lab.sh pr-review <PR_NUM>`).
4. Commit your work **offline** (`./lab.sh commit-offline "docs(day-XX): ..."`).
5. When internet returns, run `./lab.sh sync` to push all queued offline commits to GitHub!

---

## Week 1: Consensus Foundations, Mempool Policy & Sovereign Custody (Days 01–08)

- [x] **Day 01:** Coinbase Maturity (`COINBASE_MATURITY = 100`) & Regtest Halvings (`./lab.sh practice 01`)
- [x] **Day 02:** Raw Transaction Serialization, `-maxtxfee` Guardrail & SegWit Weight (`./lab.sh practice 02`)
- [x] **Day 03:** BIP125 Replace-By-Fee (`PaysForRBF` Rule #4) & CPFP Package Feerates (`./lab.sh practice 03`)
- [x] **Day 04:** Two-Node P2P Functional Test with `BitcoinTestFramework` & `MiniWallet` (`./lab.sh practice 04`)
- [x] **Day 05:** BIP431 TRUC (`version=3`) & 1P1C Zero-Fee Parent Package Relay (`./lab.sh practice 05`)
- [x] **Day 06:** Lightning P2WSH HTLC (`OP_SHA256` Preimage vs `OP_CHECKSEQUENCEVERIFY` Timeout) (`./lab.sh practice 06`)
- [x] **Day 07:** BIP380 Watch-Only Descriptors & BIP174 Airgapped PSBT Coordinator (`./lab.sh practice 07`)
- [x] **Day 08:** Sovereign Bitcoin Builder Starter Kit (Go HTTP + `OP_RETURN` Notarization) (`./lab.sh practice 08`)

---

## Week 2: Upstream PR Reviews From Local Git History (Days 09–15)

All PRs below are **already stored inside `/Users/mac/bitcoin`'s local git object database**. Run `./lab.sh pr-review <PR_NUMBER>` offline to scaffold your review file in `pr-reviews/PR-<NUMBER>.md`:

- [x] **Day 09 — PR #32800 (`rpc: Distinguish between vsize and sigop adjusted mempool vsize`):**
  - Run: `./lab.sh pr-review 32800`
  - Inspect how `CTxMemPoolEntry::GetTxSize()` adjusts virtual size by `nSigOpCost * bytes_per_sigop` and run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py mempool_sigoplimit.py`.
- [ ] **Day 10 — PR #34628 (`p2p: Replace per-peer transaction rate-limiting with global rate limits`):**
  - Run: `./lab.sh pr-review 34628`
  - Study `src/net_processing.cpp` to understand how Bitcoin Core schedules `inv` trickling across inbound and outbound peers.
- [ ] **Day 11 — PR #28463 (`p2p: Increase inbound capacity for block-relay only connections`):**
  - Run: `./lab.sh pr-review 28463`
  - Study eclipse-attack resistance via block-relay-only (`block-relay-only`) peers in `src/net.cpp` and `src/net_processing.cpp`.
- [ ] **Day 12 — PR #35320 (`key: validate BIP32 seed length in CExtKey::SetSeed`):**
  - Run: `./lab.sh pr-review 35320` and `./lab.sh bip 32`
  - Verify `CExtKey::SetSeed` bounds (128 to 512 bits) in `src/key.cpp`.
- [ ] **Day 13 — PR #35664 (`test: add CLTV and CHECK(MULTI)SIGVERIFY failure-path vectors to script_tests.json`):**
  - Run: `./lab.sh pr-review 35664` and `./lab.sh bip 65`
  - Inspect `src/test/data/script_tests.json` and run `ctest --test-dir /Users/mac/bitcoin/build -R script_tests`.
- [ ] **Day 14 — PR #33014 (`rpc: Fix internal bug in descriptorprocesspsbt when encountering invalid signatures`):**
  - Run: `./lab.sh pr-review 33014` and `./lab.sh bip 174`
  - Run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py rpc_psbt.py`.
- [ ] **Day 15 — PR #35694 (`clusterlin: minor SFL optimizations`):**
  - Run: `./lab.sh pr-review 35694`
  - Study Spanning Forest Linearization (SFL) for Cluster Mempool in `src/cluster_linearize.h`.

---

## Week 3: Taproot, Schnorr (BIP340/341/342) & Miniscript (Days 16–22)

- [ ] **Day 16 — BIP340 Schnorr Signatures & Batch Verification:**
  - Read `./lab.sh bip 340` and inspect `/Users/mac/bitcoin/src/secp256k1/src/modules/schnorrsig/main_impl.h`.
  - Explain why 64-byte Schnorr signatures $(R, s)$ satisfy linearity ($s_1 + s_2$) whereas DER-encoded ECDSA signatures do not.
- [ ] **Day 17 — BIP341 Taproot Key-Path vs Script-Path Spends (`P2TR`):**
  - Read `./lab.sh bip 341` and run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py feature_taproot.py`.
  - Implement **Challenge A** in `08-builder-starter-kit/main.go` (`bech32m` / `bcrt1p...` invoice generation).
- [ ] **Day 18 — BIP342 Tapscript & `OP_CHECKSIGADD`:**
  - Read `./lab.sh bip 342` and inspect `EvalChecksigTapscript` in `/Users/mac/bitcoin/src/script/interpreter.cpp`.
  - Compare legacy `OP_CHECKMULTISIG` ($O(N \times M)$ signature checks) with Tapscript `OP_CHECKSIGADD` ($O(N)$ deterministic checks).
- [ ] **Day 19 — Output Script Descriptors & Miniscript (`BIP380`–`BIP386`):**
  - Read `./lab.sh bip 380` and run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py wallet_miniscript.py`.
- [ ] **Day 20 — Absolute Timelocks (`nLockTime` & `OP_CHECKLOCKTIMEVERIFY` / BIP65):**
  - Read `./lab.sh bip 65` and run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py feature_cltv.py`.
- [ ] **Day 21 — Relative Timelocks (`nSequence` & `OP_CHECKSEQUENCEVERIFY` / BIP68 & BIP112):**
  - Read `./lab.sh bip 68` and `./lab.sh bip 112`, then run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py feature_csv_activation.py`.
- [ ] **Day 22 — Builder Challenge B (`POST /api/bumpfee` RBF Endpoint in Go):**
  - Implement Challenge B in `08-builder-starter-kit/main.go` and commit your test in `main_test.go`.

---

## Week 4: P2P Protocol, Compact Blocks & Lightning BOLTs (Days 23–30)

- [ ] **Day 23 — BIP152 Compact Block Relay (`cmpctblock`, `getblocktxn`, `blocktxn`):**
  - Read `./lab.sh bip 152` and run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py p2p_compactblocks.py`.
- [ ] **Day 24 — BIP324 v2 Encrypted P2P Transport (`ElligatorSwift` + `ChaCha20Poly1305`):**
  - Read `./lab.sh bip 324` and run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py p2p_v2_transport.py`.
- [ ] **Day 25 — Mempool Ephemeral Anchors & Package RBF:**
  - Run `python3 /Users/mac/bitcoin/build/test/functional/test_runner.py mempool_ephemeral_dust.py mempool_package_rbf.py`.
- [ ] **Day 26 — Lightning BOLT #2 Channel Lifecycle (`open_channel`, `funding_created`, `channel_ready`):**
  - Read `./lab.sh bolt 2` and map out the 2-of-2 multisig funding output state machine.
- [ ] **Day 27 — Lightning BOLT #3 Commitment Transactions & Revocation Keys (`to_local`, `to_remote`):**
  - Read `./lab.sh bolt 3` and trace how a leaked `per_commitment_secret` enables a penalty ("Justice") transaction.
- [ ] **Day 28 — Lightning BOLT #4 Sphinx Onion Routing & BOLT #11 Invoices:**
  - Read `./lab.sh bolt 4` and `./lab.sh bolt 11`.
- [ ] **Day 29 — Builder Challenge C (`GET /api/verify` On-Chain `OP_RETURN` Verifier in Go):**
  - Implement Challenge C in `08-builder-starter-kit/main.go` and verify an on-chain document timestamp.
- [ ] **Day 30 — Author a Brand-New Functional Test in `04-functional-test-framework/`:**
  - Write a new two-node P2P test verifying `submitpackage` 1P1C relay across `Node 0` and `Node 1`.
