# ⚡ Bitcoin Core & Lightning Protocol Lab

> *"A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution."* — **Satoshi Nakamoto**  
> An open-source repository of first-principles Bitcoin Core C++ consensus verification, functional tests, upstream PR reviews (`bitcoin/bitcoin`), sovereign custody, and a pure-Bitcoin Go application starter kit.

📘 **[Start Here: Mastering What Satoshi Intended — Step-by-Step Workbook & Btrust Guide](./MASTERING_SATOSHI_WORKBOOK.md)**

---

## 🚀 Quickstart: Practice & Build in 1 Command (`./lab.sh`)

```bash
# 1. Check live regtest daemon height, mempool & wallet balances
./lab.sh status

# 2. Practice any specific protocol stage (01 through 08)
./lab.sh practice 01
./lab.sh practice 08

# 3. Run the complete verification suite across all stages
./lab.sh verify-all
```

---

## 🎯 Purpose & Goal
This repository documents my hands-on protocol verification labs, functional test implementations, upstream code reviews, and sovereign application architecture as I work towards full-time open-source Bitcoin & Lightning protocol contribution (**Btrust Builders Fellowship**, **Brink**, **OpenSats**).

Every module is **100% Bitcoin-native (zero fiat, zero custodial intermediaries)** and includes executable scripts, C++ source references into `bitcoin/bitcoin`, and empirical `regtest` verification traces.

---

## 📝 Hands-On Protocol & Builder Lab Log

| Stage | Protocol Topic | Lab Directory & Code | Verified Consensus / Policy Outcome |
| :---: | :--- | :--- | :--- |
| **01** | **Bitcoin Core Daemon, Halving Epochs & Coinbase Maturity** | [`01-node-foundations`](./01-node-foundations/) | Verified `COINBASE_MATURITY = 100` (`src/consensus/consensus.h`) and `nSubsidyHalvingInterval = 150` across heights 203 -> 302 -> 303. |
| **02** | **Raw Transactions, Implicit Fee Guardrails & SegWit Weight** | [`02-raw-tx-and-mempool`](./02-raw-tx-and-mempool/) | Verified implicit fee rule (`nValueIn - value_out`), `-maxtxfee` rejection, `txid` vs `wtxid` malleability fix, `561 WU` / `141 vB` math, and BIP141 witness commitment. |
| **03** | **BIP125 Replace-By-Fee (RBF) & Child-Pays-For-Parent (CPFP)** | [`03-rbf-and-cpfp`](./03-rbf-and-cpfp/) | Triggered `PaysForRBF` Rule #4 relay DoS rejection (`src/policy/rbf.cpp`); evicted low-fee tx via BIP125 RBF; verified CPFP ancestor package feerate (`99.60 sat/vB`) and topological block assembly. |
| **04** | **Python Functional Test Suite (`BitcoinTestFramework` & `MiniWallet`)** | [`04-functional-test-framework`](./04-functional-test-framework/) | Ran upstream `feature_rbf.py` & `mempool_packages.py`; authored custom 2-node P2P functional test (`kisumu_pos_rbf_test.py`) verifying P2P RBF eviction and CPFP package propagation. |
| **05** | **Upstream PR Review: BIP431 TRUC (`v3`) & 1P1C Package Relay** | [`05-truc-package-relay-review`](./05-truc-package-relay-review/) | Reviewed `PackageTRUCChecks` (`src/policy/truc_policy.cpp`); ran `mempool_truc.py`; verified `TRUC-violation` version inheritance and atomic 0-fee `v3` parent + fee-paying `v3` child acceptance via `submitpackage`. |
| **06** | **Lightning HTLC State Machine (`OP_SHA256` & `OP_CHECKSEQUENCEVERIFY`)** | [`06-lightning-htlc-state-machine`](./06-lightning-htlc-state-machine/) | Constructed and funded P2WSH HTLC (`bcrt1q00umt9...`); verified `OP_EQUALVERIFY` preimage failure, immediate preimage settlement, `non-BIP68-final` premature timeout rejection, and 10-block CSV refund. |
| **07** | **Sovereign Custody: BIP380 Descriptors & BIP174 Airgapped PSBT** | [`07-psbt-descriptors-and-miniscript`](./07-psbt-descriptors-and-miniscript/) | Built & tested Go coordinator separating watch-only BIP84 descriptors (`disable_private_keys: true`) from airgapped BIP174 PSBT signing (`0x70736274ff`), finalized and confirmed on `bitcoind -regtest`. |
| **08** | **Sovereign Bitcoin Builder Starter Kit (Go HTTP + JSON-RPC Engine)** | [`08-builder-starter-kit`](./08-builder-starter-kit/) | Zero-dependency Go HTTP server & CLI building watch-only BIP21 satoshi invoices, dust/supply consensus validation, and `OP_RETURN` (`6a20...`) SHA-256 block timestamping. |

---

## 🛠️ Environment & Toolchain
- **OS:** macOS ARM64
- **Base Chain:** Bitcoin Core v29.0 (`bitcoind`, compiled from source with CMake)
- **Layer 2:** Lightning Network Daemon v0.21.3-beta (`lnd`)
- **Testing:** Bitcoin Core Python Functional Test Suite (`test_runner.py`)
- **Language Stack:** C++ (Consensus/Mempool Core), Python 3 (Functional Testing), Go (Descriptor/PSBT Coordinator & Sovereign HTTP Kit)

---

**Maintained by Stanley Chege Thuita ([@altradits](https://github.com/altradits))**  
*Co-founder, BitDevs Kisumu ([@BitDevsKsm](https://x.com/BitDevsKsm))*
