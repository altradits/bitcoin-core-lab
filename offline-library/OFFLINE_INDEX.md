# Offline study library

When a stage assumes a skill you lack, look it up here instead of
searching the web. The library has two parts: five short workbooks
shipped in this repo, and full textbooks plus specs that live in your
own local reference library.

Set `BITCOIN_REFERENCES` to your reference library root (default
`~/bitcoin-references`). The lab ships none of the outside texts. See
[LICENSES.md](../LICENSES.md) for what each source allows.

## 1. The 5 in repo workbooks (`./lab.sh book 1..5`)

Stored in [offline-library/books/](./books/), so every clone gets
them automatically:

| Book command | Workbook | Skills covered |
| :--- | :--- | :--- |
| `./lab.sh book 1` | [BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | Hex and bytes, endianness, `ReverseBytes`, `DoubleSHA256`, `TaggedHash`, `bytes.Buffer`, overflow guards, table tests. |
| `./lab.sh book 2` | [BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | `CAmount`, `uint256`, `std::span`, RAII destructors, `LOCK(cs_main)`, `BlockValidationState`, Boost tests, `BitcoinTestFramework`. |
| `./lab.sh book 3` | [BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md](./books/BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md) | Finite fields, secp256k1, compressed vs x-only keys, ECDSA vs Schnorr, Taproot tweaking, Base58, Bech32, Bech32m. |
| `./lab.sh book 4` | [BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md) | Legacy vs SegWit layout, malleability fix, weight and vsize, the 4 timelocks, CVE-2010-5139 and CVE-2018-17144. |
| `./lab.sh book 5` | [BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md](./books/BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md) | Funding multisig, commitment transactions, `to_local` script, HTLC preimages, `cltv_expiry_delta`, the `bitcoind` to `lnd` bridge. |

### Practice from memory (`./lab.sh recall`)

```bash
# 1. Blank the 8 building block functions in offline-library/books/memory_drills.go:
./lab.sh recall blank

# 2. Reimplement them from memory, then test:
./lab.sh recall check

# 3. Restore the reference solutions when done:
./lab.sh recall solve
```

## 2. Outside textbooks and specs (your reference library)

Four complete books plus specs, read from `$BITCOIN_REFERENCES`
(default `~/bitcoin-references`). Clone or install them yourself;
the lab never copies them.

| Textbook | Path under `$BITCOIN_REFERENCES` | Reader command |
| :--- | :--- | :--- |
| _Mastering Bitcoin_ 3rd ed. (Antonopoulos, Harding) | `books/mastering-bitcoin/` | `./lab.sh book mb [ch01..ch12]` |
| _Programming Bitcoin_ (Jimmy Song) | `books/programming-bitcoin/` | `./lab.sh book pb [ch01..ch13]` |
| _Learning Bitcoin from the Command Line_ | `books/learning-bitcoin-cli/` | `./lab.sh book cli [01..20]` |
| _Mastering the Lightning Network_ | `books/mastering-lightning/` | `./lab.sh book ln [01..16]` |
| Satoshi whitepaper (PDF plus lab study guide) | `bitcoin.pdf`, [SATOSHI_WHITEPAPER.md](./SATOSHI_WHITEPAPER.md) | `cat offline-library/SATOSHI_WHITEPAPER.md` |
| BIPs and BOLTs | `bips/`, `bolts/` | `./lab.sh bip 340`, `./lab.sh bolt 3` |
| Bitcoin Core developer notes | `$BITCOIN_ROOT/doc/developer-notes.md` | `less ~/bitcoin/doc/developer-notes.md` |

Licences: Mastering Bitcoin and Mastering Lightning are CC BY-SA;
the CLI book is CC BY; Programming Bitcoin is CC BY-NC-ND (reference
only, never copied). Details in [LICENSES.md](../LICENSES.md).

## 3. Stage to book map

Which chapter to read when a stage assumes a skill you lack:

| Stage | Programming gap | Protocol gap | Verify with |
| :--- | :--- | :--- | :--- |
| [00: Start small](../00-start-small/README.md) | [Book 1: Ch 1](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | `./lab.sh book cli 03` | `./lab.sh step 5` |
| [01: Node basics](../01-node-foundations/README.md) | [Book 1: Ch 1-2](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md), [Book 2: Ch 1](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [SATOSHI_WHITEPAPER.md](./SATOSHI_WHITEPAPER.md), `./lab.sh book mb ch02` | `./lab.sh recall check` (Drill 1) |
| [02: Raw transactions](../02-raw-tx-and-mempool/README.md) | [Book 1: Ch 1, 3](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [Book 4: Ch 1-2](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `./lab.sh bip 141` | `./lab.sh recall check` (Drills 1-3, 6) |
| [03: RBF and CPFP](../03-rbf-and-cpfp/README.md) | [Book 1: Ch 4](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [Book 4: Ch 2-3](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `./lab.sh bip 125` | `./lab.sh recall check` (Drills 6-7) |
| [04: Functional tests](../04-functional-test-framework/README.md) | [Book 2: Ch 5](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [PR-36439 journey](../pr-reviews/merged-journeys/PR-36439-JOURNEY.md) | `./lab.sh practice 04` |
| [05: TRUC and packages](../05-truc-package-relay-review/README.md) | [Book 2: Ch 1-3](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [Book 4: Ch 2](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), `./lab.sh bip 431` | `./lab.sh practice 05` |
| [06: HTLC contracts](../06-lightning-htlc-state-machine/README.md) | [Book 2: Ch 5](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md), [Book 1: Ch 2](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [Book 4: Ch 3](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md), [Book 5: Ch 2-3](./books/BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md) | `./lab.sh practice 06` |
| [07: Descriptors and PSBT](../07-psbt-descriptors-and-miniscript/README.md) | [Book 1: Ch 3, 5](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [Book 3: Ch 1-4](./books/BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md), `./lab.sh bip 174` | `./lab.sh practice 07` |
| [08: Builder starter kit](../08-builder-starter-kit/README.md) | [Book 1: Ch 1-5](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | `./lab.sh book cli 05`-`08` | `./lab.sh practice 08` |
| [09: Bug dojo](../09-bug-dojo-and-pr-mastery/README.md) | [Book 1: Ch 4-5](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md), [Book 2: Ch 1-4](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [Book 4: Ch 4](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md) | `./lab.sh dojo check` |
| [10: Protocol code](../10-protocol-primitives-from-scratch/README.md) | [Book 1: Ch 1-5](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [Book 3: Ch 1-4](./books/BOOK-3-CRYPTOGRAPHY-AND-SERIALIZATION-PRIMER.md), [Book 4: Ch 1-4](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md) | `./lab.sh recall check` (all drills) |
| [11: Small machine node](../11-from-regtest-to-live-mainnet/README.md) | [Book 1: Ch 1-5](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [Book 4: Ch 2](./books/BOOK-4-TRANSACTIONS-SCRIPT-AND-CONSENSUS-ENGINE.md) | `./lab.sh practice 11` |
| [12: Lightning bridge](../12-lightning-readiness-and-bitcoind-bridge/README.md) | [Book 1: Ch 2-3](./books/BOOK-1-GO-AND-SYSTEMS-FROM-MEMORY.md) | [Book 5: Ch 1-4](./books/BOOK-5-LIGHTNING-BOLTS-AND-LND-ARCHITECTURE.md), `./lab.sh bolt 2` | `./lab.sh practice 12`, `./lab.sh polar` |
| [Drills and PR reviews](../BUILDING_BITCOIN_CORE_FROM_SOURCE.md) | [Book 2: Ch 1-5](./books/BOOK-2-CPP-AND-PYTHON-FOR-BITCOIN-CORE.md) | [journeys](../pr-reviews/merged-journeys/README.md) | `./lab.sh drill 1..8`, `./lab.sh journeys` |
