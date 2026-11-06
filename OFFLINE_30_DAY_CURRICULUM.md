# 30 day offline study plan for Bitcoin Core and Lightning

Every challenge below uses local files only: your Bitcoin Core
checkout (`$BITCOIN_ROOT`, default `~/bitcoin`), your reference
library (`$BITCOIN_REFERENCES`, default `~/bitcoin-references`), and
this lab repo. No internet needed after setup.

### Offline daily workflow

1. Pick the next uncompleted day below.
2. Read the local BIP or BOLT (`./lab.sh bip <num>`, `./lab.sh bolt
   <num>`) and the C++ sources under `$BITCOIN_ROOT/src/`.
3. Run the test, or draft a review (`./lab.sh pr-review <PR_NUM>`).
4. Commit offline (`./lab.sh commit-offline "docs(day-XX): ..."`).
5. When internet returns, `./lab.sh sync` pushes the queued commits.

## Week 1: Stages 00 to 08 (Days 01-08)

One stage per day, in order. Each day ends with that stage's
Checkpoint.

- [ ] **Day 01:** Stage 00 (first block, coins, send).
- [ ] **Day 02:** Stage 01 (coinbase maturity, halvings).
- [ ] **Day 03:** Stage 02 (raw transactions, fees, weight).
- [ ] **Day 04:** Stage 03 (RBF, CPFP) plus Stage 04 (functional
  tests).
- [ ] **Day 05:** Stage 05 (TRUC, packages).
- [ ] **Day 06:** Stage 06 (HTLC contracts).
- [ ] **Day 07:** Stage 07 (descriptors, PSBT).
- [ ] **Day 08:** Stage 08 (builder app).

## Week 2: Upstream PR reviews from local history (Days 09-15)

All PRs below sit in your checkout's git history. Run
`./lab.sh pr-review <PR_NUMBER>` to scaffold a draft review.

Warning: the generator writes `pr-reviews/PR-<NUMBER>-AUDIT.md` and
overwrites without asking. The numbers below already have curated
audits in this repo. Back yours up first, or pick a different PR
number and compare your draft against the curated one after.

- [ ] **Day 09:** PR #32800 (sigop adjusted vsize). Read the curated
  audit, then run `mempool_sigoplimit.py`:

  ```bash
  python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" mempool_sigoplimit.py
  ```

- [ ] **Day 10:** PR #34628 (global tx rate limits). Study `inv`
  trickling in `src/net_processing.cpp`.
- [ ] **Day 11:** PR #28463 (block relay only capacity). Study
  eclipse resistance in `src/net.cpp` and `src/net_processing.cpp`.
- [ ] **Day 12:** PR #35320 (BIP32 seed bounds). Run `./lab.sh bip
  32`, verify the `Assert` in `CExtKey::SetSeed` (`src/key.cpp`).
- [ ] **Day 13:** PR #35664 (script test vectors). Inspect
  `src/test/data/script_tests.json`, then run:

  ```bash
  "$BITCOIN_ROOT/build/bin/test_bitcoin" --run_test=script_tests
  ```

- [ ] **Day 14:** PR #33014 (PSBT signature handling). Run
  `./lab.sh bip 174`, then:

  ```bash
  python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" rpc_psbt.py
  ```

- [ ] **Day 15:** PR #35694 (cluster linearization). Study
  `src/cluster_linearize.h`.

## Week 3: Taproot, timelocks, miniscript (Days 16-22)

- [ ] **Day 16:** BIP340 Schnorr. Read `./lab.sh bip 340`, inspect
  `src/secp256k1/src/modules/schnorrsig/main_impl.h`. Explain why
  64 byte Schnorr signatures add linearly but DER ECDSA does not.
- [ ] **Day 17:** BIP341 Taproot. Read `./lab.sh bip 341`, then run:

  ```bash
  python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" feature_taproot.py
  ```

  Then do Stage 08 Going further 1 (Taproot invoices).
- [ ] **Day 18:** BIP342 Tapscript. Read `./lab.sh bip 342`,
  inspect `EvalChecksigTapscript` in
  `src/script/interpreter.cpp`. Compare `OP_CHECKMULTISIG` with
  `OP_CHECKSIGADD`.
- [ ] **Day 19:** Descriptors and miniscript. Read `./lab.sh bip
  380`, then run:

  ```bash
  python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" wallet_miniscript.py
  ```

- [ ] **Day 20:** Absolute timelocks. Read `./lab.sh bip 65`, then
  run `feature_cltv.py` with the same runner pattern.
- [ ] **Day 21:** Relative timelocks. Read `./lab.sh bip 68` and
  `./lab.sh bip 112`, then run `feature_csv_activation.py`.
- [ ] **Day 22:** Builder challenge. Do Stage 08 Going further 2
  (fee bump endpoint) with a test in `main_test.go`.

## Week 4: P2P, packages, Lightning (Days 23-30)

Run each test with the runner pattern from Week 2
(`python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" <name>`).

- [ ] **Day 23:** BIP152 compact blocks. Read `./lab.sh bip 152`,
  run `p2p_compactblocks.py`.
- [ ] **Day 24:** BIP324 encrypted transport. Read `./lab.sh bip
  324`, run `p2p_v2_transport.py`.
- [ ] **Day 25:** Package relay edge cases. Run
  `mempool_ephemeral_dust.py` and `mempool_package_rbf.py`.
- [ ] **Day 26:** BOLT 2 channel lifecycle. Read `./lab.sh bolt 2`,
  map the funding output states.
- [ ] **Day 27:** BOLT 3 commitments. Read `./lab.sh bolt 3`,
  trace how a leaked secret enables justice.
- [ ] **Day 28:** BOLT 4 routing and BOLT 11 invoices. Read
  `./lab.sh bolt 4` and `./lab.sh bolt 11`.
- [ ] **Day 29:** Builder challenge. Do Stage 08 Going further 3
  (notarize size cap) and verify a timestamp on chain.
- [ ] **Day 30:** Write a new two node test in
  `04-functional-test-framework/` that relays a 1 parent 1 child
  package across both nodes.
