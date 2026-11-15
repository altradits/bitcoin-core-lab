# 30 Offline Study Days (companion to CURRICULUM.md)

Use this list on days with no internet. It is **not** the main schedule.
[CURRICULUM.md](./CURRICULUM.md) is, and it puts public review from week 4 on.
Each day should take 2–4 hours and needs only local files:

- the Bitcoin Core source (`~/bitcoin`; use `git show master:<path>` for files that exist only on master)
- BIPs and BOLTs in `~/bitcoin-references/` (read them with `./lab.sh bip <n>` / `./lab.sh bolt <n>`)
- this repo

**Daily loop.** Pick the next unchecked day. Read the material. Do the task, typing every
command yourself and logging it in `my-work/<stage>/journal.md`. Answer the check
question from memory. Commit your notes with `git` yourself. Push when you are back online.
`[x]` marks days you have already completed.

The tests named below are upstream functional or unit tests. You learned in Stages 04 and 13
how to run a single one from your build directory. If you can't remember, that is the
lesson for the day: work it out from `test/functional/README.md` / `ctest --help`.

---

## Week 1: Foundations (Stages 00–08 offline practice)
- [x] **Day 01:** Coinbase maturity and regtest halvings (Stage 01). *Check:* which reject reason does spending a coinbase at depth 99 give, and where is it raised?
- [x] **Day 02:** Raw tx serialization, fee guardrails, weight (Stage 02). *Check:* compute weight/vsize for a tx by hand from `decoderawtransaction` sizes.
- [x] **Day 03:** RBF and CPFP (Stage 03). *Check:* which rule stops a 1-sat replacement spam, and in which function?
- [x] **Day 04:** Two-node functional test (Stage 04). *Check:* why do multi-node tests need `sync_mempools`?
- [x] **Day 05:** TRUC and 1P1C packages (Stage 05). *Check:* what are the TRUC child's size limit and its constant name in `src/policy/truc_policy.h`?
- [x] **Day 06:** P2WSH HTLC (Stage 06). *Check:* what does a premature CSV spend return?
- [x] **Day 07:** Descriptors and PSBT (Stage 07). *Check:* name the BIP174 roles and the RPC for each.
- [x] **Day 08:** Builder kit (Stage 08). *Check:* why does the server only hold a watch-only wallet?

## Week 2: Merged PRs from local git history (Stage 09/19 skills)
For each PR, find its merge commit in `master` (hint: merge commit subjects start with `Merge bitcoin/bitcoin#<N>:`), list the author's commits, read the diff, and run the tests it touched. Write 5 lines in `my-work/reviews/` on what invariant it protects. The existing audits in [`pr-reviews/`](./pr-reviews/) are for comparing *after* you write yours.
- [x] **Day 09:** #32800 sigop-adjusted vsize. Tests: `mempool_sigoplimit.py`.
- [ ] **Day 10:** #34628 global tx relay rate limits. Area: `src/net_processing.cpp`.
- [ ] **Day 11:** #28463 block-relay-only inbound capacity. Area: `src/net.cpp`.
- [ ] **Day 12:** #35320 BIP32 seed length. Area: `CExtKey::SetSeed` in `src/key.cpp`; read BIP32.
- [ ] **Day 13:** #35664 script test vectors. Area: `src/test/data/script_tests.json`; run the `script_tests` unit suite.
- [ ] **Day 14:** #33014 `descriptorprocesspsbt` invalid signatures. Test: `rpc_psbt.py`.
- [ ] **Day 15:** #35694 clusterlin SFL optimizations. Area: `src/cluster_linearize.h` (read it on master).

(All seven were checked as merged in local `master` at `e75b76b12c`.)

## Week 3: Taproot, Schnorr, timelocks, miniscript (Stage 16 preview)
- [ ] **Day 16:** BIP340. Read `src/secp256k1/src/modules/schnorrsig/main_impl.h`. *Check:* why does Schnorr allow key/signature aggregation (MuSig2, BIP327) when ECDSA does not?
- [ ] **Day 17:** BIP341 key path vs script path. Test: `feature_taproot.py`. Optional: Stage 08 Challenge A (bech32m invoices).
- [ ] **Day 18:** BIP342 and `OP_CHECKSIGADD`. Find the tapscript checksig path in `src/script/interpreter.cpp`. *Check:* why can't tapscript use `OP_CHECKMULTISIG`?
- [ ] **Day 19:** Descriptors and miniscript (BIP380–386). Test: `wallet_miniscript.py`.
- [ ] **Day 20:** CLTV (BIP65). Test: `feature_cltv.py`.
- [ ] **Day 21:** BIP68/112 CSV. Test: `feature_csv_activation.py`.
- [ ] **Day 22:** Stage 08 Challenge B (RBF bump endpoint), with a test you write first.

## Week 4: P2P, packages, Lightning (Stages 14, 18, 12 preview)
- [ ] **Day 23:** BIP152 compact blocks. Test: `p2p_compactblocks.py`. Area: `src/blockencodings.cpp`.
- [ ] **Day 24:** BIP324 v2 transport. Test: `p2p_v2_transport.py`. Area: `src/bip324.cpp`.
- [ ] **Day 25:** Ephemeral dust and package RBF. Tests: `mempool_ephemeral_dust.py`, `mempool_package_rbf.py`.
- [ ] **Day 26:** BOLT 2 channel lifecycle. Draw the open → `channel_ready` state machine from memory.
- [ ] **Day 27:** BOLT 3 commitments and revocation. *Check:* what lets the victim sweep `to_local` after a revoked broadcast?
- [ ] **Day 28:** BOLT 4 onion routing and BOLT 11 invoices.
- [ ] **Day 29:** Stage 08 Challenge C (`OP_RETURN` verifier).
- [ ] **Day 30:** Write a new two-node functional test of 1P1C `submitpackage` relay in `my-work/04-functional-test-framework/`.
