# ⚡ Bitcoin Core & Lightning Lab Notes

> *"Proof of Work speaks louder than credentials."*  
> An open-source log of first-principles research, upstream PR reviews (`bitcoin/bitcoin`), and circular economy architecture experiments for **Kisumu, Kenya**.

---

## 🎯 Purpose & Goal
This repository documents my hands-on hourly challenges and code experiments as I work towards full-time open-source Bitcoin protocol contribution and grant support (**Btrust Builders Fellowship**, **Brink**, **OpenSats**).

Every lesson, test run, PR reproduction, and architecture design is recorded here with code, reproduction steps, and technical rationale.

---

## 🗺️ Curriculum Track

| Module | Focus Area | Core Technologies | Status |
| :--- | :--- | :--- | :---: |
| **01. Node Engine** | Bitcoin Core compilation, Regtest daemon, JSON-RPC & LevelDB UTXO tracking | C++, `bitcoind`, `bitcoin-cli` | `In Progress ⚡` |
| **02. Functional Tests** | Running and writing Python simulations for consensus, mempool & wallet edge cases | Python 3, `test_framework` | `Upcoming ⏳` |
| **03. Upstream PR Reviews** | Reproducing PRs from `bitcoin/bitcoin`, running `test_runner.py`, and publishing reviews | Git, C++, Bitcoin Core PR Review Club | `Upcoming ⏳` |
| **04. Lightning Layer 2** | Multi-node topologies, routing fees, channel liquidity & HTLC state machine | LND, Polar, Go gRPC | `Upcoming ⏳` |
| **05. Kisumu Circular Economy** | Low-latency Point-of-Sale (POS) & M-Pesa automated on/off-ramp rails | Go, Daraja API, Web LN | `Active Build 🚀` |

---

## 📝 Hourly Challenge Log

| Hour | Challenge Topic | Artifact / Code | Outcome |
| :---: | :--- | :--- | :---: |
| **01** | **Bitcoin Core Daemon & Coinbase Maturity** | [`01-node-foundations`](./01-node-foundations/) | Mined 101 regtest blocks; passed coinbase maturity rule; verified UTXO creation. |
| **02** | **Raw Transactions, Implicit Fee Guardrails & Mempool Weight** | [`02-raw-tx-and-mempool`](./02-raw-tx-and-mempool/) | Spent 25 BTC UTXO via raw hex; triggered `-maxtxfee` guardrail; verified SegWit `txid` vs `wtxid`, `561 WU` / `141 vB` math, and BIP141 witness commitment. |

---

## 🛠️ Environment & Toolchain
- **OS:** macOS ARM64
- **Base Chain:** Bitcoin Core v29.0 (`bitcoind`)
- **Layer 2:** Lightning Network Daemon v0.21.3-beta (`lnd`)
- **Testing:** Python Functional Test Suite & Polar
- **Language Stack:** Go (Backend/Services), C++ (Protocol Core), Python (Testing)

---

**Maintained by Stanley Chege Thuita ([@altradits](https://github.com/altradits))**  
*Co-founder, BitDevs Kisumu ([@BitDevsKsm](https://x.com/BitDevsKsm))*
