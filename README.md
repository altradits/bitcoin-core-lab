# ⚡ Bitcoin Core & Lightning Protocol Lab

> *"A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution."* — **Satoshi Nakamoto**  
> An open-source repository of first-principles Bitcoin Core C++ consensus verification, protocol primitives from scratch, functional tests, maintainer-grade upstream PR audits (`bitcoin/bitcoin`), interactive bug-fix dojo, sovereign custody, and a pure-Bitcoin Go application starter kit.

### 📚 Core Guides & Self-Contained Offline Study System
- 🌱 **[Stage 00: Start Small — The 15-Minute Micro-Win Ladder (`00-start-small`)](./00-start-small/README.md)**
- 🔨 **[Bitcoin Core From Source: The 8-Drill Repetition & Open-Source Mastery Manual (`./lab.sh drill 1..8`)](./BITCOIN_FROM_SOURCE_MASTERY.md)**
- 🌍 **[Stage 11: Apple M1 Sovereign Node, Wallet of Satoshi Migration, Fee/Speed Mastery & PR Fix Proposals (`11-from-regtest-to-live-mainnet`)](./11-from-regtest-to-live-mainnet/README.md)**
- ⚡ **[Stage 12: The Bitcoin-to-Lightning Readiness Gate & How `lnd` Interacts With `bitcoind` (`12-lightning-readiness-and-bitcoind-bridge`)](./12-lightning-readiness-and-bitcoind-bridge/README.md)**
- ⚙️ **[Stage 10: Bitcoin Protocol Primitives From Scratch (`10-protocol-primitives-from-scratch`)](./10-protocol-primitives-from-scratch/README.md)**
- 🥋 **[Stage 09: The Bitcoin Core Bug Dojo & PR Fix Arena (`09-bug-dojo-and-pr-mastery`)](./09-bug-dojo-and-pr-mastery/README.md)**
- 🛡️ **[The Guardian's Manual: If Satoshi Taught His Son How to Protect & Audit Bitcoin](./SATOSHI_GUARDIAN_MANUAL.md)**
- 📘 **[Mastering What Satoshi Intended — Step-by-Step Workbook & Btrust Guide](./MASTERING_SATOSHI_WORKBOOK.md)**
- 🗓️ **[30-Day Offline Bitcoin Core & Lightning Mastery Curriculum](./OFFLINE_30_DAY_CURRICULUM.md)**
- 📄 **[Satoshi Nakamoto's Original 2008 Whitepaper (Annotated w/ C++ Source Links)](./offline-library/SATOSHI_WHITEPAPER.md)**
- 🗂️ **[Offline BIPs (`1–431+`) & Lightning BOLTs (`1–11`) Index](./offline-library/OFFLINE_INDEX.md)**
- 🔍 **[Upstream `bitcoin/bitcoin` Maintainer PR Audits (`pr-reviews/`)](./pr-reviews/)**

---

## 🚀 Quickstart: Start Small, Drill From Source, Fix Bugs & Audit PRs (`./lab.sh`)

```bash
# 0. Start Small (5-to-15 minute micro-wins with your live node when things feel hard)
./lab.sh step 1           # Walk through Micro-Steps 1..5
./lab.sh practice 00      # Run & edit your first 60-line Bitcoin app

# 1. Master Bitcoin Core From Source by Repetition (Download -> CMake Build -> Test -> PR Review)
./lab.sh drill 1          # Drill 1..8: Git clone, CMake build, wallets, test_bitcoin & Tested ACK

# 2. Enter the Bug Dojo: load 5 real pre-PR vulnerabilities, watch exploits fail, then fix them!
./lab.sh dojo break
./lab.sh dojo check 1     # Test Mission 1 (CVE-2010-5139 & CVE-2018-17144)
./lab.sh dojo solve       # Restore & verify all 5 upstream solutions

# 3. Run Protocol Primitives, Apple M1 Sovereign Wallet & Lightning L1/L2 Readiness Bridge
./lab.sh practice 10
./lab.sh practice 11
./lab.sh practice 12

# 4. Inspect Satoshi's Genesis Block & the 61-Line Consensus Shield
./lab.sh genesis

# 5. Read any BIP or Lightning BOLT specification 100% offline
./lab.sh bip 340
./lab.sh bolt 3

# 6. List & run a 6-Point Guardian Security Audit on any upstream PR 100% offline
./lab.sh pr-list
./lab.sh pr-audit 35320

# 7. Commit your daily study/audit offline, then push when internet returns
./lab.sh commit-offline "docs(pr-audit): complete 6-point guardian audit of bitcoin#35320"
./lab.sh sync
```

---

## 🎯 Purpose & Goal
This repository documents my hands-on protocol verification labs, functional test implementations, upstream code reviews, and sovereign application architecture as I work towards full-time open-source Bitcoin & Lightning protocol contribution (**Btrust Builders Fellowship**, **Brink**, **OpenSats**).

Every module is **100% Bitcoin-native (zero fiat, zero custodial intermediaries)** and includes executable scripts, C++ source references into `bitcoin/bitcoin`, and empirical `regtest` verification traces.

---

## 📝 Hands-On Protocol, Bug Dojo & Builder Lab Log

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
| **11** | **Apple M1 Sovereign Node, WoS Migration, Fee Optimizer & PR Fix Proposals** | [`11-from-regtest-to-live-mainnet`](./11-from-regtest-to-live-mainnet/) | Profiled M1 Mac (`prune=5500`, `dbcache=1024`), Wallet of Satoshi -> sovereign `bc1q`/`bc1p` migration, `vByte` fee/speed math (`RBF`/`CPFP`/`sendmany`), and PR Fix Proposal Matrix. |
| **12** | **Bitcoin-to-Lightning Readiness Gate & `lnd` <-> `bitcoind` Bridge** | [`12-lightning-readiness-and-bitcoind-bridge`](./12-lightning-readiness-and-bitcoind-bridge/) | Verified the 6 Bitcoin Core prerequisites for Lightning (2-of-2 multisig, SegWit `txid` fix, `OP_CSV` revocation penalty, HTLCs, TRUC/CPFP) and simulated off-chain channel state transitions & breach penalties. |

---

## 🛠️ Environment & Toolchain
- **Hardware:** Apple M1 MacBook Air (`MacBookAir10,1`, 8 Cores, 8 GB RAM, Pruned Sovereign Node Ready)
- **Base Chain:** Bitcoin Core v29.0 (`bitcoind`, compiled from source with CMake)
- **Layer 2:** Lightning Network Daemon v0.21.3-beta (`lnd`)
- **Offline Reference Vault:** `/Users/mac/bitcoin-references/` (`bitcoin.pdf`, all 270+ BIPs, all Lightning BOLTs)
- **Language Stack:** C++ (Consensus/Mempool Core), Python 3 (Functional Testing), Go (Protocol Primitives, Bug Dojo, PSBT Coordinator & Sovereign HTTP Kit)

---

**Maintained by Stanley Chege Thuita ([@altradits](https://github.com/altradits))**  
*Co-founder, BitDevs Kisumu ([@BitDevsKsm](https://x.com/BitDevsKsm))*
