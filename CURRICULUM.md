# CURRICULUM.md — The Single Source of Truth

This file defines **what you must be able to do** (competencies), **where you learn it**
(stages 00–19), **when** (a part-time weekly schedule), and **how you prove it**
(three mastery gates). Every stage README tags its objectives with the IDs below.
Rules for how exercises are written live in [CURRICULUM_CONVENTIONS.md](./CURRICULUM_CONVENTIONS.md).
Your evidence goes in [BTRUST_READINESS_TRACKER.md](./BTRUST_READINESS_TRACKER.md).

- Upstream checked: `~/bitcoin`, branch `master` at `e75b76b12c` (2026-07-26).
  The working tree there is detached at `f490f5562d` (29.x). Several things below
  (`doc/AI_POLICY.md`, `src/txgraph.h`) exist **only on master**. Review against master,
  not the 29.x checkout.
- Btrust requirements: verified 2026-11-09. Sources are in
  [BTRUST_AND_BITDEVS_PLAYBOOK.md](./BTRUST_AND_BITDEVS_PLAYBOOK.md#sources-checked-date-2026-11-09).

---

## 1. Competency map

Each line reads: **ID: name.** What you can do. *(stages that teach it)*

### Git & GitHub workflow (`C-GIT`)
- **C-GIT-1: Repo hygiene.** Clone, fork, set `origin`/`upstream` remotes, keep `master` clean, work on topic branches. *(00, 13)*
- **C-GIT-2: Check out a PR.** Fetch any PR by number, diff it against its merge-base, and list its commits. *(09, 13, 19)*
- **C-GIT-3: Shape history.** Use interactive rebase, `fixup!` commits and `--autosquash` to keep each commit atomic and buildable. *(19)*
- **C-GIT-4: Range-diff.** Re-review a force-pushed PR with `git range-diff` and say exactly what changed. *(19)*
- **C-GIT-5: Bisect.** Find the commit that introduced a regression with `git bisect` (manual and `run`). *(17)*
- **C-GIT-6: Code archaeology.** Use `git log -S/-G`, `git blame` and merge-commit messages to find why code exists. *(09, 13)*
- **C-GIT-7: Signing.** Sign your commits (GPG or SSH) and verify signatures on merge commits. *(19)*

### Build system (`C-BUILD`)
- **C-BUILD-1: Configure.** Install macOS dependencies and configure Core with CMake, choosing options (wallet, tests, fuzz, sanitizers). *(13)*
- **C-BUILD-2: Build on 8 GB.** Build only the targets you need with a parallelism that does not swap the M1, using ccache. *(13)*
- **C-BUILD-3: Build files.** Add a source or test file to the right `CMakeLists.txt` and explain the library layout (`bitcoin_node`, `bitcoin_common`, …). *(13)*
- **C-BUILD-4: Reproducible builds.** Explain what `depends/` and Guix are for and when a reviewer needs them. *(13, 17)*

### C++ in Bitcoin Core (`C-CPP`)
- **C-CPP-1: Modern C++.** Read and write RAII types, `std::unique_ptr`/`shared_ptr`, move semantics, `std::optional`. *(13)*
- **C-CPP-2: Locking.** Use `Mutex`, `LOCK`, `WITH_LOCK`, `AssertLockHeld`, and the clang thread-safety annotations (`EXCLUSIVE_LOCKS_REQUIRED`, `GUARDED_BY`); spot lock-order bugs. *(14, 15)*
- **C-CPP-3: Span & serialization.** Use `std::span`/`Span` (`src/span.h`) and the serialization framework (`src/serialize.h`, `SERIALIZE_METHODS`). *(13, 14)*
- **C-CPP-4: Error paths.** Use `util::Result`, `BlockValidationState`/`TxValidationState`, and know when Core asserts and when it returns an error. *(15)*
- **C-CPP-5: House style.** Apply `doc/developer-notes.md` (naming, `clang-format`, safety rules) in your own code and reviews. *(13, 19)*

### Python functional tests (`C-PY`)
- **C-PY-1: Framework anatomy.** Explain `BitcoinTestFramework` (`set_test_params`, `run_test`, node startup and teardown). *(04)*
- **C-PY-2: Test tools.** Use `MiniWallet`, `P2PInterface`, `sync_mempools`/`sync_blocks`, and `assert_*` helpers. *(04, 14)*
- **C-PY-3: Write a test.** Write a new functional test, register it in `test_runner.py`, and make it deterministic. *(04, 19)*

### Unit tests (`C-TEST`)
- **C-TEST-1: Run.** Run `test_bitcoin` suites and single cases, and run `ctest` filters. *(13)*
- **C-TEST-2: Write.** Write a Boost unit test using the right fixture (`BasicTestingSetup`, `TestChain100Setup`, …). *(13)*
- **C-TEST-3: Mutation testing.** Prove a test catches the bug: break the code, watch the test fail, then restore it. *(09, 19)*
- **C-TEST-4: Benchmarks.** Run `bench_bitcoin` before and after a performance PR, and report the numbers honestly. *(17)*

### Fuzzing (`C-FUZZ`)
- **C-FUZZ-1: Build & run.** Build fuzz targets (a libFuzzer-capable LLVM is needed, not Apple clang) and run one target. *(17)*
- **C-FUZZ-2: Write a harness.** Write a fuzz target with `FuzzedDataProvider`. *(17)*
- **C-FUZZ-3: Corpus & crashes.** Use the `qa-assets` corpus and reproduce or minimise a crash input. *(17)*

### Debugging, sanitizers & CI (`C-DEBUG`)
- **C-DEBUG-1: Debuggers & logs.** Debug `bitcoind`/`test_bitcoin` with `lldb`, and use `-debug=<category>` logging. *(17)*
- **C-DEBUG-2: Sanitizers.** Build with ASan/UBSan (and TSan where it makes sense) and read their reports. *(17)*
- **C-DEBUG-3: CI & lint.** Read a failing CI log, reproduce it locally, and run the linters in `test/lint/`. *(17, 19)*

### Transactions (`C-TX`)
- **C-TX-1: Serialization.** Decode a transaction by hand: version, inputs, outputs, witness, locktime; txid vs wtxid; weight and vsize. *(02, 10)*
- **C-TX-2: Raw-tx RPCs.** Build, fund, sign and broadcast raw transactions with RPCs only. *(02)*
- **C-TX-3: Timelocks.** Explain and use `nLockTime`, `nSequence`/BIP68, CLTV (BIP65) and CSV (BIP112). *(06, 16)*

### Script, SegWit & Taproot (`C-SCRIPT`)
- **C-SCRIPT-1: Interpreter.** Trace `EvalScript`/`VerifyScript` for the standard templates. *(10, 16)*
- **C-SCRIPT-2: SegWit v0.** P2WPKH/P2WSH spending and BIP143 sighash. *(02, 16)*
- **C-SCRIPT-3: Taproot.** Key path vs script path, control blocks, tapscript, `OP_CHECKSIGADD` (BIP341/342). *(16)*
- **C-SCRIPT-4: Flags & standardness.** Tell consensus script flags apart from policy (standardness) flags. *(16, 18)*

### Cryptography (`C-CRYPTO`)
- **C-CRYPTO-1: Hashing.** SHA256d, tagged hashes, Merkle roots and the CVE-2012-2459 mutation. *(10)*
- **C-CRYPTO-2: Curves.** secp256k1 field and group basics, and ECDSA signing and verification. *(16)*
- **C-CRYPTO-3: Schnorr.** BIP340 Schnorr signatures, x-only keys, and key tweaking. *(16)*
- **C-CRYPTO-4: MuSig2.** BIP327 key aggregation and the nonce-reuse danger, at concept level. *(16)*
- **C-CRYPTO-5: libsecp256k1.** Know the library layout (`src/secp256k1/`), its constant-time rules, and how it is tested. *(16)*

### Consensus & soft-fork history (`C-CONS`)
- **C-CONS-1: Core invariants.** Supply cap, coinbase maturity, `CheckTransaction`/`CheckTxInputs`. *(01, 09)*
- **C-CONS-2: Soft-fork history.** P2SH, BIP66, CLTV/CSV, SegWit, Taproot, and how they were deployed (BIP9, buried deployments, BIP8 debate). *(15, 16)*
- **C-CONS-3: Historic bugs.** CVE-2010-5139, CVE-2018-17144, CVE-2012-2459, and the lessons a reviewer takes from each. *(09, 10)*
- **C-CONS-4: Proof of work.** `nBits`, target, difficulty retarget, and chainwork. *(10, 15)*

### Validation & chainstate (`C-VAL`)
- **C-VAL-1: Block flow.** Trace `ProcessNewBlock` → `CheckBlock` → `AcceptBlock` → `ActivateBestChain` → `ConnectBlock`. *(15)*
- **C-VAL-2: Coins cache.** The `CCoinsView` layers, the UTXO set database, and flushing. *(15)*
- **C-VAL-3: Reorgs.** `DisconnectBlock`, reorg handling, `invalidateblock`/`reconsiderblock`, and what happens to the mempool. *(15)*
- **C-VAL-4: AssumeUTXO.** Snapshot loading, background validation, and two chainstates (`doc/assumeutxo.md`). *(15)*
- **C-VAL-5: Sync.** Headers-first IBD, `assumevalid`, and pruning. *(11, 15)*

### P2P (`C-P2P`)
- **C-P2P-1: Messages.** The version handshake, the message types, and the `net` vs `net_processing` split. *(14)*
- **C-P2P-2: Tx relay.** inv/getdata, orphan handling, and relay rate limits. *(14)*
- **C-P2P-3: Compact blocks.** BIP152 (`src/blockencodings.cpp`). *(14)*
- **C-P2P-4: Addrman & eclipse.** Addrman buckets, connection types (block-relay-only, feelers, anchors), and eclipse resistance. *(14)*
- **C-P2P-5: BIP324.** The v2 encrypted transport (`src/bip324.cpp`). *(14)*
- **C-P2P-6: DoS.** Misbehaviour, discouragement, and bounding memory and CPU per peer. *(14)*

### Mempool & policy (`C-MEMPOOL`)
- **C-MEMPOOL-1: Admission.** `AcceptToMemoryPool` (ATMP) and the policy checks it runs. *(02, 18)*
- **C-MEMPOOL-2: Fee bumping.** RBF rules (`doc/policy/mempool-replacements.md`) and CPFP. *(03, 18)*
- **C-MEMPOOL-3: Packages.** Package relay/1P1C (`doc/policy/packages.md`), TRUC (BIP431), and ephemeral dust/anchors. *(05, 18)*
- **C-MEMPOOL-4: Cluster mempool.** Clusters, linearization (`src/cluster_linearize.h`), `TxGraph` (`src/txgraph.h`, master only), and feerate diagrams. *(18)*
- **C-MEMPOOL-5: Fees & templates.** Fee estimation and block template assembly (`src/node/miner.cpp`). *(03, 18)*

### Wallet (`C-WALLET`)
- **C-WALLET-1: Descriptors.** Descriptor wallets and BIP32/BIP84/BIP86 derivation (BIP380–386). *(07, 11, 18)*
- **C-WALLET-2: Coin selection.** BnB, Knapsack, SRD and CoinGrinder in `src/wallet/coinselection.cpp`, plus waste. *(18)*
- **C-WALLET-3: Miniscript.** Miniscript and policy, with `wallet_miniscript.py` as the reference test. *(07, 18)*
- **C-WALLET-4: Safety.** Backups, encryption, legacy→descriptor migration, and watch-only wallets. *(11, 18)*

### PSBT (`C-PSBT`)
- **C-PSBT-1: BIP174.** The roles (creator, updater, signer, combiner, finalizer, extractor) and the matching RPCs. *(07)*
- **C-PSBT-2: Air-gap & v2.** Air-gapped/external-signer flows (`doc/psbt.md`, `doc/external-signer.md`) and the purpose of PSBTv2 (BIP370). *(07)*

### Lightning (`C-LN`)
- **C-LN-1: BOLT map.** What each BOLT (01–12) covers and how LN depends on Bitcoin Core. *(12)*
- **C-LN-2: HTLCs.** Build and spend HTLC scripts through both the preimage path and the timeout path. *(06)*
- **C-LN-3: Channel state.** Commitment transactions, revocation, penalty, and `to_local`/`to_remote` (BOLT 3). *(06, 12)*
- **C-LN-4: LN meets mempool.** Channel lifecycle, anchors, pinning, and why TRUC/package relay matter to LN. *(05, 12, 18)*
- **C-LN-5: Run LN.** Run LND under Polar with `lncli`, and explain the bitcoind bridge (RPC + ZMQ). *(12)*
- **C-LN-6: Payments.** Onion routing (BOLT 4) and invoices/offers (BOLT 11/12) at concept level. *(12)*

### Review craft (`C-REVIEW`)
- **C-REVIEW-1: Triage.** Classify a PR's risk area and name the invariants it must keep. *(09, 19)*
- **C-REVIEW-2: Concept & approach.** Give a Concept/Approach (N)ACK grounded in the motivation, linked issues and prior discussion. *(05, 19)*
- **C-REVIEW-3: Code review.** Review commit by commit for locking, bounds, behaviour changes and test coverage. *(19)*
- **C-REVIEW-4: Tested ACK.** Give an `ACK <commit>` that says what you tested, including change-specific manual testing (CONTRIBUTING.md "Peer Review"). *(19)*
- **C-REVIEW-5: Follow-up.** Re-review after a force-push with range-diff, and track your comments to resolution. *(19)*
- **C-REVIEW-6: Review Club.** Prepare for and take part in Bitcoin Core PR Review Club (bitcoincore.reviews). *(from week 3, all stages)*

### Contribution craft (`C-CONTRIB`)
- **C-CONTRIB-1: Find work.** Find good work: issues, test-coverage gaps, follow-ups left in reviews. *(19)*
- **C-CONTRIB-2: Atomic commits.** Write atomic commits with prefixed messages (`test:`, `p2p:`, …) and a clear PR description. *(19)*
- **C-CONTRIB-3: Keep a PR alive.** Answer review, rebase, fix CI, and keep the PR moving. *(19)*
- **C-CONTRIB-4: Policy.** Follow `doc/AI_POLICY.md` (master) and the MIT licensing rules: human authorship, explanations in your own words, no AI co-authors on commits. *(19, all)*

### Technical communication (`C-COMMS`)
- **C-COMMS-1: Your own words.** Write precise technical comments in your own words. *(all)*
- **C-COMMS-2: Socratic Seminar.** Curate a reading list and moderate a Socratic Seminar. *(BitDevs Kisumu, ongoing)*
- **C-COMMS-3: Write-ups.** Publish a monthly progress report and short technical write-ups. *(ongoing)*
- **C-COMMS-4: Community etiquette.** Know the conventions for IRC (`#bitcoin-core-dev`), Delving Bitcoin and the mailing list. *(19)*

### Btrust readiness (`C-BTRUST`)
- **C-BTRUST-1: Requirements.** State the verified requirements of the Builders program, Starter Grant and BitDevs sponsorship, and pick a track. *(this file, playbook)*
- **C-BTRUST-2: Evidence.** Keep a public, link-backed proof-of-work log. *(tracker)*
- **C-BTRUST-3: References.** Earn at least two references from mentors or contributors on your chosen project through real collaboration. *(tracker)*
- **C-BTRUST-4: Six-month plan.** Write your own six-month plan. *(tracker)*
- **C-BTRUST-5: BitDevs Kisumu.** Run BitDevs Kisumu within Btrust's sponsorship terms. *(playbook)*

> Stage authors: if you need an ID that is not here, use the prefix and report it.
> The architect adds it here; until then this list is authoritative.

---

## 2. Stage sequence 00 → 19

Hours are for a first, honest pass at 8 GB RAM, including reading and journaling.

| # | Stage | Prerequisites | Est. hours | Competencies delivered |
|---|---|---|---|---|
| 00 | [start-small](./00-start-small/README.md) | none | 4 | C-GIT-1, C-TX-2 (intro) |
| 01 | [node-foundations](./01-node-foundations/README.md) | 00 | 6 | C-CONS-1, C-VAL-5 (intro) |
| 02 | [raw-tx-and-mempool](./02-raw-tx-and-mempool/README.md) | 01 | 10 | C-TX-1, C-TX-2, C-SCRIPT-2, C-MEMPOOL-1 |
| 03 | [rbf-and-cpfp](./03-rbf-and-cpfp/README.md) | 02 | 8 | C-MEMPOOL-2, C-MEMPOOL-5 |
| 04 | [functional-test-framework](./04-functional-test-framework/README.md) | 02, 13 (build) | 12 | C-PY-1, C-PY-2, C-PY-3 |
| 05 | [truc-package-relay-review](./05-truc-package-relay-review/README.md) | 03, 04 | 10 | C-MEMPOOL-3, C-REVIEW-2, C-LN-4 |
| 06 | [lightning-htlc-state-machine](./06-lightning-htlc-state-machine/README.md) | 02 | 8 | C-LN-2, C-LN-3, C-TX-3 |
| 07 | [psbt-descriptors-and-miniscript](./07-psbt-descriptors-and-miniscript/README.md) | 02 | 10 | C-PSBT-1, C-PSBT-2, C-WALLET-1, C-WALLET-3 |
| 08 | [builder-starter-kit](./08-builder-starter-kit/README.md) | 07 | 10 | C-TX-2, C-WALLET-1 (applied) |
| 09 | [bug-dojo-and-pr-mastery](./09-bug-dojo-and-pr-mastery/README.md) | 02, 03, 07 | 12 | C-CONS-1, C-CONS-3, C-TEST-3, C-REVIEW-1, C-GIT-2, C-GIT-6 |
| 10 | [protocol-primitives-from-scratch](./10-protocol-primitives-from-scratch/README.md) | 02 | 14 | C-TX-1, C-CRYPTO-1, C-CONS-3, C-CONS-4, C-SCRIPT-1 |
| 11 | [from-regtest-to-live-mainnet](./11-from-regtest-to-live-mainnet/README.md) | 07 | 6 | C-VAL-5, C-WALLET-4 |
| 12 | [lightning-readiness-and-bitcoind-bridge](./12-lightning-readiness-and-bitcoind-bridge/README.md) | 06 | 12 | C-LN-1, C-LN-3, C-LN-4, C-LN-5, C-LN-6 |
| 13 | [core-codebase-build-and-unit-tests](./13-core-codebase-build-and-unit-tests/README.md) | 00 | 16 | C-GIT-1, C-GIT-2, C-GIT-6, C-BUILD-1..4, C-CPP-1, C-CPP-3, C-CPP-5, C-TEST-1, C-TEST-2 |
| 14 | [p2p-and-net-processing](./14-p2p-and-net-processing/README.md) | 13, 04 | 18 | C-P2P-1..6, C-CPP-2, C-CPP-3, C-PY-2 |
| 15 | [validation-chainstate-and-reorgs](./15-validation-chainstate-and-reorgs/README.md) | 13, 01 | 18 | C-VAL-1..5, C-CPP-2, C-CPP-4, C-CONS-2, C-CONS-4 |
| 16 | [script-taproot-and-libsecp256k1](./16-script-taproot-and-libsecp256k1/README.md) | 10, 13 | 18 | C-SCRIPT-1..4, C-CRYPTO-2..5, C-TX-3, C-CONS-2 |
| 17 | [fuzzing-sanitizers-debugging-and-ci](./17-fuzzing-sanitizers-debugging-and-ci/README.md) | 13 | 16 | C-FUZZ-1..3, C-DEBUG-1..3, C-GIT-5, C-TEST-4, C-BUILD-4 |
| 18 | [cluster-mempool-wallet-and-policy](./18-cluster-mempool-wallet-and-policy/README.md) | 03, 05, 07, 13 | 18 | C-MEMPOOL-1..5, C-WALLET-1..4, C-SCRIPT-4, C-LN-4 |
| 19 | [review-and-contribution-practicum](./19-review-and-contribution-practicum/README.md) | 09, 13; runs alongside everything from week 4 | 40+ (ongoing) | C-REVIEW-1..6, C-CONTRIB-1..4, C-GIT-3, C-GIT-4, C-GIT-7, C-COMMS-1, C-COMMS-4 |

Total for a first pass: about 265 hours, not counting the open-ended practicum.

**Why 13 comes early:** numbering follows when stages were written, not the order you
study them. You need a source build (13) before the functional tests in 04 make sense.
Use the schedule below, not the stage numbers.

---

## 3. Week-by-week schedule (15–20 h/week, part-time)

Public work starts in **week 2** (watching Review Club) and **week 4** (first posted review).
Every week also includes about 1 h of journal upkeep in `my-work/` and a tracker update.

| Week | Study (≈12–15 h) | Public / community (≈3–5 h) |
|---|---|---|
| 1 | 00, 01; start 13 (deps, CMake configure, first build with `-j` sized for 8 GB) | Join `#bitcoin-core-dev` (read only). Read CONTRIBUTING.md, developer-notes, and `doc/AI_POLICY.md` (master). |
| 2 | Finish 13 (run unit tests, write one Boost test locally); 02 | Read the logs of a past PR Review Club meeting, then attend one live (listen). |
| 3 | 04 (functional tests; write your own) | Attend Review Club and answer at least one prepared question. Pick 2 open `test:` PRs to follow. |
| 4 | 03; start 19 (how to review; check out a PR; mutation-test it) | **First public review** on a test-only PR: what you ran and what you checked, in your own words. |
| 5 | 09 (bug dojo) | Review Club. Second review. Run BitDevs Kisumu #1 using a reading list you curated. |
| 6 | 05 (TRUC/packages) | Review Club. Third review. **Gate 1 check.** |
| 7–8 | 17 (fuzzing, sanitizers, lldb, bisect, lint) | 1 review/week. Run a fuzz target from a PR you review. |
| 9–10 | 14 (P2P) | 1–2 reviews/week, at least one p2p PR. Monthly progress report #2. |
| 11–12 | 15 (validation, reorgs, assumeutxo) | Reviews. Find one issue you can reproduce and comment with your reproduction. |
| 13–14 | 10 + 16 (primitives, script, taproot, secp) | Reviews. **Open your first PR** (test coverage or a small bug fix found while reviewing). |
| 15–16 | 18 (cluster mempool, wallet, policy) | Policy/mempool reviews with manual regtest scenarios. |
| 17 | 06, 07 (HTLC, PSBT/descriptors) | Reviews; answer review comments on your own PR; use range-diff. |
| 18–19 | 12 (LN readiness), 11, 08 | Reviews; BitDevs session on an LN/mempool topic. |
| 20 | Consolidation: retake every self-check quiz | **Gate 2 check.** Choose your target project for the grant (see §4). |
| 21–36 | Practicum 19 full-time-equivalent: one focus subsystem and deep review | 2–3 reviews/week. Keep at least 2 of your own PRs open at any time. Monthly reports. BitDevs monthly. Build relationships for references. |
| 37+ | — | **Gate 3 check.** Apply when every Gate 3 box is ticked. |

If a week slips, slip the whole plan. Do not skip the public column. Reviewing is the
skill the whole plan is built around.

---

## 4. Mastery gates

Each criterion is objective. Record the evidence (a link, a file, a date) in
[BTRUST_READINESS_TRACKER.md](./BTRUST_READINESS_TRACKER.md).
Run `./lab.sh progress` to see which criteria your checker passes, quiz scores
(`my-work/quiz-scores.env`) and tracker rows already meet, and which ones only you can judge.

### Gate 1: "I can build and test Core and review a test-only PR" (target: week 6)
- [ ] From an empty directory, you cloned, configured and built `bitcoind`, `bitcoin-cli` and `test_bitcoin` on `master`. Every command is in `my-work/13-*/journal.md`, typed by you.
- [ ] You ran a single unit suite, a single functional test, and the full functional suite with `--jobs` sized for 8 GB.
- [ ] You wrote one new Boost unit test and one new functional test (local; they need not be upstream), and each fails when you break the code under test.
- [ ] You posted at least 1 public review on a `bitcoin/bitcoin` test-only PR that states the commit, what you ran, and what you checked.
- [ ] You attended at least 2 PR Review Club meetings and spoke in at least 1.
- [ ] You scored at least 80% from memory on the self-check quizzes for stages 00–04, 09 and 13.

### Gate 2: "I can review a policy/mempool PR with a tested ACK" (target: week 20)
- [ ] You posted at least 1 tested ACK (or a reasoned NACK or change request) on a mempool/policy/validation PR that includes a change-specific manual regtest test you designed.
- [ ] You have at least 10 public reviews in total, at least 3 of which raised a point the author answered or acted on.
- [ ] You re-reviewed at least 1 PR after a force-push using `git range-diff`, and said what changed.
- [ ] You built and ran at least 1 fuzz target and 1 sanitizer build, and explained the result.
- [ ] You opened at least 1 PR of your own (any outcome) and answered its review comments.
- [ ] You scored at least 80% on the self-check quizzes for stages 05–08 and 10–18.
- [ ] You ran at least 3 BitDevs Kisumu Socratic Seminars, each with a public reading list.

### Gate 3: "Btrust-application-ready" (no fixed week; it depends on merges)
These criteria quote the Btrust **Starter Grant** page as checked on 2026-11-09 (the page showed "Applications closed" that day).
- [ ] You have chosen **one specific Bitcoin open-source project**.
- [ ] You have **at least five merged code-based PRs** on that project that are not docs-only and not labelled "good first issue".
- [ ] You have made **multiple helpful reviews** that "helped to move code that is not their own forward" (links in the tracker).
- [ ] You have **multiple helpful responses on issues and discussions**, plus community participation such as BitDevs.
- [ ] You have **a clear six-month plan**, written by you.
- [ ] You are **willing to commit full-time** for the six months.
- [ ] You have **positive reviews from at least two mentors or contributors on the project**.
- [ ] You have not yet applied: Gate 3 marks the point where you apply. Before applying, re-read the live page; the criteria may have changed.

Five merged non-trivial PRs in `bitcoin/bitcoin` can take a long time. Choosing a
project with a faster review cycle (for example BDK, LDK, rust-bitcoin or
libsecp256k1) is a legitimate choice. Make it at Gate 2 and record why.
The **Btrust Builders** program has different, lighter entry criteria: an active GitHub,
production experience (btrust.tech says 3+ years, builders.btrust.tech says one year), time each
week, and a code challenge or the BOSS preliminary challenge. Its self-paced pathways are always
open. It is a valid route before Gate 3. See the playbook, Part 2A.

---

## 5. The No-Shortcuts Rule (summary)

Full text: [CURRICULUM_CONVENTIONS.md §1](./CURRICULUM_CONVENTIONS.md#1-the-no-shortcuts-rule).
- You type every command and write every line of code that teaches a skill. Worksheets say *what to achieve* and *which RPC/file to read*, never the finished command.
- Hints come in two layers at most. Reference answers in `solutions/` are for after a check passes or after 3 honest attempts.
- Checkers verify outcomes and never print answers. `setup_*.sh` helpers only prepare the environment, and from Stage 02 you write your own setup.
- Keep a command journal in `my-work/<stage>/journal.md` (see [my-work/README.md](./my-work/README.md)).
- Everything public (reviews, PRs, comments) is written by you, in your own words, from your own testing. That is the lab's rule, and it is Bitcoin Core's rule too (`doc/AI_POLICY.md` on master): comments must be written by humans, you must be able to explain your PR yourself, and agents must not be listed as commit authors or co-authors.
