# ⚡ Bitcoin Core & Lightning Protocol Lab (`bitcoin-core-lab`)

[![License: MIT](https://img.shields.io/badge/License-MIT-F7931A.svg)](./LICENSE)
[![Bitcoin Core](https://img.shields.io/badge/Bitcoin_Core-v29.0_From_Source-F7931A)](https://github.com/bitcoin/bitcoin)
[![Lightning LND](https://img.shields.io/badge/Lightning-LND_%26_BOLTs-792EE5)](https://github.com/lightningnetwork/lnd)
[![100% FOSS](https://img.shields.io/badge/100%25_Bitcoin_FOSS-Zero_Fiat-success)](./BTRUST_AND_BITDEVS_PLAYBOOK.md)

> *"A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution."* — **Satoshi Nakamoto**  
> An open-source, self-contained Bitcoin Core C++ & Lightning Network verification lab, offline textbook & blind-recall knowledge bank, interactive CVE Bug Dojo, maintainer PR review archive, and sovereign node/wallet toolkit built for **BitDevs Kisumu** and aspiring **Btrust / Brink / OpenSats** protocol contributors.

---

## 📚 Complete Offline Study System & Navigation Map

- 🌱 **[Stage 00: Start Small — The 15-Minute Micro-Win Ladder (`00-start-small/`)](./00-start-small/README.md)**
- 🔨 **[Bitcoin Core From Source: The 8-Drill Repetition & Open-Source Mastery Manual (`./lab.sh drill 1..8`)](./BITCOIN_FROM_SOURCE_MASTERY.md)**
- 📖 **[Offline Supplementary Knowledge Bank: 5 From-Memory Workbooks, 4 Full Books & 8 Blind-Recall Drills (`./lab.sh book` & `./lab.sh recall`)](./offline-library/OFFLINE_INDEX.md)**
- 🔍 **[Maintainer PR Review Playbook: 8 Merged PR Review Journeys (`./lab.sh journeys`)](./pr-reviews/merged-journeys/README.md)** & **[10 Upstream PR Security Audits (`pr-reviews/`)](./pr-reviews/)**
- 🥋 **[Stage 09: The Bitcoin Core Bug Dojo & PR Fix Arena (`09-bug-dojo-and-pr-mastery/`)](./09-bug-dojo-and-pr-mastery/README.md)**
- ⚙️ **[Stage 10: Bitcoin Protocol Primitives From Scratch (`10-protocol-primitives-from-scratch/`)](./10-protocol-primitives-from-scratch/README.md)**
- 🌍 **[Stage 11: Apple M1 Sovereign Node, Wallet Migration, Fee/Speed Mastery & PR Fix Proposals (`11-from-regtest-to-live-mainnet/`)](./11-from-regtest-to-live-mainnet/README.md)**
- ⚡ **[Stage 12: Bitcoin-to-Lightning Readiness Gate, Polar/Docker & `lnd` $\leftrightarrow$ `bitcoind` Bridge (`12-lightning-readiness-and-bitcoind-bridge/`)](./12-lightning-readiness-and-bitcoind-bridge/README.md)**
- 🤝 **[Btrust Grant Compliance & BitDevs Socratic Seminar Playbook (`BTRUST_AND_BITDEVS_PLAYBOOK.md`)](./BTRUST_AND_BITDEVS_PLAYBOOK.md)**
- 🛡️ **[The Guardian's Manual: If Satoshi Taught His Son How to Protect & Audit Bitcoin](./SATOSHI_GUARDIAN_MANUAL.md)**
- 📘 **[Mastering What Satoshi Intended — Step-by-Step Workbook](./MASTERING_SATOSHI_WORKBOOK.md)** & **[30-Day Offline Curriculum](./OFFLINE_30_DAY_CURRICULUM.md)**
- 📄 **[Satoshi Nakamoto's Original 2008 Whitepaper (Annotated w/ C++ Source Links)](./offline-library/SATOSHI_WHITEPAPER.md)**

---

## 🚀 Quickstart CLI (`./lab.sh`)

```bash
# 🍏 1. Apple M1 Hardware Health & RAM Protection (Run Anytime)
./lab.sh health           # Full M1 CPU, 8 GB RAM, SSD Swap & daemon footprint report
./lab.sh rest             # Stop bitcoind & Polar containers when done studying to free RAM

# 📚 2. Offline Knowledge Bank & Blind-Recall Code Arena (Zero Internet / Zero AI / Zero Google)
./lab.sh book             # View the Stage-to-Book Learner Journey Map
./lab.sh book 1           # Read From-Memory Workbooks (1:Go, 2:C++/Py, 3:Crypto, 4:Tx/Script, 5:LN)
./lab.sh book mb ch04     # Read Mastering Bitcoin, Programming Bitcoin (pb), CLI (cli), or LN (ln)
./lab.sh recall blank     # Blank out 8 core Bitcoin functions to test writing from pure memory
./lab.sh recall check     # Run the 8 Blind-Recall unit tests
./lab.sh recall solve     # Restore verified reference solutions

# 🌱 3. Start Small & Master Bitcoin Core From Source by Repetition
./lab.sh step 1           # Walk through Micro-Steps 1..5
./lab.sh drill 1          # Drill 1..8: git clone -> CMake build -> test_bitcoin -> PR review

# 🥋 4. Bug Dojo: Break, Fix & Verify 5 Real Bitcoin Core Vulnerabilities
./lab.sh dojo break       # Load 5 unfixed pre-PR vulnerabilities into dojo_missions.go
./lab.sh dojo check 1     # Test Mission 1 (CVE-2010-5139 & CVE-2018-17144)
./lab.sh dojo solve       # Restore & verify all 5 upstream solutions

# 🔍 5. Study Real Maintainer Review Journeys & Audit Upstream PRs
./lab.sh journeys         # Read 7 Maintainer Comment Patterns & 8 merged PR review journeys
./lab.sh journeys 36447   # Inspect how reviewer comments improved PR #36447 before merge
./lab.sh pr-audit 36553   # Run a 6-Point Guardian Security Audit on any open/merged PR

# ⚡ 6. Sovereign Node, Lightning Readiness & Polar LND Simulation
./lab.sh practice 11      # Apple M1 Pruned Mainnet profile, descriptor wallet & fee optimizer
./lab.sh practice 12      # 6-Point Bitcoin->Lightning Readiness Gate & L1/L2 state simulator
./lab.sh polar            # Inspect ~/.polar networks & print Docker lncli terminal drills
```

---

## 📝 Complete 13-Stage Protocol, Bug Dojo & Builder Lab Log

| Stage | Protocol Topic | Lab Directory & Code | Verified Consensus / Policy Outcome |
| :---: | :--- | :--- | :--- |
| **00** | **Start Small: 15-Minute Micro-Wins & First 60-Line Bitcoin App** | [`00-start-small`](./00-start-small/) | Interactive 5-step ladder (`./lab.sh step 1..5`) & 60-line Go app generating `bech32` addresses and confirming satoshi transfers on live `bitcoind`. |
| **01** | **Bitcoin Core Daemon, Halving Epochs & Coinbase Maturity** | [`01-node-foundations`](./01-node-foundations/) | Verified `COINBASE_MATURITY = 100` (`src/consensus/consensus.h`) and `nSubsidyHalvingInterval = 150` across heights 203 -> 302 -> 303. |
| **02** | **Raw Transactions, Implicit Fee Guardrails & SegWit Weight** | [`02-raw-tx-and-mempool`](./02-raw-tx-and-mempool/) | Verified implicit fee rule (`nValueIn - value_out`), `-maxtxfee` rejection, `txid` vs `wtxid` malleability fix, `561 WU` / `141 vB` math, and BIP141 witness commitment. |
| **03** | **BIP125 Replace-By-Fee (RBF) & Child-Pays-For-Parent (CPFP)** | [`03-rbf-and-cpfp`](./03-rbf-and-cpfp/) | Triggered `PaysForRBF` Rule #4 relay DoS rejection (`src/policy/rbf.cpp`); evicted low-fee tx via BIP125 RBF; verified CPFP ancestor package feerate (`99.60 sat/vB`) and topological block assembly. |
| **04** | **Python Functional Test Suite (`BitcoinTestFramework` & `MiniWallet`)** | [`04-functional-test-framework`](./04-functional-test-framework/) | Ran upstream `feature_rbf.py` & `mempool_packages.py`; authored custom 2-node P2P functional test (`kisumu_pos_rbf_test.py`) verifying P2P RBF eviction and CPFP package propagation. |
| **05** | **Upstream PR Review: BIP431 TRUC (`v3`) & 1P1C Package Relay** | [`05-truc-package-relay-review`](./05-truc-package-relay-review/) | Reviewed `PackageTRUCChecks` (`src/policy/truc_policy.cpp`); ran `mempool_truc.py`; verified `TRUC-violation` version inheritance and atomic 0-fee `v3` parent + fee-paying `v3` child acceptance via `submitpackage`. |
| **06** | **Lightning HTLC State Machine (`OP_SHA256` & `OP_CHECKSEQUENCEVERIFY`)** | [`06-lightning-htlc-state-machine`](./06-lightning-htlc-state-machine/) | Constructed and funded P2WSH HTLC (`bcrt1q00umt9...`); verified `OP_EQUALVERIFY` preimage failure, immediate preimage settlement, `non-BIP68-final` premature timeout rejection, and 10-block CSV refund. |
| **07** | **Sovereign Custody: BIP380 Descriptors & BIP174 Airgapped PSBT** | [`07-psbt-descriptors-and-miniscript`](./07-psbt-descriptors-and-miniscript/) | Built & tested Go coordinator separating watch-only BIP84 descriptors (`disable_private_keys: true`) from airgapped BIP174 PSBT signing (`0x70736274ff`), finalized and confirmed on `bitcoind -regtest`. |
| **08** | **Sovereign Bitcoin Builder Starter Kit (Go HTTP + JSON-RPC Engine)** | [`08-builder-starter-kit`](./08-builder-starter-kit/) | Zero-dependency Go HTTP server & CLI building watch-only BIP21 satoshi invoices, dust/supply consensus validation, and `OP_RETURN` (`6a20...`) SHA-256 block timestamping. |
| **09** | **The Bitcoin Core Bug Dojo & PR Fix Arena (5 Upstream Bugs)** | [`09-bug-dojo-and-pr-mastery`](./09-bug-dojo-and-pr-mastery/) | Interactive break-and-fix arena covering `CVE-2010-5139` overflow, `CVE-2018-17144` duplicate inputs, `PR #35320` BIP32 seed bounds, `PR #32800` sigop vsize, BIP125 RBF DoS, and `PR #33014` PSBT validation. |
| **10** | **Protocol Primitives From Scratch (PoW, CompactSize, Merkle, Script VM)** | [`10-protocol-primitives-from-scratch`](./10-protocol-primitives-from-scratch/) | Zero-dependency Go implementation of `SHA256d`, BIP340 `TaggedHash`, canonical `CompactSize`, 80-byte Genesis Block PoW & `nBits` target math, Merkle tree root, and a stack-based Script interpreter. |
| **11** | **Apple M1 Sovereign Node, Wallet Migration, Fee Optimizer & PR Fix Matrix** | [`11-from-regtest-to-live-mainnet`](./11-from-regtest-to-live-mainnet/) | Profiled M1 Mac (`prune=5500`, `dbcache=1024`), custodial-to-sovereign `bc1q`/`bc1p` migration, `vByte` fee/speed math (`RBF`/`CPFP`/`sendmany`), and PR Fix Proposal Matrix. |
| **12** | **Bitcoin-to-Lightning Readiness Gate, Polar/Docker & `lnd` $\leftrightarrow$ `bitcoind` Bridge** | [`12-lightning-readiness-and-bitcoind-bridge`](./12-lightning-readiness-and-bitcoind-bridge/) | Verified the 6 Bitcoin Core prerequisites for Lightning, simulated off-chain channel state updates & `OP_CSV` revocation justice sweeps, and integrated Polar/Docker `lncli` drills. |

---

## 🔍 Upstream `bitcoin/bitcoin` PR Reviews & Merged Review Journeys

- **Live Open PR Audits ([`pr-reviews/`](./pr-reviews/)):**
  - [`PR-36553-AUDIT.md`](./pr-reviews/PR-36553-AUDIT.md) — `test: Add missing sync_mempools in wallet_conflicts.py` (`@maflcko`)
  - [`PR-36555-AUDIT.md`](./pr-reviews/PR-36555-AUDIT.md) — `rpc: return error when invalidateblock fails` (`@ja7ad`)
  - [`PR-36550-AUDIT.md`](./pr-reviews/PR-36550-AUDIT.md) — `crypto: cleanse CSHA512 state in its destructor` (`@fametrano`)
- **8 Downloaded Merged PR Review Journeys ([`pr-reviews/merged-journeys/`](./pr-reviews/merged-journeys/README.md)):**
  - Full verbatim maintainer discussion threads, inline code suggestions, and before/after code improvements across `#36545`, `#36447`, `#36469`, `#36439`, `#35724`, `#33630`, `#33624`, and `#32313`.

---

## 🛠️ Environment & Toolchain
- **Hardware:** Apple M1 MacBook Air (`MacBookAir10,1`, 8 Cores, 8 GB Unified RAM, 67 GiB Free SSD — Pruned Sovereign Mainnet Ready)
- **Base Chain:** Bitcoin Core v29.0 (`bitcoind`, `bitcoin-cli`, `test_bitcoin` compiled from source with CMake + SQLite Descriptor Wallets)
- **Layer 2:** Lightning Network Daemon (`lnd` + `lncli` + Polar Docker simulation clusters)
- **Offline Reference Vault:** 5 In-Repo From-Memory Workbooks, 4 Full Open-Source Books (`Mastering Bitcoin`, `Programming Bitcoin`, `Learning Bitcoin from the Command Line`, `Mastering the Lightning Network`), `bitcoin.pdf`, 270+ BIPs, and 11 BOLTs.

---

**Maintained by Stanley Chege Thuita ([@altradits](https://github.com/altradits))**  
*Co-founder, BitDevs Kisumu ([@BitDevsKsm](https://x.com/BitDevsKsm)) · MIT License*
