# 📚 Offline Bitcoin & Lightning Protocol Reference Library

All core Bitcoin and Lightning protocol specifications are stored locally on this laptop so you can study, build, and review PRs with **zero internet connection**:

| Resource | Local Path on This Laptop | Quick CLI Command |
| :--- | :--- | :--- |
| **Satoshi's Original Whitepaper (PDF)** | `/Users/mac/bitcoin-references/bitcoin.pdf` | `open /Users/mac/bitcoin-references/bitcoin.pdf` |
| **Satoshi's Whitepaper (Annotated w/ C++ Links)** | [`offline-library/SATOSHI_WHITEPAPER.md`](./SATOSHI_WHITEPAPER.md) | `cat offline-library/SATOSHI_WHITEPAPER.md` |
| **All 270+ Bitcoin Improvement Proposals (BIPs)** | `/Users/mac/bitcoin-references/bips/` | `./lab.sh bip 340` *(or any BIP number)* |
| **All Lightning Network Specifications (BOLTs)** | `/Users/mac/bitcoin-references/bolts/` | `./lab.sh bolt 3` *(or any BOLT number)* |
| **Bitcoin Core Full C++ Codebase & Git History** | `/Users/mac/bitcoin/` | `./lab.sh pr-list` & `./lab.sh pr-review <PR>` |

---

## Essential BIPs to Read Offline (`./lab.sh bip <num>`)

- **Keys & Wallets:** `BIP32` (HD Wallets), `BIP39` (Mnemonics), `BIP44`/`BIP84`/`BIP86` (Derivation Paths), `BIP380`–`BIP386` (Output Script Descriptors)
- **Timelocks & Mempool:** `BIP65` (`OP_CHECKLOCKTIMEVERIFY`), `BIP68` & `BIP112` (Relative Locktime & `OP_CHECKSEQUENCEVERIFY`), `BIP125` (Opt-in RBF), `BIP431` (TRUC `v3` Transactions)
- **SegWit & Taproot:** `BIP141` (SegWit Consensus), `BIP143` (SegWit Sighash), `BIP173` & `BIP350` (Bech32 / Bech32m), `BIP340` (Schnorr Signatures), `BIP341` (Taproot), `BIP342` (Tapscript)
- **Signing & P2P:** `BIP152` (Compact Block Relay), `BIP174` & `BIP370` (PSBT v0 / v2), `BIP324` (v2 Encrypted P2P Transport)

## Essential Lightning BOLTs to Read Offline (`./lab.sh bolt <num>`)

- **`BOLT 1` (`01-messaging.md`):** Base Protocol & Type-Length-Value (TLV) Framing
- **`BOLT 2` (`02-peer-protocol.md`):** Channel Establishment (`open_channel`, `accept_channel`), HTLC Forwarding (`update_add_htlc`, `update_fulfill_htlc`), and Closing
- **`BOLT 3` (`03-transactions.md`):** Bitcoin Transaction & Script Formats (Commitment Transactions, Revocation Keys, Offered/Received HTLC Scripts, Anchor Outputs)
- **`BOLT 4` (`04-onion-routing.md`):** Sphinx Onion Packet Construction & Encrypted Multi-Hop Routing
- **`BOLT 5` (`05-onchain.md`):** On-Chain Force-Close, Breach Remedy (Justice Transactions), and HTLC Timeout Handling
- **`BOLT 7` (`07-routing-gossip.md`):** P2P Channel & Node Announcement Gossip
- **`BOLT 11` (`11-payment-encoding.md`):** Bech32 Lightning Invoice Encoding (`lnbc...`, `lnbcrt...`)
