# 📚 Offline Supplementary Knowledge Bank & From-Memory Curriculum Map

> **Zero Internet, Zero AI, Zero Google, Zero Spoon-Feeding:**
> Whenever you or a BitDevs learner hit a roadblock in a programming language (`Go`, `C++20`, `Python 3`, `Bash`) or a Bitcoin/Lightning protocol concept, **do not search Google or ask AI**.
> Look up your current stage in the **Learner Journey Map** below, read the exact offline book chapter on disk, close the book, and complete the **Blind Recall Code Challenges** (`./lab.sh recall`) until you can write the building blocks from pure memory.

---

## 1. The 5 In-Repo From-Memory Workbooks (`./lab.sh book 1..5`)

Stored directly inside [`offline-library/books/`](./books/) (so every learner who clones `bitcoin-core-lab` gets them automatically):

| Book Command | In-Repo Workbook | Core Skills & Blind Recall Drills Covered |
| :--- | :--- | :--- |
| `./lab.sh book 1` | [`BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | Hex $\leftrightarrow$ `[]byte`, Little-Endian vs Big-Endian (`encoding/binary`), `ReverseBytes`, `DoubleSHA256`, `TaggedHash`, `bytes.Buffer`, `MoneyRange` Overflow Guards, Table-Driven Go Tests. |
| `./lab.sh book 2` | [`BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | `CAmount`, `uint256`, `std::span`, RAII Destructors (`~CSHA512`), `LOCK(cs_main)`, `EXCLUSIVE_LOCKS_REQUIRED`, `BlockValidationState`, Boost C++ Unit Tests, Python `BitcoinTestFramework`, `sync_mempools()`. |
| `./lab.sh book 3` | [`BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md`](./books/BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md) | Finite Fields $\mathbb{F}_p$, `secp256k1` ($y^2 = x^3 + 7$), Compressed vs X-Only Pubkeys, ECDSA vs BIP340 Schnorr Linearity ($s \cdot G = R + e \cdot P$), Taproot Tweaking ($Q = P + t \cdot G$), Base58 / Bech32 / Bech32m. |
| `./lab.sh book 4` | [`BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md) | Legacy vs SegWit (BIP141) Byte Layout, Why SegWit Fixed Malleability, Weight (WU) & Virtual Size (`vbytes`), The 4 Timelocks (`nLockTime`, `nSequence`, `OP_CLTV`, `OP_CSV`), `CVE-2010-5139` & `CVE-2018-17144`. |
| `./lab.sh book 5` | [`BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md`](./books/BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md) | 2-of-2 Funding Multisig, Asymmetric Commitment Transactions, `to_local` Script (`OP_IF <revocationpubkey> OP_ELSE <delay> OP_CSV ...`), HTLC Preimages ($H = \text{SHA256}(R)$), `cltv_expiry_delta`, `bitcoind` $\leftrightarrow$ `lnd` ZMQ/RPC Bridge. |

### 🧠 Practice Writing Building Blocks From Memory (`./lab.sh recall`)
```bash
# 1. Blank out the 8 building block functions in offline-library/books/memory_drills.go:
./lab.sh recall blank

# 2. Edit offline-library/books/memory_drills.go from pure memory (no copy-pasting!) and test:
./lab.sh recall check

# 3. Restore verified reference solutions when done:
./lab.sh recall solve
```

---

## 2. The 4 Full Open-Source Textbooks Cloned Locally (`/Users/mac/bitcoin-references/books/`)

In addition to the 5 concise From-Memory Workbooks above, four complete, unabridged open-source Bitcoin & Lightning books are stored locally on your SSD:

| Textbook | Local Path on SSD | Quick CLI Reader Command |
| :--- | :--- | :--- |
| **_Mastering Bitcoin_ (3rd Ed., Antonopoulos & Harding)** | `/Users/mac/bitcoin-references/books/mastering-bitcoin/` | `./lab.sh book mb [ch01..ch12]` |
| **_Programming Bitcoin_ (Jimmy Song — Build From Scratch)** | `/Users/mac/bitcoin-references/books/programming-bitcoin/` | `./lab.sh book pb [ch01..ch13]` |
| **_Learning Bitcoin from the Command Line_ (Blockchain Commons)** | `/Users/mac/bitcoin-references/books/learning-bitcoin-cli/` | `./lab.sh book cli [01..20]` |
| **_Mastering the Lightning Network_ (Antonopoulos, Osuntokun, Pickhardt)** | `/Users/mac/bitcoin-references/books/mastering-lightning/` | `./lab.sh book ln [01..16]` |
| **Satoshi's Original Whitepaper (PDF & Annotated C++ Index)** | `/Users/mac/bitcoin-references/bitcoin.pdf` & [`SATOSHI_WHITEPAPER.md`](./SATOSHI_WHITEPAPER.md) | `cat offline-library/SATOSHI_WHITEPAPER.md` |
| **All 270+ BIPs & 11 Lightning BOLTs** | `/Users/mac/bitcoin-references/bips/` & `/Users/mac/bitcoin-references/bolts/` | `./lab.sh bip 340` / `./lab.sh bolt 3` |
| **Bitcoin Core Official C++ Developer Notes** | `/Users/mac/bitcoin/doc/developer-notes.md` | `less /Users/mac/bitcoin/doc/developer-notes.md` |

---

## 3. Complete Learner Journey Map: Which Book to Read When You Get Stuck

Every stage in your curriculum links directly to its underlying programming and protocol chapters below:

| Learner Journey Stage | If You Hit a Programming Gap, Read: | If You Hit a Bitcoin / Protocol Gap, Read: | Blind-Recall Verification |
| :--- | :--- | :--- | :--- |
| **[Stage 00: Start Small (`00-start-small/`)](../00-start-small/README.md)** | [`Book 1: Ch 1`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) (Bytes, Hex, CLI basics) | `./lab.sh book cli 03` (_Learning Bitcoin CLI_ Ch 03–04: `bitcoin-cli` & `bitcoin.conf`) | `./lab.sh step 5` |
| **[Stage 01: Node Foundations & Coinbase Maturity (`01-node-foundations/`)](../01-node-foundations/README.md)** | [`Book 1: Ch 1–2`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md), [`Book 2: Ch 1`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [`SATOSHI_WHITEPAPER.md`](./SATOSHI_WHITEPAPER.md), `./lab.sh book mb ch02`, `./lab.sh book cli 04` | `./lab.sh recall check` (Drill 1) |
| **[Stage 02: Raw Transactions & SegWit Weight (`02-raw-tx-and-mempool/`)](../02-raw-tx-and-mempool/README.md)** | [`Book 1: Ch 1 & 3`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) (`encoding/binary`, `bytes.Buffer`) | [`Book 4: Ch 1–2`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `./lab.sh book pb ch05`, `./lab.sh bip 141` | `./lab.sh recall check` (Drills 1–3, 6) |
| **[Stage 03: BIP125 RBF & CPFP (`03-rbf-and-cpfp/`)](../03-rbf-and-cpfp/README.md)** | [`Book 1: Ch 4`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) (Integer fee math) | [`Book 4: Ch 2–3`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `./lab.sh book mb ch06`, `./lab.sh bip 125` | `./lab.sh recall check` (Drills 6–7) |
| **[Stage 04: Python Functional Test Framework (`04-functional-test-framework/`)](../04-functional-test-framework/README.md)** | [`Book 2: Ch 5`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) (`BitcoinTestFramework`, `sync_mempools()`) | [`pr-reviews/merged-journeys/PR-36439-JOURNEY.md`](../pr-reviews/merged-journeys/PR-36439-JOURNEY.md) & [`PR-36545-JOURNEY.md`](../pr-reviews/merged-journeys/PR-36545-JOURNEY.md) | `./lab.sh practice 04` |
| **[Stage 05: BIP431 TRUC (v3) & 1P1C Package Relay (`05-truc-package-relay-review/`)](../05-truc-package-relay-review/README.md)** | [`Book 2: Ch 1–3`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) (C++ policy validation) | [`Book 4: Ch 2`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `./lab.sh bip 431`, [`PR-33630-JOURNEY.md`](../pr-reviews/merged-journeys/PR-33630-JOURNEY.md) | `./lab.sh practice 05` |
| **[Stage 06: Lightning P2WSH HTLC State Machine (`06-lightning-htlc-state-machine/`)](../06-lightning-htlc-state-machine/README.md)** | [`Book 2: Ch 5`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) (Python scripting), [`Book 1: Ch 2`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [`Book 4: Ch 3`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), [`Book 5: Ch 2–3`](./books/BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md), `./lab.sh bolt 3` | `./lab.sh practice 06` |
| **[Stage 07: BIP380 Descriptors, PSBT & Miniscript (`07-psbt-descriptors-and-miniscript/`)](../07-psbt-descriptors-and-miniscript/README.md)** | [`Book 1: Ch 3 & 5`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) (Go structs & table tests) | [`Book 3: Ch 1–4`](./books/BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md), `./lab.sh bip 174`, `./lab.sh bip 380` | `./lab.sh practice 07` |
| **[Stage 08: Sovereign Bitcoin Builder Starter Kit (`08-builder-starter-kit/`)](../08-builder-starter-kit/README.md)** | [`Book 1: Ch 1–5`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) (Go RPC & wallet architecture) | `./lab.sh book cli 05`–`08`, `./lab.sh book mb ch05` | `./lab.sh practice 08` |
| **[Stage 09: Bug Dojo & Consensus CVEs (`09-consensus-bug-hunting/`)](../09-consensus-bug-hunting/README.md)** | [`Book 1: Ch 4–5`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md), [`Book 2: Ch 1–4`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [`Book 4: Ch 4`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md) (`CVE-2010-5139` & `CVE-2018-17144`) | `./lab.sh recall check` (Drills 5 & 8) + `./lab.sh dojo check` |
| **[Stage 10: Protocol Primitives From Scratch (`10-protocol-primitives-from-scratch/`)](../10-protocol-primitives-from-scratch/README.md)** | [`Book 1: Ch 1–5`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) (Pure Go byte primitives) | [`Book 3: Ch 1–4`](./books/BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md), [`Book 4: Ch 1–4`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `./lab.sh book pb ch01`–`ch07` | `./lab.sh recall check` (All 8 Drills) |
| **[Stage 11: From Regtest to Sovereign Mainnet (`11-from-regtest-to-live-mainnet/`)](../11-from-regtest-to-live-mainnet/README.md)** | [`Book 1: Ch 1–5`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md), [`Book 2: Ch 1–5`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [`Book 4: Ch 2`](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `/Users/mac/bitcoin/doc/reduce-memory.md` | `./lab.sh practice 11` |
| **[Stage 12: Lightning Readiness & Polar LND (`12-lightning-readiness-and-bitcoind-bridge/`)](../12-lightning-readiness-and-bitcoind-bridge/README.md)** | [`Book 1: Ch 2–3`](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [`Book 5: Ch 1–4`](./books/BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md), `./lab.sh book ln 03`–`10`, `./lab.sh bolt 2`, `./lab.sh bolt 3`, `./lab.sh bolt 5` | `./lab.sh practice 12` & `./lab.sh polar` |
| **[Drills 1–8 & PR Reviews](../BITCOIN_FROM_SOURCE_MASTERY.md)** (`./lab.sh journeys`) | [`Book 2: Ch 1–5`](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) (C++20, Boost, Python TestFramework) | `/Users/mac/bitcoin/doc/developer-notes.md`, [`pr-reviews/merged-journeys/README.md`](../pr-reviews/merged-journeys/README.md) | `./lab.sh drill 1..8` & `./lab.sh journeys` |
